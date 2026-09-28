---
name: pr-feedback
description: Address unresolved PR review comments from Copilot and teammates
argument-hint: optional filter or guidance (e.g. "ignore Copilot, focus on @teammate", "skip nits")
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(git *), Bash(gh *), Bash(bin/rubocop*), Bash(bin/prettier*), Bash(uv run ruff*), Bash(xcrun swift-format*), Bash(bin/rails test*)
---

# /pr-feedback

Reads all unresolved PR review comments, triages them, and resolves each thread with reasoning.

## User context

User-provided context for this invocation: $ARGUMENTS

If non-empty, treat it as triage guidance — e.g. it may tell you which reviewers to prioritize, which categories of comment to skip, or specific threads to focus on. Apply it during Step 3 (triage) when forming your recommendations.

## Step 1: Find the PR

1. Get the current branch: `git branch --show-current`.
2. Find the open PR for this branch: `gh pr view --json number,url,title`.
3. If no PR exists, stop — nothing to address.

## Step 2: Fetch unresolved comments

1. Fetch all review comments:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments
   ```
2. Also fetch review threads to check resolution status:
   ```bash
   gh api graphql -f query='{ repository(owner:"{owner}", name:"{repo}") { pullRequest(number:{number}) { reviewThreads(first:100) { nodes { id, isResolved, comments(first:10) { nodes { body, path, line, author { login } } } } } } } }'
   ```
3. Filter to unresolved threads only. If all threads are resolved, say so and stop.

## Step 3: Triage each comment

For each unresolved comment, read the referenced code and understand the suggestion. Display a table:

| # | Reviewer | File | Suggestion | Recommendation |
|---|----------|------|-----------|----------------|
| 1 | copilot | path/to/file.rb:42 | Summary | **FIX** — reason |
| 2 | teammate | path/to/other.js:10 | Summary | **IGNORE** — reason |

Ask the user which recommendations to proceed with before making any changes.

## Step 4: Address each comment

Process comments one at a time. For each approved fix:
1. Make the code change.
2. Stage and commit with a message describing the fix.
3. Push: `git push`.
4. Reply to the PR comment thread with the commit SHA linked:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies -f body="Fixed in <commit_sha> — <what was changed>"
   ```
5. Resolve the thread using the thread's node ID from Step 2, and **confirm it actually resolved**:
   ```bash
   gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "<thread_node_id>"}) { thread { isResolved } } }' --jq '.data.resolveReviewThread.thread.isResolved'
   ```

For each approved ignore:
1. Reply to the PR comment thread explaining why:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies -f body="Won't fix — <reasoning>"
   ```
2. Resolve the thread, confirming it resolved the same way:
   ```bash
   gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "<thread_node_id>"}) { thread { isResolved } } }' --jq '.data.resolveReviewThread.thread.isResolved'
   ```

**The mutation must print `true`.** GraphQL reports a bad node ID, a stale thread, or a permissions problem as an `errors` array with HTTP 200, so an unresolved thread looks identical to a resolved one unless you read the result. Anything other than `true` means that thread is still open: say so in your reply to the user and leave it out of the "resolved" count rather than assuming it landed.

## Step 5: Update PR description

If any code changes were made in Step 4, rewrite the description to reflect the current state of the code:
- Update the summary so it reads as though the PR were just created.
- Update the test plan:

**IMPORTANT: Before rewriting, fetch the current PR body first** with `gh pr view --json body` and check which test plan items are currently checked (`- [x]`). You MUST preserve this information:
  1. Uncheck all items.
  2. For any item that existed before, is unchanged, and was previously checked, append "🔄" to indicate it needs re-verification.
  3. Remove items that are no longer relevant and add new ones if needed.

```bash
gh pr edit {number} --body "<rewritten body>"
```
