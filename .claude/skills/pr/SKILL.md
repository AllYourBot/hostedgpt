---
name: pr
description: Create or update a pull request
argument-hint: optional context for the PR (focus area, scope notes, anything to highlight)
allowed-tools: Read, Glob, Grep, Bash(git *), Bash(gh *)
---

# /pr

Creates a new pull request or updates an existing one to reflect the current state of the code.

## User context

User-provided context for this invocation: $ARGUMENTS

If non-empty, treat it as guidance that shapes decisions in the steps below — e.g. branch-name flavor, what to emphasize in the PR title/summary, what scope clarifications to surface in the test plan. Don't override the explicit rules of the steps with it; layer it on top.

## Step 1: Land the work on a feature branch

Run `git branch --show-current` and `git status --porcelain` and `git log main..HEAD --oneline` (commits on the current branch beyond `main`) to figure out the state, then pick exactly one of the cases below. **Do not ask the user any questions except in the one explicit case noted.** In particular, never ask the user to confirm a branch name — pick one.

### Picking a branch name (when needed)

When a new branch is required, generate the name yourself from the work in progress (uncommitted diff + any commits already made on the current branch). Use lowercase kebab-case, 2–5 words, describing the change. Keep under 60 chars. Examples: `dedupe-task-queue`, `fix-oauth-callback`, `add-myroku-deploy-flag`. Do not present the name for approval — just create the branch.

### Case A — on `main` with uncommitted changes

Obvious: this work needs a feature branch. Do all of this without asking:
1. Generate a branch name from the pending work.
2. `git checkout -b <name>`.
3. Stage the changed files explicitly (do not use `git add -A` or `git add .`).
4. Commit with a sensible message derived from the diff. Match the style of recent `git log --oneline -5`.
5. Continue to "Rebase and push" below.

### Case B — on `main` with a clean working tree

Nothing to PR. Stop and tell the user.

### Case C — on a feature branch and this conversation has clearly been working on it

If the conversation history shows you've been committing to this branch for the current PR scope (e.g., you created the branch earlier this session, or you've already made commits here for the work the user is now PR-ing), just proceed:
1. If there are uncommitted changes, stage the changed files explicitly and commit with a sensible message.
2. Continue to "Rebase and push" below.

### Case D — on a feature branch with no commits beyond `main`

`git log main..HEAD --oneline` is empty. This branch was created for some work but nothing has been committed yet — safe to treat as the destination for the current changes:
1. If there are uncommitted changes, stage the changed files explicitly and commit with a sensible message.
2. Continue to "Rebase and push" below.

### Case E — on a feature branch with existing commits, uncommitted changes, AND no clear signal this branch is for the current work

This is the only ambiguous case. Stop and ask the user exactly one question:

> We're on `<branch>` which already has `<N>` commit(s) beyond `main`, and there are uncommitted changes here too. Commit them to this branch, or create a new feature branch?

Then act on the answer:
- "this branch" → stage the changed files explicitly, commit, continue to "Rebase and push".
- "new branch" → generate a name, `git checkout -b <name>` *from* `main` (not from the current branch — `git checkout main && git checkout -b <name>`), stage, commit, continue.

### Case F — on a feature branch with existing commits and a clean working tree

Nothing to commit. The PR (new or existing) should reflect what's already on this branch. Continue to "Rebase and push" below.

### Rebase and push

After whichever case above applied:
1. Rebase onto main: `git fetch upstream main && git rebase /main`. Resolve any conflicts.
2. Push the branch: `git push -u origin HEAD`. If the rebase rewrote history (or this is a force-push scenario from a previous push), use `git push --force-with-lease`.

## Step 2: Create or update the PR

**Never put an issue or PR number in the PR title.** GitHub already appends the PR's own number (`#474`) and auto-links any `#123` you write, so a title like `Fix the thing (#407)` renders as the confusing `Fix the thing (#407) #474` across GitHub's UI. Keep the title plain prose. Reference the issue in the PR *body* instead (e.g. `Fixes #407`), where it links cleanly. This applies to both creating a title and rewriting an existing one.

1. Check if a PR already exists: `gh pr view --json number,url,title,body`.
2. Run `git log main...HEAD --oneline` to see all commits on this branch.
3. Run `git diff main...HEAD` to see the full diff.

**If no PR exists**, create one:

```bash
gh pr create --title "<short title>" --body "$(cat <<'PREOF'
## Summary
<bullet points describing the changes — as many as needed, as few as possible>

## Verify in dev
<checklist of items that can be verified locally before merge>

## Verify in production
<checklist of items that can only be verified after deploy>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
PREOF
)"
```

