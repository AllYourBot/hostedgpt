#!/bin/bash
# SessionStart hook: prepare the Rails harness for Claude Code on the web.
#
# The base image ships Ruby 3.3.6 on PATH, but this repo pins Ruby via
# .ruby-version (4.0.2). rbenv + ruby-build are installed but not wired into
# the shell, so without this hook every command falls back to 3.3.6 and the
# Rails harness can't boot. Here we install/activate the pinned Ruby, install
# gems, prepare the test database, and persist the rbenv shims onto PATH for
# the rest of the session via $CLAUDE_ENV_FILE.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
RAILS_DIR="$PROJECT_DIR/rails"

cd "$RAILS_DIR"

# Installs the pinned Ruby if missing and activates rbenv in this shell.
source bin/ensure_ruby

# rbenv shims must stay on PATH for every later tool shell in this session,
# otherwise commands revert to the base-image Ruby 3.3.6.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  RBENV_ROOT_DIR="$(rbenv root)"
  {
    echo "export RBENV_ROOT=\"$RBENV_ROOT_DIR\""
    echo "export PATH=\"$RBENV_ROOT_DIR/shims:\$PATH\""
    # This container runs as root, and the claude CLI refuses
    # --dangerously-skip-permissions under root unless it knows it's sandboxed.
    # Any test that spawns the agent subprocess errors without this.
    echo "export IS_SANDBOX=1"
  } >> "$CLAUDE_ENV_FILE"
fi

bundle check >/dev/null 2>&1 || bundle install

# image_processing -> ruby-vips needs the native libvips library, which the
# base image doesn't ship. Without it, Active Storage variant tests error with
# "libvips.so.42: cannot open shared object file".
if ! ldconfig -p 2>/dev/null | grep -q libvips; then
  apt-get install -y libvips42 >/dev/null 2>&1 || true
fi

RAILS_ENV=test bin/rails db:prepare

# Views reference app/assets/builds/tailwind.css; an unbuilt container fails
# every rendering test with "The asset 'tailwind.css' was not found".
bin/rails tailwindcss:build >/dev/null

if [ ! -f config/master.key ] && [ -z "${RAILS_MASTER_KEY:-}" ]; then
  echo "NOTE: No config/master.key and RAILS_MASTER_KEY is unset. The normal test" >&2
  echo "suite runs fine without it. Only the live tiers (LIVE=1 / BROWSER=1) that" >&2
  echo "hit real APIs need RAILS_MASTER_KEY set in this environment's configuration." >&2
fi
