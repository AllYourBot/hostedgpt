---
name: pr-review
description: Review code against guidelines, verify Claude CLI and framework-config assumptions, update rules and user stories
argument-hint: optional focus area or specific concerns to scrutinize
allowed-tools: Read, Edit, Write, Glob, Grep, Agent, Bash(git *), Bash(gh *), Bash(bin/rubocop*), Bash(bin/prettier*), Bash(uv run ruff*), Bash(xcrun swift-format*), Bash(bin/rails test*), Bash(bin/rails runner*), Bash(bundle exec ruby*), Bash(bundle show*), Bash(.claude/hooks/scan-transaction-locks.rb*), Bash(ruby .claude/hooks/scan-transaction-locks*), WebFetch, WebSearch
---

# /pr-review

Reviews code against project guidelines, verifies external assumptions, fixes issues, and updates documentation.

## User context

User-provided context for this invocation: $ARGUMENTS

If non-empty, treat it as a lens across every step — e.g. "focus on the auth changes" means weight Step 1's guideline review and Step 6's rule-freshness pass toward that area. Don't skip steps because of it; layer the user's emphasis on top of the normal flow.

## Execution plan: run the analysis in parallel

The steps below are numbered so nothing gets skipped, but most of the analysis is independent of the rest — do NOT execute them one at a time. Orchestrate them in phases:

**Phase A — setup (serial, you).** Do items 1 and 2 of Step 1 yourself: branch check, changed-file list, full diff. Concatenate `git diff upstream/main...HEAD`, `git diff`, and `git diff --cached` into one temp file — uncommitted and staged work is in scope, and a committed-only file would hide it from every subagent. Pass that path plus the union changed-file list to each agent.

Diff against `upstream/main`, not `main`, and `git fetch upstream main` first. The local `main` branch ref goes stale the moment a teammate merges: `/pr` rebases onto `upstream/main` without moving local `main`, so `git diff main...HEAD` silently widens the review to include every commit merged since you last touched `main`. That is not a cosmetic problem — you will review already-shipped code as if it were new, and Steps 6, 7, and 8 will propose rules, stories, and assistant migrations for someone else's work.

