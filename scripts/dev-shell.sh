#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"
REQ_FILE="${ROOT_DIR}/example/requirements.txt"

cd "${ROOT_DIR}"

if ! command -v bundle >/dev/null 2>&1; then
  echo "Bundler not found. Install with: gem install bundler"
  exit 1
fi

if ! command -v python >/dev/null 2>&1; then
  echo "Python not found in PATH."
  exit 1
fi

echo "[1/4] Installing Ruby gems..."
bundle install

echo "[2/4] Creating Python virtualenv (.venv)..."
python -m venv "${VENV_DIR}"

echo "[3/4] Installing Python requirements..."
"${VENV_DIR}/bin/pip" install -r "${REQ_FILE}"

echo "[4/4] Loading environment variables..."
export PYTHONPATH="${ROOT_DIR}/lib:${PYTHONPATH:-}"
export RUBYLIB="${ROOT_DIR}/lib:${RUBYLIB:-}"

if [[ "${1:-}" == "--command" ]]; then
  shift
  exec "$@"
fi

echo "Environment ready."
echo "Run with command passthrough:"
echo "  scripts/dev-shell.sh --command ruby example/bot.rb"
echo
echo "Starting interactive shell with .venv active..."
# Shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
exec "${SHELL:-bash}"
