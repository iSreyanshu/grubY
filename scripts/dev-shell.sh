#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

if ! command -v bundle >/dev/null 2>&1; then
  echo "Bundler not found. Install with: gem install bundler"
  exit 1
fi

echo "[1/2] Installing Ruby gems..."
bundle install

echo "[2/2] Loading environment variables..."
export RUBYLIB="${ROOT_DIR}/lib:${RUBYLIB:-}"

if [[ "${1:-}" == "--command" ]]; then
  shift
  exec "$@"
fi

echo "Environment ready."
echo "Run with command passthrough:"
echo "  scripts/dev-shell.sh --command ruby example/bot.rb"
echo
echo "Starting interactive shell..."
exec "${SHELL:-bash}"
