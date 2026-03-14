#!/usr/bin/env bash
# ~/dotfiles/bin/dotfiles-sync.sh
# 양방향 동기화: ~/.claude ↔ ~/dotfiles/claude + git push/pull
# claude/codex 실행 전 자동 호출됨 (zshrc 래퍼)
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CLAUDE_DIR="$HOME/.claude"
QUIET=0; [[ "${1:-}" == "--quiet" ]] && QUIET=1
log() { [[ "$QUIET" -eq 0 ]] && echo "$@" || true; }

[[ -d "$DOTFILES_DIR/.git" ]] || exit 0

# 복사 동기화 대상 (symlink가 아닌 파일들)
SYNC_FILES=(settings.json plugins/installed_plugins.json plugins/blocklist.json)

# --- 1) 역동기화: ~/.claude → dotfiles (로컬 변경 수집) ---
for f in "${SYNC_FILES[@]}"; do
  src="$CLAUDE_DIR/$f"
  dst="$DOTFILES_DIR/claude/$f"
  [[ -f "$src" && ! -L "$src" ]] || continue
  mkdir -p "$(dirname "$dst")"
  if ! cmp -s "$src" "$dst" 2>/dev/null; then
    cp "$src" "$dst"
    log "← $f → dotfiles"
  fi
done

# --- 2) git commit + push (변경 있을 때만) ---
cd "$DOTFILES_DIR"
git fetch --quiet origin 2>/dev/null || true

if [[ $(git status --porcelain | wc -l | tr -d ' ') -gt 0 ]]; then
  git add -A
  git commit -m "auto sync: $(date '+%Y-%m-%d %H:%M') [$(hostname -s)]" --quiet 2>/dev/null || true
  git push --quiet origin main 2>/dev/null || true
fi

# --- 3) pull (원격 변경 있을 때만) ---
BEHIND=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo 0)
if [[ "$BEHIND" -gt 0 ]]; then
  git pull --quiet --rebase origin main 2>/dev/null || true
fi

# --- 4) 정동기화: dotfiles → ~/.claude (pull로 받은 변경 반영) ---
for f in "${SYNC_FILES[@]}"; do
  src="$DOTFILES_DIR/claude/$f"
  dst="$CLAUDE_DIR/$f"
  [[ -f "$src" ]] || continue
  if ! cmp -s "$src" "$dst" 2>/dev/null; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    log "→ $f → ~/.claude"
  fi
done

log "dotfiles sync complete"
