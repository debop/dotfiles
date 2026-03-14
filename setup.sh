#!/usr/bin/env bash
# dotfiles setup script - 전체 환경 일괄 설치
# Usage: bash setup.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CODEX_DIR="$HOME/.codex"
ENABLE_CLAUDE_DOTFILES="${ENABLE_CLAUDE_DOTFILES:-1}"

echo "==> dotfiles 설치 시작: $DOTFILES_DIR"

# ── 헬퍼 ─────────────────────────────────────────────────────────────
link_file() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    echo "  백업: $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -s "$src" "$dst"
  echo "  링크: $dst"
}

mcp_add() {
  local name="$1"; shift
  if claude mcp list 2>/dev/null | grep -q "^$name:"; then
    echo "  스킵 (이미 등록): $name"
  else
    claude mcp add "$name" -- "$@"
    echo "  등록: $name"
  fi
}

install_from_template() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  sed "s|__HOME__|$HOME|g" "$src" > "$dst"
  echo "  생성: $dst"
}

# ── 1. Homebrew ──────────────────────────────────────────────────────
echo ""
echo "==> [1/8] Homebrew 패키지..."
if ! command -v brew &>/dev/null; then
  echo "  Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew bundle install --file="$DOTFILES_DIR/Brewfile"

# ── 2. 쉘 설정 ──────────────────────────────────────────────────────
echo ""
echo "==> [2/8] 쉘 설정..."
link_file "$DOTFILES_DIR/zshrc"    "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zprofile" "$HOME/.zprofile"
link_file "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
mkdir -p "$HOME/.local/bin"

# 시크릿 파일 안내
if [[ ! -f "$HOME/.zshrc_secrets" ]]; then
  cp "$DOTFILES_DIR/zshrc_secrets.example" "$HOME/.zshrc_secrets"
  echo "  생성: ~/.zshrc_secrets (값을 직접 채워주세요)"
else
  echo "  스킵: ~/.zshrc_secrets (이미 존재)"
fi

# ── 3. Cursor ────────────────────────────────────────────────────────
echo ""
echo "==> [3/8] Cursor 설정..."
mkdir -p "$HOME/.cursor"
link_file "$DOTFILES_DIR/cursor/mcp.json" "$HOME/.cursor/mcp.json"

# ── 4. Claude Code 설정 ──────────────────────────────────────────────
echo ""
echo "==> [4/8] Claude Code 설정..."
if [[ "$ENABLE_CLAUDE_DOTFILES" == "1" ]]; then
  mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/hooks"

  link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  link_file "$DOTFILES_DIR/claude/RTK.md"    "$CLAUDE_DIR/RTK.md"

  # settings.json — __HOME__ 치환 후 복사 (없을 때만)
  if [[ ! -f "$CLAUDE_DIR/settings.json" ]]; then
    sed "s|__HOME__|$HOME|g" "$DOTFILES_DIR/claude/settings.json" > "$CLAUDE_DIR/settings.json"
    echo "  복사: settings.json (신규)"
  else
    echo "  스킵: settings.json (이미 존재 — 수동 머지 필요)"
  fi

  # hooks
  for hook in "$DOTFILES_DIR/claude/hooks/"*.sh; do
    name="$(basename "$hook")"
    link_file "$hook" "$CLAUDE_DIR/hooks/$name"
    chmod +x "$CLAUDE_DIR/hooks/$name"
  done

  # skills
  for skill_dir in "$DOTFILES_DIR/claude/skills/"*/; do
    name="$(basename "$skill_dir")"
    dst="$CLAUDE_DIR/skills/$name"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
      mv "$dst" "${dst}.bak"
      echo "  백업: skills/$name"
    fi
    link_file "$skill_dir" "$dst"
  done
else
  echo "  스킵: Claude 경로는 자동 관리하지 않음 (ENABLE_CLAUDE_DOTFILES=1 로 opt-in)"
fi

