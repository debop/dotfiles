#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CODEX_SYNC_SCRIPT="${CODEX_SYNC_SCRIPT:-$DOTFILES_DIR/bin/sync-codex.sh}"
SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

find_real_codex() {
  local candidate

  if [[ -n "${REAL_CODEX_BIN:-}" && -x "${REAL_CODEX_BIN}" ]]; then
    printf '%s\n' "${REAL_CODEX_BIN}"
    return 0
  fi

  while IFS= read -r candidate; do
    [[ -n "$candidate" && "$candidate" != "$SELF_PATH" ]] && {
      printf '%s\n' "$candidate"
      return 0
    }
  done < <(which -a codex 2>/dev/null | awk '!seen[$0]++')

  return 1
}

main() {
  local real_codex

  if [[ -x "$CODEX_SYNC_SCRIPT" ]]; then
    "$CODEX_SYNC_SCRIPT" --quiet
  fi

  real_codex="$(find_real_codex)" || {
    echo "real codex binary not found" >&2
    exit 1
  }

  exec "$real_codex" "$@"
}

main "$@"
