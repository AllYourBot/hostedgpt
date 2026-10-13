---
name: pr-review
description: Review the branch against project guidelines, fix what it finds, strip non-load-bearing comments, and keep .claude/rules fresh
argument-hint: optional focus area or specific concerns to scrutinize
allowed-tools: Read, Edit, Write, Glob, Grep, Agent, Bash(git *), Bash(gh *), Bash(bin/rubocop*), Bash(bin/rails test*), Bash(bin/blocks test*)
---

# /pr-review

Reviews the branch against project guidelines, fixes issues, and keeps `.claude/rules/` fresh.

## User context

User-provided context for this invocation: $ARGUMENTS

If non-empty, treat it as a lens across every step — e.g. "focus on the streaming changes" means weight Step 2's review and Step 5's rule-freshness pass toward that area. Don't skip steps because of it.

## Step 1: Set up the diff

1. `git branch --show-current`. If on `main`, check for uncommitted or staged changes. If there are changes, ask the user for a branch name, create it, and continue. If there are none, stop — nothing to review.
2. `git fetch upstream main`, then collect the diff: `git diff upstream/main...HEAD`, `git diff`, `git diff --cached`, plus untracked files from `git status --short`. Uncommitted work is in scope.

Diff against `upstream/main`, never the local `main` ref: local `main` lags as soon as someone merges, which silently pulls their shipped commits into your review. (`origin` is a personal fork; `upstream` is AllYourBot/hostedgpt.)

If the branch holds unrelated work (e.g. an earlier commit for a different change), say so and review only the work the user is asking about.

## Step 2: Review against the guidelines

1. Read `CLAUDE.md` and every `.claude/rules/*.md`. They are path-scoped, but read all of them for review so you can apply the right guidance to every changed file.
2. Review all changes against them. Also look for bugs, security issues (never log raw tokens; `encrypts` on credentials), dead code, and missing test coverage — including the CLAUDE.md conventions: provider behavior stays in the `AIBackend` layer, provider tests stub the client under `test/support/test_client/`, and streaming changes assert chunk order as well as final persistence.
3. Verify each finding against the full file before acting on it — a diff alone often suggests problems the surrounding code disproves.
4. Fix every real issue. New tests follow the rule for their file type: `unit_test.md` + `model_concern.md` for models and concerns, `controller_test.md` for controllers, `tests.md` everywhere.

For a large diff you may fan the analysis out to subagents via the Agent tool (e.g. one per area). If you do, they are ANALYSIS ONLY — tell them explicitly not to use Edit or Write and to return proposed replacement text with file:line. You apply every edit yourself.

## Step 3: Strip comments to load-bearing only

For every comment added on this branch, ask: **"If I delete this comment, would a future developer plausibly break something or waste meaningful time?"**

**Default action is REMOVE.** Keep a comment only when you can finish the sentence "Without this comment, a future dev would…" with a concrete failure — a hidden coupling, a workaround for a specific bug, a surprising invariant. Comments that restate the code, summarize the method, or record write-time thinking go.

## Step 4: Tighten consecutive one-line method definitions

Consecutive single-expression `def foo = expr` definitions in the same scope sit with **no blank lines between them**. Don't collapse a one-liner against a multi-line `def`, or across another statement (an `attr_*`, a constant, a comment).

## Step 5: Keep `.claude/rules/` fresh

- **ADD:** Did the review catch a mistake a competent person could make again? Did the diff hit a non-obvious gotcha or settle a decision where the obvious alternative fails? Document it in the most narrowly-scoped rule that covers those paths (or CLAUDE.md for architecture).
- **UPDATE:** Does a rule contradict what the code actually does? Figure out which side is wrong and fix it.
- **REMOVE:** References to files, helpers, or tools that no longer exist; guidance now redundant. When in doubt, delete.

Don't add descriptions of what code does, standard conventions, or "useful background" — the bar is *load-bearing*. Most PRs need 0–1 small rule edits.

## Step 6: Run the tests

Run `bin/rails test` and `bin/rubocop` (and `bin/blocks test` if `app/javascript/blocks/` changed). System tests run in CI on the PR. Fix failures before committing; report any you can't fix.

## Step 7: Commit

If Steps 2–5 changed anything, stage the files explicitly and commit with a message describing the review changes, separate from feature commits.

## Step 8: Link the PR

End with the PR URL (`gh pr view --json url -q .url`). If no PR exists yet, say so and suggest `/pr`.