# ── 5. Codex / oh-my-codex 설정 ─────────────────────────────────────
echo ""
echo "==> [5/8] Codex 설정..."
mkdir -p "$CODEX_DIR" "$HOME/.agents" "$HOME/.omx/agents"
chmod +x "$DOTFILES_DIR/bin/sync-codex.sh"
chmod +x "$DOTFILES_DIR/bin/codex-wrapper.sh"
chmod +x "$DOTFILES_DIR/bin/codex-sync-watch.sh"
chmod +x "$DOTFILES_DIR/bin/codex-preflight.sh"
link_file "$DOTFILES_DIR/bin/codex-wrapper.sh" "$HOME/.local/bin/codex"
link_file "$DOTFILES_DIR/bin/sync-codex.sh" "$HOME/.local/bin/codex-sync"
"$DOTFILES_DIR/bin/sync-codex.sh"

mkdir -p "$HOME/Library/LaunchAgents"
install_from_template \
  "$DOTFILES_DIR/launchagents/com.debop.codex-sync-watch.plist" \
  "$HOME/Library/LaunchAgents/com.debop.codex-sync-watch.plist"
launchctl unload "$HOME/Library/LaunchAgents/com.debop.codex-sync-watch.plist" >/dev/null 2>&1 || true
launchctl load "$HOME/Library/LaunchAgents/com.debop.codex-sync-watch.plist"

# ── 6. MCP 서버 자동 등록 ────────────────────────────────────────────
echo ""
echo "==> [6/8] MCP 서버 등록..."
mcp_add git        uvx mcp-server-git
mcp_add context7   npx -y @upstash/context7-mcp
mcp_add filesystem npx -y @modelcontextprotocol/server-filesystem "$HOME" "$HOME/work"

# exa — API 키 필요
if [[ -n "${EXA_API_KEY:-}" ]]; then
  mcp_add exa npx -y exa-mcp-server
else
  echo "  스킵: exa (EXA_API_KEY 미설정 — ~/.zshrc_secrets에 추가 후 수동 등록)"
  echo "        claude mcp add exa -- npx -y exa-mcp-server"
fi

# ── 7. Gradle 설정 ───────────────────────────────────────────────────
echo ""
echo "==> [7/8] Gradle 설정..."
mkdir -p "$HOME/.gradle"
if [[ ! -f "$HOME/.gradle/gradle.properties" ]]; then
  cp "$DOTFILES_DIR/gradle/gradle.properties.example" "$HOME/.gradle/gradle.properties"
  echo "  생성: ~/.gradle/gradle.properties (값을 직접 채워주세요)"
else
  echo "  스킵: ~/.gradle/gradle.properties (이미 존재)"
fi

# ── 8. Maven toolchains + jenv ────────────────────────────────────────
echo ""
echo "==> [8/8] Maven toolchains + jenv 설정..."
mkdir -p "$HOME/.m2"
link_file "$DOTFILES_DIR/m2/toolchains.xml" "$HOME/.m2/toolchains.xml"

if command -v jenv &>/dev/null; then
  for jdk_home in /Library/Java/JavaVirtualMachines/*/Contents/Home; do
    [[ -d "$jdk_home" ]] && jenv add "$jdk_home" 2>/dev/null || true
  done
  jenv global 21
  echo "  완료: jenv global=21"
else
  echo "  스킵: jenv 미설치 (brew install jenv 후 재실행)"
fi

# ── 완료 ─────────────────────────────────────────────────────────────
echo ""
echo "==> 완료! 다음 단계:"
echo "  1. ~/.zshrc_secrets 에 API 키 값 입력"
echo "  2. ~/.gradle/gradle.properties 에 토큰/GPG 키 값 입력"
echo "  3. 새 터미널 열기 (zshrc 반영)"
echo "  4. Claude Code 재시작"
echo "  5. Codex 실행 전 dotfiles 기반 sync 가 자동 수행됨"
echo "  6. JetBrains IDE 열면 jetbrains/intellij-index MCP 자동 등록됨"
