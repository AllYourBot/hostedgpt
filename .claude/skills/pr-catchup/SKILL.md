---
name: pr-catchup
description: Catch up on the team's merges since you last checked in
argument-hint: optional since-date (e.g. "thursday" or 2026-07-23) to override the checkpoint
allowed-tools: Read, Write, Bash(git *), Bash(gh *), Bash(mkdir *)
---

# /pr-catchup

Tells the user what the **rest of the team** shipped since they last caught up. The audience is a person about to start work, not a changelog reader: every entry must answer "what changed, in plain words, and does it affect how I work today."

Two hard rules shape everything below:

- **Never summarize the user's own work.** They were there. Only other authors' PRs get entries.
- **Plain language only.** No jargon the user wouldn't say out loud. If a technical term is unavoidable, explain it in ordinary words the first time.

## User context

Optional since-date: $ARGUMENTS

## Step 1: Fetch

```bash
git fetch upstream main
```

Everything below reasons about `upstream/main`, never local branches — the user may be mid-work on some feature branch, and this skill must not touch their checkout.

## Step 2: Establish the range

**If the user passed a since-date**, skip the checkpoint entirely and cover `upstream/main` commits since that date (`git log --since="<date>" upstream/main`). Accept any human way of writing a date — a day name ("thursday" = the most recent past one), a relative phrase ("3 days ago", "last week"), or a numeric date. **Numeric dates with slashes are day/month/year** (03/04/26 = April 3rd, not March 4th) — resolve it yourself and pass git an unambiguous ISO date rather than the raw string. Work the date you actually used into the opening line naturally ("Since Thursday, …") — never meta-commentary like "resolved from 'thursday'"; the user typed it two seconds ago. An explicit date also means **skip Step 5** — this mode exists for testing and re-reading, and must leave the checkpoint untouched so it can be run repeatedly.

Otherwise, use the checkpoint. The checkpoint records the last `upstream/main` commit the user was caught up through. It lives **outside** the clone so all sibling clones of this repo share it:

```bash
SLUG=$(git remote get-url upstream | sed -E 's#\.git$##; s#.*[:/]([^/]+/[^/]+)$#\1#; s#/#-#')
CHECKPOINT="$HOME/.claude/pr-catchup/$SLUG"
```

Read the file with the Read tool. Line 1 is the SHA, line 2 an ISO timestamp (informational only).

- **File exists and SHA equals `upstream/main`:** the user is fully caught up. Say so in one line, update nothing else, and stop. Do not pad this out.
- **File exists, SHA differs:** the range to cover is `<sha>..upstream/main`. But before treating the user as behind, check who authored the range: if every commit in it is one of the user's own merges (Step 3's authorship check), they are caught up by definition — "behind" only ever means behind on *other people's* work. Say so in one line, advance the checkpoint to `upstream/main` per Step 5, and stop. If the SHA is no longer in history (`git cat-file -e <sha>` fails — e.g. after a very long absence), fall back to the first-run behavior below and say so.
- **File missing (first run):** anchor on the user's own last merged PR — the best available marker of when they last worked:

  ```bash
  gh pr list --author @me --state merged --base main --limit 1 --json number,mergeCommit,mergedAt
  ```

  Cover everything on `upstream/main` **after** that merge commit, and mention the anchor in the opening line ("Since your PR#941 merged on Thursday, …"). If the user has no merged PR at all, fall back to the last two weeks and say so. If the anchor is very old (months), still honor it — that's genuinely how long they've been away — but group entries aggressively so the recap stays readable.

## Step 3: Collect what the team merged

PRs are squash-merged, so each commit on `main` is usually one PR with the PR number in its subject (a commit pushed straight to `main` has none — mention it by subject if another author made it):

```bash
git log --reverse --format='%H|%ad|%s' --date=short <range>
```

Extract the `(#N)` PR numbers. Establish the user's login with `gh api user -q .login` and drop every PR they authored — check authorship via the PR data, not the commit, since squash commits can carry co-authors:

```bash
gh pr view <N> --json number,title,author,mergedAt,body,files,additions,deletions,url
```

Read each remaining PR's title, body, and files. The body usually explains the why better than the diff — use it.

## Step 4: Print the recap — as message text, now

The recap **is the product of this skill**; a run that gathers everything but never prints it has failed. Deliver it as the **final message of your turn** — never as an aside between tool calls, where it will be compressed into a status line and lost. Use exactly this shape (one block per entry, placeholders filled):

```
Since <anchor, e.g. "your PR#941 merged on Thursday">, the team merged <K> PRs:

PR#<N> **<3–5 word plain-words headline>** (+<adds> −<dels>) <bare PR URL>
<1–2 plain sentences: what changed and why, in words the user would use.> Affects you: <...>

PR#<N> ...

Total: +<sum> −<sum>
```

Rules for filling it in:

- The header line's URL is bare — never markdown `[text](url)` syntax, which does not render as a clickable link in the terminal.

- Order entries **chronologically, oldest first**, so it reads like the story of what happened while the user was away.
- Include the **Affects you:** sentence only when the change actually alters how the user works — a renamed command, a new required step, a moved file, changed setup or deploy behavior, a rewritten area they're likely to touch. Most entries won't need it; don't manufacture impact.

## Step 5: Update the checkpoint

**Skip this step entirely if the user passed a since-date** (Step 2). Otherwise, only after the summary is delivered — and "delivered" means the formatted recap has actually been printed to the user as message text; having gathered all the data is not delivery:

```bash
mkdir -p "$HOME/.claude/pr-catchup"
```

Then Write the file: line 1 the `upstream/main` SHA you summarized through, line 2 the current ISO timestamp (`git log -1 --format=%cI upstream/main` works — no need for a `date` call). Never update the checkpoint if the summary failed to produce; the user shouldn't lose a catchup to an error.
