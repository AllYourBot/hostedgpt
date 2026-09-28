#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

if echo "$COMMAND" | grep -qiE "gh signoff|context['\"]?[=:][[:space:]]*['\"]?signoff"; then
  echo "BLOCKED: Creating signoff status is not allowed. Only bin/ci can sign off commits." >&2
  exit 2
fi

exit 0
