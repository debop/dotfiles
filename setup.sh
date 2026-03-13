#!/usr/bin/env bash
# dotfiles setup script
# Usage: bash setup.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "==> dotfiles 설치 시작: $DOTFILES_DIR"

# ~/.claude 디렉토리 생성
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/hooks"

# ── CLAUDE.md / RTK.md ──────────────────────────────────────────────
link_file() {
  local src="$1" dst="$2"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "  백업: $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -sf "$src" "$dst"
  echo "  링크: $dst"
}

link_file "$DOTFILES_DIR/claude/CLAUDE.md"    "$CLAUDE_DIR/CLAUDE.md"
link_file "$DOTFILES_DIR/claude/RTK.md"       "$CLAUDE_DIR/RTK.md"

# ── settings.json (없을 때만 복사, 덮어쓰지 않음) ────────────────────
if [[ ! -f "$CLAUDE_DIR/settings.json" ]]; then
  cp "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"
  echo "  복사: settings.json (신규)"
else
  echo "  스킵: settings.json (이미 존재 — 수동 머지 필요)"
fi

# ── hooks (심볼릭 링크) ──────────────────────────────────────────────
for hook in "$DOTFILES_DIR/claude/hooks/"*.sh; do
  name="$(basename "$hook")"
  link_file "$hook" "$CLAUDE_DIR/hooks/$name"
  chmod +x "$CLAUDE_DIR/hooks/$name"
done

# ── skills (심볼릭 링크) ─────────────────────────────────────────────
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

# ── MCP 서버 등록 안내 ───────────────────────────────────────────────
echo ""
echo "==> MCP 서버 등록 (수동 실행 필요):"
echo "  claude mcp add git -- uvx mcp-server-git"
echo "  claude mcp add context7 -- npx -y @upstash/context7-mcp"
echo "  claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem \$HOME \$HOME/work"
echo "  claude mcp add exa -- npx -y exa-mcp-server  # EXA_API_KEY 환경변수 필요"
echo ""
echo "==> 완료! Claude Code를 재시작하세요."
