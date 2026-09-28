---
paths:
  - "db/migrate/**"
---

# Migrations

## A new column holding a secret or customer content needs `encrypts`

Decide this when you add the column, not later. It applies to credentials (API tokens, OAuth tokens — anything that authenticates) and to customer content the user typed or we recorded about them. `APIService#token` and the `Credential` subclasses are the existing examples.

The fork: if any code looks the column up by value — including a uniqueness validation or a unique index — it must be `deterministic: true`; otherwise plain `encrypts`. A column that *already holds rows* also needs a one-off backfill; a brand-new one has nothing to backfill.

## `schema.rb` captures your whole local DB, not just this branch's migrations

`bin/rails db:migrate` dumps `schema.rb` from the *current state of your dev DB*. Migrate on branch A, switch to branch B, migrate again, and A's tables/columns are still applied — so they get dumped into `schema.rb` on B even though their migration files don't exist there. The result is a `schema.rb` that diverges from `db/migrate` and breaks fresh setup (`db:prepare` loads `schema.rb`), with no failing test to catch it. After any migrate, check `git diff db/schema.rb`: every added table/column/index must trace to a migration on THIS branch. If a stray one appears, strip it from the dump, or rebase onto the branch where it legitimately landed.

## Prefer a migration-local model in a data backfill

A backfill that calls `Conversation.find_each` runs against a *historical* schema with today's model class — which breaks the moment that model is renamed, deleted, or starts asserting columns it did not have back then. So for any row iteration or `create!`/`update!`, define a minimal model inside the migration instead:

```ruby
class BackfillSomething < ActiveRecord::Migration[8.1]
  class Conversation < ActiveRecord::Base
    self.table_name = "conversations"
  end
end
```

**A migration-local model reads an `encrypts` column as raw ciphertext**, because the declaration is what installs the attribute type and the local class doesn't carry it. Nothing raises — the backfill just decides against every row: a regex over the value matches the `{"p":…` envelope instead of the text. So redeclare the columns you read on the local model (`encrypts :token`), then seed the shapes you expect to match and to miss, `db:rollback STEP=1`, `db:migrate`, and check what actually got written.

## Rework an in-PR migration in place, don't stack a new one

If you need to revise a migration you created earlier in THIS PR, don't add a second migration just because the first one has already run locally. Roll it back, edit it, and re-run:

```bash
bin/rails db:rollback STEP=1   # or more if you need to undo several
# edit the existing migration file
bin/rails db:migrate
```

Exception: if the migration is already merged to `main`, you can't safely rewrite it — add a new migration instead.

## Drop a column in two deploys

During a deploy the old code keeps serving requests until the new release takes over, and the old code's full-column INSERTs fail against a column that is already gone. So dropping a column live code still touches takes two PRs: the first ships `self.ignored_columns` plus the code removal, the second ships the `remove_column` migration once the first is deployed.
