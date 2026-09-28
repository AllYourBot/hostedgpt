#!/bin/bash
# SessionStart hook: nudge toward /pr-catchup when teammates have merged since
# the user's last catchup — the /pr-catchup skill does the explaining. When main
# moved only with the user's own merges, silently advances the checkpoint
# instead. Silent on any failure (offline, no checkpoint, detached state):
# a missing nudge costs nothing, a broken session start costs a lot.
set -uo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] && exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

slug=$(git remote get-url upstream 2>/dev/null \
  | sed -E 's#\.git$##; s#.*[:/]([^/]+/[^/]+)$#\1#; s#/#-#') || exit 0
checkpoint="$HOME/.claude/pr-catchup/$slug"
[ -f "$checkpoint" ] || exit 0

git fetch upstream main --quiet 2>/dev/null || exit 0

last=$(head -1 "$checkpoint")
git cat-file -e "$last" 2>/dev/null || exit 0

# Squash commits carry the PR author's GitHub identity, which can differ from
# the local git config (name matches, email may not) — match either.
my_name=$(git config user.name 2>/dev/null) || my_name=
my_email=$(git config user.email 2>/dev/null) || my_email=
team_count=$(git log --format='%an%x09%ae' "$last..upstream/main" 2>/dev/null \
  | awk -F'\t' -v n="$my_name" -v e="$my_email" '$1 != n && $2 != e' | wc -l | tr -d ' ') || exit 0

if [ "${team_count:-0}" -gt 0 ]; then
  # Plain stdout from a SessionStart hook is context for the model only; the
  # systemMessage field is what actually renders in the user's terminal.
  msg="Heads up: the team merged $team_count PR(s) since your last catchup. Run /pr-catchup for a plain-language summary of their work."
  printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$msg" "$msg"
else
  head_sha=$(git rev-parse upstream/main 2>/dev/null) || head_sha=
  if [ -n "$head_sha" ] && [ "$head_sha" != "$last" ]; then
    # main moved but only with the user's own merges — caught up by definition,
    # so advance the checkpoint to keep the skills' staleness checks in agreement.
    {
      echo "$head_sha"
      git log -1 --format=%cI upstream/main
    } > "$checkpoint" 2>/dev/null || true
  fi
fi
exit 0
