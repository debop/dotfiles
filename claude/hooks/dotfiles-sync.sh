#!/usr/bin/env bash
# SessionStart hook: dotfiles 자동 동기화
# - 로컬 변경사항 있으면 push
# - 원격에 새 변경사항 있으면 pull
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
[[ -d "$DOTFILES_DIR/.git" ]] || exit 0

cd "$DOTFILES_DIR"
git fetch --quiet origin 2>/dev/null || exit 0

LOCAL_CHANGED=$(git status --porcelain | wc -l | tr -d ' ')
BEHIND=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo 0)
AHEAD=$(git rev-list origin/main..HEAD --count 2>/dev/null || echo 0)

# 로컬 변경사항 있으면 커밋 + push
if [[ "$LOCAL_CHANGED" -gt 0 ]]; then
  brew bundle dump --file="$DOTFILES_DIR/Brewfile" --force 2>/dev/null || true
  git add -A
  git commit -m "auto sync: $(date '+%Y-%m-%d %H:%M') [$(hostname -s)]" --quiet
  git push --quiet origin main 2>/dev/null || true
elif [[ "$AHEAD" -gt 0 ]]; then
  git push --quiet origin main 2>/dev/null || true
fi

# 원격에 새 변경사항 있으면 pull
if [[ "$BEHIND" -gt 0 ]]; then
  git pull --quiet --rebase origin main 2>/dev/null || true
fi

exit 0