**If a PR already exists**, rewrite the description to reflect the current state of the code:
- Update the summary so it reads as though the PR were just created.
- Update both checklists. Uncheck all items. For any item that existed before, is unchanged, and was checked, append "🔄" to indicate it needs re-verification. Remove items that are no longer relevant and add new ones if needed.

### Checklist authoring rules

**Do NOT add items that `bin/ci` already covers.** `bin/ci` runs the full test suite (the LiveKit tests whenever `livekit-menubar/` changed on the branch), rubocop, prettier, ruff, swift-format, and security checks, and the merge gate blocks any PR without a green `bin/ci` signoff. Items like "tests pass", "no lint errors", "CI is green", or "the new test in `foo_test.rb` passes" are guaranteed by the merge process — they are noise on the checklist and train you to check boxes for free. If the only verification you can think of is "tests pass", leave the dev section empty.

**Split items by where they can actually be verified:**

- **`## Verify in dev`** — things you can do locally on this branch before merging. Examples: walk through a UI flow in the browser, exercise an edge case the tests don't cover, hit a dev OAuth flow, confirm a migration's data shape on the dev database.
- **`## Verify in production`** — things that *only* work against the real production environment, real prod data, or real hardware. Examples: a real iMessage delivery via LoopMessage, a real Gmail push notification, behavior that depends on prod-only data volume, a deployed scheduled job firing on its real cron.

If something can be verified in dev, it goes in `## Verify in dev`. The production section is reserved for things genuinely impossible to confirm before deploy. If nothing fits production verification, leave the section empty (do not pad it).

The two checklists serve different consumers: `/pr-merge` blocks on unchecked items in `## Verify in dev`, and after a successful deploy it will work the `## Verify in production` items itself (with your confirmation up front).

```bash
gh pr edit {number} --body "<rewritten body>"
```

3. Return the PR URL.

## Step 3: Drive the "Verify in dev" checklist

**You own every item on this checklist.** Even the items the user has to physically perform are still yours — you're not delegating, you're asking for the smallest possible piece of help so that *you* can finish the verification. Stay involved until every box is checked or an issue has been surfaced and fixed. Be a little pushy; hold their hand.

**Language matters.** Never frame an item as "you handle #3" or "you do X" — that hands ownership away. Always frame it as "I need your help to <minimal thing>, then let me know and I'll <do the rest / confirm / check it off>." The user's role is to unblock you on the one piece they uniquely can do; yours is everything else, including the final verification and the box-check.

1. Re-read the `## Verify in dev` items from the PR body you just wrote.
2. For each item, decide what *you* will do and, if anything, what minimal piece you need the user's help with (because it requires their device, their eyes, their account, a UI flow you can't drive, etc.). Default to doing as much as possible yourself — set up state, prepare the scenario, read logs after — and ask the user only for the irreducible human part.
3. Tell the user, in one message, exactly what you're about to do and what (if anything) you need from them. Examples of the right shape:

   > While creating this PR, I identified 4 things to verify in dev:
   > 1. <item>
   > 2. <item>
   > 3. <item>
   > 4. <item>
   >
   > I can do all of these for you — may I proceed?

   or, when part of an item needs the user:

   > I can do 1, 2, and 4 on my own. For #3 I need your help to <minimal specific action — e.g. "click the new button in the menubar once the app reloads">. Once you've done that, let me know and I'll <verify the result in the logs / confirm the record landed in the db / check it off>. Want me to start on 1, 2, and 4 now?

   If there are zero items in `## Verify in dev`, skip this step entirely.

4. Once they say go, verify the items end-to-end. After each one is confirmed working, check the box in the PR body:

   ```bash
   gh pr view --json body -q .body > /tmp/pr_body.md
   # edit /tmp/pr_body.md to flip "- [ ]" to "- [x]" on the verified line
   gh pr edit {number} --body-file /tmp/pr_body.md
   ```

   Update the PR after each item rather than batching — the checklist should reflect reality as you go.

5. For items where you needed the user's help: as soon as they report they've done their part, *you* do the actual verification (read the log, query the db, hit the endpoint, whatever closes the loop) and *you* check the box. Don't ask the user "did it work?" — find out yourself when possible, and only ask them to confirm a visual/subjective result when there's literally no other way.

6. If a verification surfaces a problem, that becomes the new top priority: investigate, propose a fix, push a commit, then resume the checklist.

7. Don't declare the PR ready until every `## Verify in dev` box is checked or has been explicitly skipped by the user with a reason.

8. When the checklist is fully worked, remind the user to run `/pr-feedback` once reviewers have had a chance to comment.
