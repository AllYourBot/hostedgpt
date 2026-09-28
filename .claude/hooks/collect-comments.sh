#!/bin/bash
#
# PostToolUse hook: silently records comment lines added by each Edit/Write so
# the Stop hook (check-comments.sh) can prompt one cleanup pass at turn end.
# Deliberately emits nothing per-edit — drafting comments mid-task is fine.
#
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE" ] && exit 0

case "$FILE" in
  /tmp/* | /private/tmp/* | /var/folders/*)
    exit 0
    ;;
esac

case "$FILE" in
  *.rb | *.rake | *.py)
    PATTERN='^[[:space:]]*#'
    ;;
  *.js | *.jsx | *.swift)
    PATTERN='^[[:space:]]*(//|/\*|\*/|\*([[:space:]]|$))'
    ;;
  *)
    if [[ -f $FILE ]] && head -1 "$FILE" 2>/dev/null | grep -q '^#!/usr/bin/env ruby'; then
      PATTERN='^[[:space:]]*#'
    else
      exit 0
    fi
    ;;
esac

NEW=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // ""')
OLD=$(echo "$INPUT" | jq -r '.tool_input.old_string // ""')

ADDED=$(printf '%s\n' "$NEW" | grep -E "$PATTERN" || true)
OLD_COMMENTS=$(printf '%s\n' "$OLD" | grep -E "$PATTERN" || true)
if [ -n "$OLD_COMMENTS" ]; then
  ADDED=$(printf '%s\n' "$ADDED" | grep -Fxv -f <(printf '%s\n' "$OLD_COMMENTS") || true)
fi

ALLOWED='^#!|#\{|frozen_string_literal|^[[:space:]]*#[[:space:]]*(encoding|rubocop:)|eslint-|prettier-'
ADDED=$(printf '%s\n' "$ADDED" | grep -Ev "$ALLOWED" || true)

case "$FILE" in
  */test/* | *_test.rb | *test_*.py)
    ADDED=$(printf '%s\n' "$ADDED" | grep -Eiv '^[[:space:]]*#[[:space:]].*tests?[[:space:]]*$' || true)
    ;;
esac

[ -z "$(printf '%s' "$ADDED" | grep . || true)" ] && exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')
ACCUMULATOR="${TMPDIR:-/tmp}/claude-comment-check-${SESSION_ID}"
printf '%s\n' "$ADDED" | grep . | while IFS= read -r line; do
  printf '%s\t%s\n' "$FILE" "$line" >> "$ACCUMULATOR"
done

exit 0
