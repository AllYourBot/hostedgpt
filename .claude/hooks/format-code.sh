#!/bin/bash
#
# PostToolUse hook: auto-formats Ruby files with rubocop after Claude edits or writes them.
#
FILE=$(cat | jq -r '.tool_input.file_path')

is_ruby_file() {
  [[ $1 =~ \.(rb|rake)$ ]] && return 0
  [[ -f "$1" ]] && head -1 "$1" 2>/dev/null | grep -q '#!/usr/bin/env ruby' && return 0
  return 1
}

if is_ruby_file "$FILE"; then
  cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bin/rubocop -a --except Lint/UselessAssignment "$FILE" 2>/dev/null
fi

exit 0
