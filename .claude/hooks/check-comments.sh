#!/bin/bash
#
# Stop hook: reads the comment lines collect-comments.sh accumulated during the
# turn, drops any already deleted, and asks Claude for one cleanup pass. The
# stop_hook_active guard makes this one-shot — comments Claude deliberately
# keeps are never re-flagged.
#
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')
ACCUMULATOR="${TMPDIR:-/tmp}/claude-comment-check-${SESSION_ID}"
[ -s "$ACCUMULATOR" ] || exit 0

if [ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  rm -f "$ACCUMULATOR"
  exit 0
fi

REMAINING=$(
  sort -u "$ACCUMULATOR" | while IFS=$'\t' read -r file line; do
    [ -f "$file" ] || continue
    # Autobrowse scripts carry their procedure as numbered step comments by
    # convention — comment cleanup does not apply to them. Class-form scripts
    # say `include Autobrowse`; flat single-command scripts only require it.
    grep -qE "include Autobrowse|\.ruby/autobrowse" "$file" && continue
    if grep -Fxq -- "$line" "$file"; then
      printf '%s: %s\n' "$file" "$line"
    fi
  done
)
rm -f "$ACCUMULATOR"
[ -z "$REMAINING" ] && exit 0

MESSAGE=$(
  echo "Comment cleanup pass: it's okay that you added comments while drafting this code —"
  echo "but now that the code is settling, clean them up. These comment lines you added"
  echo "are still present:"
  echo
  printf '%s\n' "$REMAINING" | head -20
  echo
  echo "This project's policy is to write code that is self-explanatory. We do that with"
  echo "helpful variable and method names, abstractions like a named concern, or an"
  echo "intermediate variable — not comments. Re-read each line above with fresh eyes:"
  echo "prefer making the code carry the meaning, and otherwise delete the comment. It"
  echo "may stay only if, even after those best practices, the code still does something"
  echo "subtle a future developer reading carefully would miss (hidden coupling, a"
  echo "workaround for a specific bug, a surprising invariant) — and even then, be"
  echo "succinct. This check will not flag these lines again, so when you're done"
  echo "reflecting and removing/improving comments, continue with whatever you were"
  echo "saying to the user."
  echo
  echo "After acting on this message, you need to restate the exact message you just"
  echo "gave since it will be buried in all this comment cleanup work so the user won't"
  echo "see it."
)

jq -n --arg reason "$MESSAGE" '{decision: "block", reason: $reason, suppressOutput: true}'
exit 0
