#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${CODEX_PREFLIGHT_LOG_FILE:-$HOME/.codex/preflight.log}"
mkdir -p "$(dirname "$LOG_FILE")"

warn() {
  local msg="$1"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >> "$LOG_FILE"
}

check_bin() {
  local name="$1"
  command -v "$name" >/dev/null 2>&1 || warn "missing binary: $name"
}

main() {
  check_bin node
  check_bin npx
  check_bin uvx
  check_bin omx

  if [[ -n "${CODEX_INTELLIJ_INDEX_URL:-}" ]]; then
    :
  elif ! nc -z 127.0.0.1 29170 >/dev/null 2>&1; then
    warn "intellij-index endpoint not reachable on 127.0.0.1:29170"
  fi
}

main "$@"
