ZSH_DISABLE_COMPFIX=true
export ZSH="/Users/debop/.oh-my-zsh"
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"
plugins=(alias-tips asdf aws brew colorize docker docker-compose git gitignore git-flow git-prompt github golang gradle httpie jenv mvn npm pip python scala spring sudo systemd themes vscode xcode)
[[ -t 0 && -t 1 ]] && plugins=(fzf "${plugins[@]}")

export ANDROID_HOME=~/Library/Android/sdk
export JMETER_HOME=/usr/local/bin/jmeter

export GOPATH=~/work/go

# JAVA_HOME 설정 (이 방식보다 jenv enable-plugin gradle 방식이 더 좋다)
export JAVA_8_HOME=$(/usr/libexec/java_home -v1.8)
export JAVA_11_HOME=$(/usr/libexec/java_home -v11)
export JAVA_17_HOME=$(/usr/libexec/java_home -v17)
export JAVA_21_HOME=$(/usr/libexec/java_home -v21)
export JAVA_23_HOME=$(/usr/libexec/java_home -v23)
export JAVA_24_HOME=$(/usr/libexec/java_home -v24)
export JAVA_25_HOME=$(/usr/libexec/java_home -v25)

export JDK_16=$JAVA_HOME
export JDK_8=$JAVA_8_HOME

export PATH=$GOPATH/bin:$HOME/.jenv/bin:$JAVA_HOME:/usr/local/bin:/usr/local/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH:$ANDROID_HOME

# 터미널/폰트 아이콘이 깨지지 않도록 UTF-8 locale을 고정한다.
export LANG="${LANG:-ko_KR.UTF-8}"
export LC_CTYPE="${LC_CTYPE:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"

# AsciiDoctor
export XML_CATALOG_FILES=/usr/local/etc/xml/catalog

# jenv 환경설정
eval "$(jenv init -)"

#
# ZSH 
#
source /opt/homebrew/opt/zsh-git-prompt/zshrc.sh
export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/opt/homebrew/share/zsh-syntax-highlighting/highlighters
source $ZSH/oh-my-zsh.sh
source /opt/homebrew/share/zsh-autopair/autopair.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-you-should-use/you-should-use.plugin.zsh

# Colima
# unset TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock

# Python
alias python="python3"
alias pip="pip3"

alias zshconfig="cursor ~/.zshrc"
alias ohmyzsh="cursor ~/.oh-my-zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

function fzfv()
{
    fzf --preview '[[ $(file --mime {}) =~ binary ]] &&
                 echo {} is a binary file ||
                 (cat {}) 2> /dev/null | head -500'
}

# https://platform.openai.com/account/api-keys

# Claude Code
export CLAUDE_CODE_ENABLE_LSP=1
export ENABLE_LSP_TOOL=1

# proto
export PROTO_HOME="$HOME/.proto";
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH";export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql@8.4/bin:$PATH"

# Github Package
export BLUETAPE4K_GITHUB_USERNAME=debop

export GPG_TTY=$(tty)
export PATH="$HOME/.local/bin:$PATH"


# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/debop/.lmstudio/bin"
# End of LM Studio CLI section

# Zeroclaw (https://github.com/openagen/zeroclaw)
export PATH=$HOME/.cargo/bin:$PATH


# Added by Antigravity
export PATH="/Users/debop/.antigravity/antigravity/bin:$PATH"

# OpenClaw Completion
[[ -f "/Users/debop/.openclaw/completions/openclaw.zsh" ]] && source "/Users/debop/.openclaw/completions/openclaw.zsh"

[[ -o interactive && -t 0 && -f "/Users/debop/.config/kaku/zsh/kaku.zsh" ]] && source "/Users/debop/.config/kaku/zsh/kaku.zsh" # Kaku Shell Integration

portpid() {
  local port="$1"
  if [[ -z "$port" ]]; then
    echo "usage: portpid <port>"
    return 1
  fi

  lsof -nP -iTCP:"$port" -sTCP:LISTEN -t
}

portinfo() {
  local port="$1"
  if [[ -z "$port" ]]; then
    echo "usage: portinfo <port>"
    return 1
  fi

  lsof -nP -iTCP:"$port" -sTCP:LISTEN
}

killport() {
  local port="$1"
  if [[ -z "$port" ]]; then
    echo "usage: killport <port>"
    return 1
  fi

  local pids
  pids=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -t)

  if [[ -z "$pids" ]]; then
    echo "No listening process found on port $port"
    return 0
  fi

  echo "Killing process(es) on port $port: $pids"
  kill -15 $pids
}

# Kill port and force kill
# Usage: $ killport9 8080
killport9() {
  local port="$1"
  if [[ -z "$port" ]]; then
    echo "usage: killport9 <port>"
    return 1
  fi

  local pids
  pids=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -t)

  if [[ -z "$pids" ]]; then
    echo "No listening process found on port $port"
    return 0
  fi

  echo "Force killing process(es) on port $port: $pids"
  kill -9 $pids
}

# Claude Code aliases
alias cc='claude'
alias ccd='claude --dangerously-skip-permissions'
alias ccr='claude --resume --dangerously-skip-permissions'

# Codex sync + wrapper
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
export CODEX_SYNC_SCRIPT="$DOTFILES_DIR/bin/sync-codex.sh"

codex-sync() {
  command codex-sync "$@"
}

codex() {
  if [[ -x "$CODEX_SYNC_SCRIPT" ]]; then
    "$CODEX_SYNC_SCRIPT" --quiet >/dev/null 2>&1 || true
  fi
  command codex "$@"
}

# ─────────────────────────────────────────────
# Rust 기반 CLI 도구 초기화
# ─────────────────────────────────────────────

# zoxide (cd 대체 — z 명령어)
eval "$(zoxide init zsh)"

# atuin (히스토리 검색 강화 — Ctrl+R 대체)
eval "$(atuin init zsh)"

# yazi 편의 함수 (파일 매니저 종료 시 해당 디렉토리로 이동)
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ─────────────────────────────────────────────
# Alias — Rust 도구로 대체
# ─────────────────────────────────────────────
alias l='eza -la --icons --git'
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --icons -L 2'
alias cat='bat --paging=never'
alias lg='lazygit'

# tmux 안에서도 truecolor와 UTF-8 환경을 유지한다.
if [[ -n "$TMUX" ]]; then
  export TERM="${TERM:-tmux-256color}"
  export COLORTERM="${COLORTERM:-truecolor}"
fi

# Gradle wrapper 및 JVM 프로세스에서 restricted native access 경고를 없애기 위함
export JAVA_TOOL_OPTIONS="--enable-native-access=ALL-UNNAMED"

# 시크릿 (git 미포함 — ~/.zshrc_secrets에 별도 관리)
source ~/.zshrc_secrets 2>/dev/null || true
