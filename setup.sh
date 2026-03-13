#!/usr/bin/env bash
# dotfiles setup script - 전체 환경 일괄 설치
# Usage: bash setup.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "==> dotfiles 설치 시작: $DOTFILES_DIR"

# ── 헬퍼 ─────────────────────────────────────────────────────────────
link_file() {
  local src="$1" dst="$2"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "  백업: $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -sf "$src" "$dst"
  echo "  링크: $dst"
}

# ── 1. Homebrew ──────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "==> Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "==> Brew 패키지 설치 중 (Brewfile)..."
brew bundle install --file="$DOTFILES_DIR/Brewfile" --no-lock

# ── 2. 쉘 설정 ──────────────────────────────────────────────────────
echo "==> 쉘 설정 링크..."
link_file "$DOTFILES_DIR/zshrc"    "$HOME/.zshrc"
link_file "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"

# ── 3. Claude Code 설정 ──────────────────────────────────────────────
echo "==> Claude Code 설정 링크..."
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/hooks"

link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link_file "$DOTFILES_DIR/claude/RTK.md"    "$CLAUDE_DIR/RTK.md"

# settings.json — 없을 때만 복사 (플러그인/권한 설정이 달라질 수 있음)
if [[ ! -f "$CLAUDE_DIR/settings.json" ]]; then
  cp "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"
  echo "  복사: settings.json (신규)"
else
  echo "  스킵: settings.json (이미 존재 — 수동 머지 필요)"
fi

# hooks 심볼릭 링크
for hook in "$DOTFILES_DIR/claude/hooks/"*.sh; do
  name="$(basename "$hook")"
  link_file "$hook" "$CLAUDE_DIR/hooks/$name"
  chmod +x "$CLAUDE_DIR/hooks/$name"
done

# skills 심볼릭 링크
for skill_dir in "$DOTFILES_DIR/claude/skills/"*/; do
  name="$(basename "$skill_dir")"
  dst="$CLAUDE_DIR/skills/$name"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "  백업: $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -sf "$skill_dir" "$dst"
  echo "  링크: skills/$name"
done

# ── 4. MCP 서버 등록 ─────────────────────────────────────────────────
echo ""
echo "==> MCP 서버 등록 (수동 실행 필요):"
echo "  claude mcp add git -- uvx mcp-server-git"
echo "  claude mcp add context7 -- npx -y @upstash/context7-mcp"
echo "  claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem \$HOME \$HOME/work"
echo "  claude mcp add exa -- npx -y exa-mcp-server  # EXA_API_KEY 환경변수 필요"

# ── 5. 완료 ──────────────────────────────────────────────────────────
echo ""
echo "==> 완료! 다음 단계:"
echo "  1. 위 MCP 서버 명령 실행"
echo "  2. Claude Code 재시작"
echo "  3. 새 터미널 열기 (zshrc 반영)"
