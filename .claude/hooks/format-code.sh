#!/bin/bash
#
# PostToolUse hook: auto-formats files after Claude edits or writes them.
# Runs prettier on JS/JSX, rubocop on Ruby, ruff on Python, and swift-format on Swift files.
#
FILE=$(cat | jq -r '.tool_input.file_path')

# sandbox/ is deliberately unlinted (see .claude/rules/cli_script.md "Never run
# bin/rubocop on a sandbox path") — naming a file explicitly bypasses rubocop's
# Exclude list, and -a has already corrupted sandbox libs once.
[[ $FILE == */rails/sandbox/* ]] && exit 0

is_ruby_file() {
  [[ $1 =~ \.(rb|rake)$ ]] && return 0
  [[ -f "$1" ]] && head -1 "$1" 2>/dev/null | grep -q '#!/usr/bin/env ruby' && return 0
  return 1
}

if [[ $FILE =~ \.(js|jsx)$ ]]; then
  cd "$(dirname "$0")/../../rails" 2>/dev/null && npx prettier --write "$FILE" 2>/dev/null
elif is_ruby_file "$FILE"; then
  cd "$(dirname "$0")/../../rails" 2>/dev/null && bin/rubocop -a --except Lint/UselessAssignment "$FILE" 2>/dev/null
elif [[ $FILE =~ \.py$ ]]; then
  cd "$(dirname "$0")/../../livekit-menubar" 2>/dev/null && uv run ruff format "$FILE" 2>/dev/null
elif [[ $FILE =~ \.swift$ ]]; then
  xcrun swift-format format --in-place "$FILE" 2>/dev/null
fi

exit 0
