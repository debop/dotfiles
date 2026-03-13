#!/usr/bin/env bash
# dotfiles 변경 감지 → 자동 commit + push
# launchd로 로그인 시 자동 실행됨

DOTFILES_DIR="$HOME/dotfiles"
LOG_FILE="$HOME/.dotfiles-watch.log"
DEBOUNCE=5  # 초 (마지막 변경 후 이 시간 기다렸다가 commit)

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

commit_and_push() {
  cd "$DOTFILES_DIR" || return

  # 변경사항 있을 때만 커밋
  if ! git diff --quiet || ! git diff --cached --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
    git add -A
    git commit -m "chore: auto-sync dotfiles [$(date '+%Y-%m-%d %H:%M:%S')]"
    git push && log "push 완료" || log "push 실패"
  fi
}

log "감시 시작: $DOTFILES_DIR"

fswatch -r -e "\.git" -e "\.DS_Store" --event=Created --event=Updated --event=Removed \
  "$DOTFILES_DIR" | while read -r event; do
    log "변경 감지: $event"
    # debounce: 연속 변경은 묶어서 처리
    sleep "$DEBOUNCE"
    commit_and_push
  done
