---
paths:
  - "db/migrate/**"
---

# Migrations

## A new column holding a secret or customer content needs `encrypts`

Decide this when you add the column, not later — the DB is replicated offsite, so anything readable here leaves the box readable. It applies to credentials (tokens, keys, nonces — anything that authenticates) and to customer content (message text, agent instructions, names, anything the user typed or we recorded about them).

The fork: if any code looks the column up by value — including a uniqueness validation or a unique index — it must be `deterministic: true` (`Credential#oauth_email`); otherwise plain `encrypts`. Add it to `EXPECTED_ENCRYPTED_COLUMNS` in `test/lib/encryption_at_rest_test.rb`, the only thing that fails when a declaration goes missing. A column that *already holds rows* also needs a one-off backfill task run once per instance (there is no standing one — `encryption:backfill_existing` was deleted once the fleet had run it; recover it from git history as the template); a brand-new one has nothing to backfill. The full pattern — the `json`-column trap, and why deterministic columns depend on `extend_queries` — is in [[rails]] under "Encrypting a column at rest".

## `schema.rb` captures your whole local DB, not just this branch's migrations

`bin/rails db:migrate` dumps `schema.rb` from the *current state of your dev DB*. Migrate on branch A, switch to branch B, migrate again, and A's tables/columns are still applied — so they get dumped into `schema.rb` on B even though their migration files don't exist there. That's how `dedicated-browser-tab-per-loop` once shipped a `gmail_inbound_messages` table for a model that didn't exist anywhere in the repo. The result is a `schema.rb` that diverges from `db/migrate` and breaks fresh setup (`db:schema:load` is how a new production instance is provisioned), with no failing test to catch it. After any migrate, check `git diff db/schema.rb`: every added table/column/index must trace to a migration on THIS branch. If a stray one appears, it leaked from another branch — rebase onto the branch where it legitimately landed (if it's merged), or strip it from the dump. If a stray dump reaches the test DB first, the symptom points elsewhere: every test errors with `Could not find table '<some other table>'` naming a table that is not one of the leaked ones. Restore `db/schema.rb` from git, hand-add only this branch's changes, then `RAILS_ENV=test bin/rails db:schema:load`.

`bin/ci` enforces this with `bin/rails db:schema:drift`, which migrates a scratch database from zero using only `db/migrate` and diffs the dump against the committed `db/schema.rb`. Run it directly to check your work; `bin/rails db:schema:rebuild` overwrites `db/schema.rb` with that from-zero dump when the migrations are the side that's right.

### An `enum` on a new column breaks the from-zero replay unless its type is declared

The drift check replays every migration from zero with TODAY's models loaded, so a
migration older than the column loads a model that now declares `enum :thing` against
a column that does not exist yet, and Rails raises `Undeclared attribute type for
enum`. Declaring the type explicitly decouples the enum from the column:

```ruby
attribute :provider, :string, default: "loopmessage"
enum :provider, %w[loopmessage photon].index_by(&:to_sym)
```

`Message::IMessage#provider` is the worked case. Do not "tidy" the `attribute` line
away: the whole suite stays green without it and only `db:schema:drift` fails, which
reads as a schema problem rather than a model one.

### A drifted dev DB cannot be repaired by `db:migrate`

If your dev DB was ever created by loading a `schema.rb` dump (`db:schema:load`, `db:prepare` on an empty file, or a copy of a DB that was), every migration version is stamped into `schema_migrations` as applied without any of them having run. So a table or column the dump carried but no migration creates — and, symmetrically, a `remove_column` that the dump predates — is now permanently baked in: `db:migrate` sees the version checked off and skips it forever. The give-away is a column that still exists alongside a recorded migration that drops it.

This matters at review time because the drift only surfaces when something re-dumps `schema.rb` from that DB mid-`bin/ci` (any `db:migrate` in development does), dirtying the working tree and failing `db:schema:drift` with a diff that looks like the *committed* schema is wrong when it isn't. Confirm which side is bad by dumping the DB's own schema and diffing it against the committed file before changing anything. The fix is to repair the database — drop the stray tables/columns, or rebuild it — never to `db:schema:rebuild` over a correct dump.

## Prefer a migration-local model in a data backfill

Because the drift check replays every migration from zero, a backfill that calls `Conversation.find_each` runs against a *historical* schema with today's model class — which breaks the moment that model is renamed, deleted, or starts asserting columns it did not have back then. So for any row iteration or `create!`/`update!`, define a minimal model inside the migration instead:

```ruby
class BackfillSomething < ActiveRecord::Migration[8.1]
  class Conversation < ActiveRecord::Base
    self.table_name = "conversations"
  end
end
```

**A migration-local model reads an `encrypts` column as raw ciphertext**, because the declaration is what installs the attribute type and the local class doesn't carry it. Nothing raises — the backfill just decides against every row: a regex over the value matches the `{"p":…` envelope instead of the text, and two rows holding identical plaintext never look identical because non-deterministic encryption gives them different payloads. `BackfillReminderTriggeredLoops` flagged **0 of 4** seeded loops that way, and the fixed version flagged exactly the right 3 — with nothing in between to notice, since the from-zero drift replay runs every backfill against an empty table.

So redeclare the columns you read on the local model (`encrypts :instructions`). `test/lib/backfill_encryption_test.rb` is what fails when you forget: it parses every `db/migrate/*.rb` and `lib/tasks/*.rake`, finds each local `< ActiveRecord::Base` with a `self.table_name`, and names the exact declaration missing for any encrypted column of that table the file mentions. It covers the rake-task path too, because "move the backfill to a post-deploy task" (below) carries the identical footgun. It cannot prove the backfill's *logic*, though — for that, seed the shapes you expect to match and to miss, then `db:rollback:primary STEP=1`, `db:migrate`, and check what actually got written.

Referencing an application model is fine when the reference can't actually execute against a mismatched historical schema during the replay — a pure class method that touches no schema-dependent column, or a backfill whose body is guaranteed to no-op on the empty replay DB (nothing to iterate). The rule is about what *runs* under the from-zero replay, not the mere mention of a constant.

## Rework an in-PR migration in place, don't stack a new one

If you need to revise a migration you created earlier in THIS PR, don't add a second migration just because the first one has already run locally. Roll it back, edit it, and re-run:

```bash
bin/rails db:rollback STEP=1   # or more if you need to undo several
# edit the existing migration file
bin/rails db:migrate
```

This keeps the migration count per PR to a minimum and keeps the schema history clean.

Exception: if the migration is already merged to `main`, or has run against any shared/production database, you can't safely rewrite it — add a new migration instead.

## SQLite gotcha: table recreation nukes FK cascades

SQLite doesn't support many `ALTER TABLE` operations natively. When Rails hits one, it **recreates the table** behind the scenes:

1. Create a new temp table with the modified schema
2. Copy data from the original
3. **Delete all rows from the original** ← the killer
4. Drop the original
5. Rename the temp table

Step 3 triggers any `ON DELETE` foreign key actions on other tables pointing at this one. If another table has `on_delete: :nullify` or `on_delete: :cascade` pointing here, those fire and silently wipe data.

## Operations that trigger table recreation

- `change_column` (type, default, null constraint)
- `change_column_default`
- `change_column_null`
- `add_foreign_key` (including via `add_reference ... foreign_key: true`)
- `remove_foreign_key`
- `remove_column` — **always**, not "sometimes": Rails' SQLite adapter routes it through `alter_table` regardless of SQLite version, and that is `disable_referential_integrity { transaction { copy_table; drop_table } }` — a full `INSERT … SELECT` of every row inside one transaction, plus an index rebuild. Verified against the 8.1.3 adapter source and timed on the production host against a backup of the biggest table in the DB (`assistant_events`, 362k rows / 2.1GB): **~40s with the writer lock held throughout**. Budget against `deploy_timeout` (300s) before putting one in a deploy migration.
- `rename_column` — despite SQLite supporting native `ALTER TABLE … RENAME COLUMN` (schema-only, O(1)) since 3.25, Rails' SQLite adapter still goes through `alter_table` and copies every row. Verified against the 8.1.3 adapter source, and it's what locked a1's writers for over a minute mid-deploy when `assistant_events` (the biggest table in the DB) was renamed-and-rewritten. Rename a column with raw DDL instead, in a `reversible` block: `execute("ALTER TABLE t RENAME COLUMN a TO b")` (see `db/migrate/20260729000001_prepare_assistant_events_for_encryption.rb`).

Safe (no recreation): `add_column`, `add_index`, `remove_index`, `rename_table` (native `RENAME TO`).

## A deploy migration that holds the writer lock longer than ~5s bruises the live app

Migrations run in the new container while the old-image containers still serve traffic (same overlap as the never-enqueue-jobs rule above), and every writer in the old app gives up after the 5s `busy_timeout` with `SQLite3::BusyException: database is locked`. So any migration that rewrites a big table — table recreation from the list above, or an in-migration backfill over a large table — produces a burst of user-facing failures and bracket reports for its whole duration, even though the migration itself succeeds. Keep deploy migrations to O(1) schema changes on big tables; anything that rewrites rows goes in a post-deploy per-instance task (same pattern as the job-enqueue rule), iterating in batches that commit once per batch — never once per row — so the writer lock is held one bounded batch at a time. `EncryptionBackfill.in_throttled_batches` was the reference implementation before it was deleted; recover it from git history.

## Phase 2 of a two-phase column drop must check `stable` first

Dropping a column or table that live code still **touches — reads as much as writes** takes two deploys, and **an empty table is not a safe drop**: the hazard is the old image's query, not the rows. `db:prepare` runs in the NEW container while the OLD image still serves every request until the proxy cuts over, so a table the old `plan_blocked?` reads on every inbound message takes down every message in that window whether it holds a million rows or none. The split is skippable only when every affected caller is a retrying job — a judgement to make out loud, not by default. Otherwise: phase 1 ships `self.ignored_columns` (+ the code removal), phase 2 ships the `remove_column` migration one deploy later — otherwise the old image's full-column INSERTs 500 during the container overlap. But "one deploy later" must hold on EVERY deploy track, and there are two: merging to `main` deploys only a1/a7, while all other instances deploy when `main` is merged into `stable`. If `stable` hasn't shipped phase 1 by the time phase 2 merges to `main`, the eventual stable push batches both phases into ONE deploy and recreates the exact hazard the split exists to avoid — on every stable-track instance at once. Before merging a phase-2 drop, run `git merge-base --is-ancestor <phase-1-merge-sha> upstream/stable`; if it isn't an ancestor, deploy stable through phase 1 first (the deploy-all skill), then merge phase 2.

**Phase 2 should count and refuse, not trust the checklist.** Dropping the column deletes whatever it still holds, and those rows read back as nil forever — measured, not theorised: the unguarded drop against a database that had never been drained took every row's payload to nil, while a drained one lost nothing. So the migration's first statement is a `SELECT COUNT(*) … WHERE <column> IS NOT NULL` that raises `ActiveRecord::MigrationError` when it finds anything (**not** `IrreversibleMigration` — the migration is reversible; the precondition merely failed). The cost of being wrong is asymmetric: a raise fails the deploy and Kamal keeps the old container serving, which is recoverable, while a silent drop is not. Verify it fires by seeding one row before trusting it.

## Don't cross-DB JOIN in a backfill

This app has a primary DB (`production.sqlite3`) and a queue DB (`production_queue.sqlite3`) — see `config/database.yml`. Tables in different DBs cannot be joined at the SQL layer; SQLite raises `no such column` mid-query if you try.

If a migration backfill needs data that spans both DBs (e.g. reading `solid_queue_jobs` to backfill a column on `reminders`), collect candidate keys in Ruby from one DB, then query the other:

```ruby
job_ids = ReminderJob.where(...).pluck(:solidqueue_job_id)        # primary
unfinished = SolidQueue::Job.where(id: job_ids, finished_at: nil) # queue
```

Same applies anywhere `joins`, eager-loading, or a `where` subquery would cross the boundary — model methods, scopes, and ad-hoc queries in `bin/rails runner` all fail the same way.

## What to do

If your migration modifies an existing table, grep `db/schema.rb` for `add_foreign_key` lines targeting it. Any inbound FK with `on_delete: :nullify` or `:cascade` means you must save and restore the affected data within the migration:

```ruby
class ExampleMigration < ActiveRecord::Migration[8.1]
  def up
    considering = execute(
      "SELECT id, considering_project_id FROM agents WHERE considering_project_id IS NOT NULL"
    ).to_a

    change_column :projects, :some_column, :new_type

    considering.each do |row|
      execute "UPDATE agents SET considering_project_id = #{row["considering_project_id"]} WHERE id = #{row["id"]}"
    end
  end
end
```