**Phase B — fan out (parallel subagents).** Launch general-purpose subagents via the Agent tool, ALL in a single message so they run concurrently. Each agent is analysis-only: it returns findings and concrete proposed edits, and must NOT modify any file — you are the only writer, so parallel agents can't clobber each other. Give each agent: the diff temp-file path, the changed-file list, the user-context lens, and the full text of the step it's executing (paste it into the prompt — the agent can't see this skill).

The pasted step text will contain imperatives to fix, edit, and apply — Step 1 item 5 says "Fix every issue you find," Steps 2c and 3c say "apply fixes," Steps 6 and 7 are edit steps by construction. A general-purpose subagent has Edit and Write and will follow the pasted instruction over your wrapper sentence, so override it explicitly at the top AND bottom of every prompt: *"ANALYSIS ONLY. Wherever the pasted step says fix/apply/add/update, instead return the exact proposed replacement text with file:line. Do not use Edit, Write, or NotebookEdit, and do not run any command that mutates the working tree."*

The agents:

1. **Guideline review** — items 3 through 5 of Step 1 as analysis: read all `.claude/rules/*.md`, review the diff for rule violations, bugs, security issues, dead code, missing test coverage. Returns each issue with file:line and a proposed fix.
2. **Lock trace** — the transaction/`with_lock` trace below, including running `.claude/hooks/scan-transaction-locks.rb`.
3. **Disk-growth trace** — the unbounded on-disk accumulation trace below. This agent must never propose a bound; an unbounded write comes back marked BLOCKING. That finding stops the flow — raise it with the user and wait for their answer before Phase D. Do not pick a retention default yourself and do not commit around it.
4. **Agent-facing prose sweep** — the "loop" ambiguity / audience-mismatch check below.
5. **Claude CLI assumptions** — Step 2 in full (its skip condition applies — don't launch the agent if the diff doesn't touch the CLI surface). Its WebFetch/WebSearch round-trips are usually the slowest part of the review, so it sets the floor on how long Phase B takes — list it first in the launch message.
6. **Framework-config round-trips** — Step 3 in full (skip condition applies). Its `bin/rails runner` and `bundle exec ruby -e "require 'kamal'…"` round-trips are read-only.
7. **Comment + one-liner audit** — Steps 4 and 5 as analysis: return the exact list of comments to delete (with the "Without this comment…" defense for any keeper) and the blank-line groups to collapse.
8. **Rules freshness** — Step 6 as analysis: return concrete ADD/UPDATE/REMOVE proposals with draft text.
9. **USER_STORIES delta** — Step 7 as analysis: return proposed story adds/updates, or "no change needed".
10. **Chief of Staff ↔ Executive Assistant mirror check** — the mirror trace below. Launch it whenever the changed-file list touches either assistant (`rails/app/models/chief_of_staff*`, `rails/app/models/executive_assistant*`, `rails/app/models/concerns/agent/**`, `rails/sandbox/AGENT.md`, `rails/sandbox/SUBAGENT.md`, `ConversationJob`/`AgentJob`, `Conversation::Compactable`/`Loop::Briefing`). Skip it only when none of those changed.

**Phase C — apply (serial, you).** Read every agent's findings, exercise your own judgment (agents propose; you decide), and apply all edits yourself: code fixes, comment strips, one-liner collapses, rules edits, USER_STORIES edits. Anything an agent marked "flag to the user" goes into your final reply — never silently accepted.

Two gaps are yours to close because no Phase B agent could have seen them. Agent 8 ran blind to every other agent's findings, but Step 6a's most productive question is "did the review catch a mistake the author made?" — so re-run 6a yourself against the collected findings. And agents 7 and 9 audited the diff as it stood *before* your fixes, which routinely add comments and methods — so re-run Steps 4 and 5 over your own added lines.

Agents given only a diff will also flag problems that the full file disproves. Verify a finding against the file before acting on it, and expect to reject some.

**Phase D — long-running suite (backgrounded).** The keyless test run temporarily deletes `config/master.key`, so nothing else that boots Rails may run during its window — not another test run. Start it after Phase C's fixes are applied and let it finish before Phase E. Run it as a background Bash, but launch it while you're still at the keyboard: its `cp … && trap … && rm -f …` prefix is a compound command, and `allowed-tools` grants are matched per subcommand — none of `cp`, `trap`, or `rm` are granted, so expect a separate permission prompt for each. While it runs, do Step 8's migration judgment and draft the commit. Collect and act on the result before committing.

**Phase E — finish (serial).** Step 9 commit, Step 10 PR link. `bin/ci` is NOT run here — it is reserved for `/pr-merge` (too slow to run on every review pass), and `bin/stories` is a manual audit no skill runs.

## Step 1: Review code against guidelines

1. Check the current branch: `git branch --show-current`. If on `main`, check for uncommitted or staged changes. If there are changes, ask the user for a branch name, create it, and continue. If there are no changes, stop — nothing to review.
2. Get the diff: `git fetch upstream main` first, then `git diff upstream/main...HEAD --name-only` for changed files and `git diff upstream/main...HEAD` for the full diff. Also check for uncommitted changes with `git diff --name-only` and `git diff --cached --name-only`. Never diff against the local `main` ref — it lags behind `upstream/main` as soon as a teammate merges, which silently pulls their shipped commits into your review.
3. Read every rule file in `.claude/rules/*.md`. These are path-scoped, but for review purposes read all of them so you can apply the right guidance to every changed file.
4. Review all changes against every rule. Also look for bugs, security issues, dead code, and missing test coverage.
5. Fix every issue you find. When writing new tests, follow the test rule that matches the file type:
   - ActiveRecord model classes (inherit from `ApplicationRecord`) → `unit_test.md` and `model_concern.md`
   - Plain Ruby objects (any class that does NOT inherit from `ApplicationRecord` — regardless of location: `lib/`, `app/models/`, `app/services/`, concerns, value objects) → `poro_test.md`
   - Controllers → `controller_test.md`
   - Jobs → `job_test.md`
   - `sandbox/cli/*` scripts → `cli_test.md`

## Step 2: Strip comments to load-bearing only

Comments often accumulate while a feature is in flux — useful at write-time to anchor reasoning, redundant once the code stabilizes. **Audit time is when they get trimmed.**

For every comment added on this branch (including comment-only doc lines above methods, classes, constants), apply this test — not the looser CLAUDE.md framing:

**"If I delete this comment, would a future developer plausibly break something or waste meaningful time?"**

This is stricter than "does this explain WHY." A comment can be technically WHY-shaped and still redundant if the method/variable name already conveys it, the code structure makes the intent obvious, or the WHY is just notes-to-self that don't load-bear for a fresh reader.

**Default action is REMOVE.** Keep only when you can articulate a concrete failure mode the comment prevents. Examples that clear the bar:
- "Without this comment, a future dev might trim CONSTANT_X to 5s and break the chain — the ≥13s constraint comes from another file."
- "Without this comment, a future dev would think `ensure` already handles cleanup and remove the explicit call."
- "Without this comment, the cross-file relationship between A and B isn't visible from grepping either site."

Do NOT keep comments that just describe what the code does, summarize the method, or capture write-time thinking ("this provides useful context", "explains the design rationale"). If you find yourself rationalizing in those terms, remove the comment. The bar is *load-bearing*, not *useful*.

After this pass, the only comments remaining should be ones you can defend with a concrete sentence starting with "Without this comment, a future dev would…".

## Step 3: Tighten consecutive one-line method definitions

When the diff contains multiple one-line method definitions (`def foo = expr`) in a row inside the same scope, they should sit one right after another with **no blank lines between them**. The blank lines that auto-format between full-body `def`s are noise when the bodies fit on one line — the methods read as a small group of related accessors / predicates / delegates and that visual grouping is what you want.

Sweep the diff for groups of two or more consecutive single-expression `def foo = ...` defs separated by blank lines and collapse the blank lines. Do not collapse:
- A one-liner next to a multi-line `def` — the blank line between them is correct.
- A one-liner separated from another by a different statement (an `attr_*`, a constant, a comment).

Example — before:
```ruby
def user? = role == "user"

def assistant? = role == "assistant"

def to_s = text
```

After:
```ruby
def user? = role == "user"
def assistant? = role == "assistant"
def to_s = text
```

## Step 4: Keep `.claude/rules/` fresh

The rules in `.claude/rules/` keep future developers and Claude aligned. Every PR is a chance for them to drift — new patterns get added that aren't documented, conventions get sharpened, old guidance becomes stale, or this very review process catches mistakes that should now be prevented. **Treat keeping the rules fresh as a deliberate step, not an afterthought.**

Do three passes:

### 4a. Capture new load-bearing knowledge (ADD)

Ask: what did THIS PR teach? Specifically:

- Did the review catch a mistake the author made? If a competent person could plausibly make the same mistake again, document it so the next person doesn't repeat it.
- Did the diff introduce a non-obvious gotcha (platform quirk, ordering constraint, hidden coupling) that took real effort to get right?
- Did the diff settle an architectural decision where the obvious alternative was tried and failed? Capture the choice and why the alternative didn't work.
- Is there external knowledge (CLI behavior, OS quirk, library API) the diff depends on that isn't visible from the code alone?

Add to the most narrowly-scoped existing rule that covers the relevant paths. Only create a new rule when no existing one fits.

### 4b. Sharpen or correct existing rules (UPDATE)

Read the rules that match the changed paths. For each:

- Does it contradict what the PR actually does? Either the rule is stale or the PR is wrong — figure out which and fix it.
- Is its phrasing vague where this PR's example could make it concrete? Tighten with a specific example.
- Does it miss a case this PR encountered? Add the case.

### 4c. Remove stale content (REMOVE)

Rules rot. Sweep for:

- References to deleted files, removed features, or deprecated patterns.
- Workarounds for bugs that have since been fixed (check git log / commits).
- Guidance now redundant — covered by a better-scoped rule, or now obvious from code conventions.
- Long lists where most items no longer add value — trim, don't preserve.

When in doubt, delete. A short sharp rule beats a long half-stale one.

### What NOT to add

- Descriptions of what code does (Claude can read the code)
- Standard patterns or conventions (Claude can infer these)
- User-facing behavior (that belongs in USER_STORIES.md)
- "Useful background" or "interesting context" — the bar is *load-bearing*, not *useful*

If after all three passes nothing meets the bar, move on. Most PRs need 0-1 small rule edits; occasional PRs need a new rule or a larger rewrite. A PR that touches no rules is fine — a PR that touches rules every time is a smell (the rules are bloating).


## Step 5: Commit

If any changes were made in Steps 1–4:
1. Stage all changes.
2. Commit with a clear message describing the review changes (separate from feature commits).

`bin/ci` is NOT run here — it's reserved for `/pr-merge`.

## Step 6: Link the PR

Always end by giving the user the PR URL (`gh pr view --json url -q .url`) so they can jump straight to it — the last line of your reply is the link.
