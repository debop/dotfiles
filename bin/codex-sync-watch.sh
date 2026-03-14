#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
SYNC_SCRIPT="${CODEX_SYNC_SCRIPT:-$DOTFILES_DIR/bin/sync-codex.sh}"
LOG_FILE="${CODEX_SYNC_LOG_FILE:-$HOME/.codex-sync-watch.log}"
DEBOUNCE_SECONDS="${CODEX_SYNC_DEBOUNCE_SECONDS:-2}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

main() {
  command -v fswatch >/dev/null 2>&1 || {
    log "fswatch not found; exiting"
    exit 1
  }

  [[ -x "$SYNC_SCRIPT" ]] || {
    log "sync script not executable: $SYNC_SCRIPT"
    exit 1
  }

  log "watching $DOTFILES_DIR for Codex config changes"

  fswatch -or \
    -e '/\.git/' \
    -e '/\.DS_Store$' \
    -i '/codex/' \
    -i '/agents/skills/' \
    -i '/omx/agents/' \
    -i '/bin/sync-codex\.sh$' \
    -i '/bin/codex-wrapper\.sh$' \
    -i '/setup\.sh$' \
    "$DOTFILES_DIR" | while read -r _; do
      sleep "$DEBOUNCE_SECONDS"
      if "$SYNC_SCRIPT" --quiet; then
        log "sync complete"
      else
        log "sync failed"
      fi
    done
}

main "$@"
