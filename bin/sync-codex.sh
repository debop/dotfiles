#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

QUIET=0
if [[ "${1:-}" == "--quiet" ]]; then
  QUIET=1
fi

log() {
  if [[ "$QUIET" -eq 0 ]]; then
    echo "$@"
  fi
}

find_intellij_app() {
  local candidates=(
    "${CODEX_INTELLIJ_APP:-}"
    "$HOME/Applications/IntelliJ IDEA.app"
    "/Applications/IntelliJ IDEA.app"
    "$HOME/Applications/IntelliJ IDEA Ultimate.app"
    "/Applications/IntelliJ IDEA Ultimate.app"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    [[ -n "$candidate" && -d "$candidate" ]] && {
      printf '%s\n' "$candidate"
      return 0
    }
  done

  return 1
}

render_codex_config() {
  local output_file="$1"
  local brew_prefix intellij_app intellij_java ij_port ij_index_url ij_classpath

  brew_prefix="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null || printf '/opt/homebrew')}"
  ij_port="${CODEX_IJ_MCP_SERVER_PORT:-64342}"
  ij_index_url="${CODEX_INTELLIJ_INDEX_URL:-http://127.0.0.1:29170/index-mcp/sse}"

  cat > "$output_file" <<EOF
# Shared Codex configuration managed by dotfiles/bin/sync-codex.sh
notify = ["node", "${brew_prefix}/lib/node_modules/oh-my-codex/scripts/notify-hook.js"]
model_reasoning_effort = "medium"
developer_instructions = "You have oh-my-codex installed. Use /prompts:architect, /prompts:executor, /prompts:planner for specialized agent roles. Workflow skills via \$name: \$ralph, \$autopilot, \$plan. AGENTS.md is your orchestration brain."

model_context_window = 1000000
model_auto_compact_token_limit = 900000

model = "gpt-5.4"
[projects."${HOME}"]
trust_level = "trusted"

[projects."${HOME}/work/bluetape4k/bluetape4k-projects"]
trust_level = "trusted"

[projects."${HOME}/work/bluetape4k/exposed-workshop"]
trust_level = "trusted"

[projects."${HOME}/work/bluetape4k/bluetape4k-experimental"]
trust_level = "trusted"

[notice.model_migrations]
"gpt-5.2-codex" = "gpt-5.3-codex"
"gpt-5.3-codex" = "gpt-5.4"

[features]
multi_agent = true
apps = true
child_agents_md = true

[mcp_servers.omx_state]
command = "node"
args = ["${brew_prefix}/lib/node_modules/oh-my-codex/dist/mcp/state-server.js"]
startup_timeout_sec = 5.0

[mcp_servers.omx_memory]
command = "node"
args = ["${brew_prefix}/lib/node_modules/oh-my-codex/dist/mcp/memory-server.js"]
startup_timeout_sec = 5.0

[mcp_servers.omx_code_intel]
command = "node"
args = ["${brew_prefix}/lib/node_modules/oh-my-codex/dist/mcp/code-intel-server.js"]
startup_timeout_sec = 10.0

[mcp_servers.omx_trace]
command = "node"
args = ["${brew_prefix}/lib/node_modules/oh-my-codex/dist/mcp/trace-server.js"]
startup_timeout_sec = 5.0

[mcp_servers.omx_team_run]
command = "node"
args = ["${brew_prefix}/lib/node_modules/oh-my-codex/dist/mcp/team-server.js"]
startup_timeout_sec = 5.0

[mcp_servers.notion]
url = "https://mcp.notion.com/mcp"

[mcp_servers.playwright]
command = "npx"
args = ["@playwright/mcp@latest"]

[mcp_servers.git]
command = "uvx"
args = ["mcp-server-git"]
startup_timeout_sec = 10.0

[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
startup_timeout_sec = 10.0

[mcp_servers.filesystem]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "${HOME}", "${HOME}/work"]
startup_timeout_sec = 10.0
EOF

  if intellij_app="$(find_intellij_app)"; then
    intellij_java="${intellij_app}/Contents/jbr/Contents/Home/bin/java"
    ij_classpath="${intellij_app}/Contents/plugins/mcpserver/lib/mcpserver-frontend.jar:${intellij_app}/Contents/lib/util-8.jar:${intellij_app}/Contents/lib/module-intellij.libraries.ktor.client.cio.jar:${intellij_app}/Contents/lib/module-intellij.libraries.ktor.client.jar:${intellij_app}/Contents/lib/module-intellij.libraries.ktor.network.tls.jar:${intellij_app}/Contents/lib/module-intellij.libraries.ktor.io.jar:${intellij_app}/Contents/lib/module-intellij.libraries.ktor.utils.jar:${intellij_app}/Contents/lib/module-intellij.libraries.kotlinx.io.jar:${intellij_app}/Contents/lib/module-intellij.libraries.kotlinx.serialization.core.jar:${intellij_app}/Contents/lib/module-intellij.libraries.kotlinx.serialization.json.jar"

    cat >> "$output_file" <<EOF

[mcp_servers.intellij]
command = "${intellij_java}"
args = ["-classpath", "${ij_classpath}", "com.intellij.mcpserver.stdio.McpStdioRunnerKt"]
env = { IJ_MCP_SERVER_PORT = "${ij_port}" }
EOF
  fi

  cat >> "$output_file" <<EOF

[mcp_servers.intellij-index]
command = "npx"
args = ["-y", "mcp-remote", "${ij_index_url}", "--allow-http"]

# OMX Native Agent Roles (Codex multi-agent)

[agents.explore]
description = "Fast codebase search and file/symbol mapping"
config_file = "${HOME}/.omx/agents/explore.toml"

[agents.analyst]
description = "Requirements clarity, acceptance criteria, hidden constraints"
config_file = "${HOME}/.omx/agents/analyst.toml"

[agents.planner]
description = "Task sequencing, execution plans, risk flags"
config_file = "${HOME}/.omx/agents/planner.toml"

[agents.architect]
description = "System design, boundaries, interfaces, long-horizon tradeoffs"
config_file = "${HOME}/.omx/agents/architect.toml"

[agents.debugger]
description = "Root-cause analysis, regression isolation, failure diagnosis"
config_file = "${HOME}/.omx/agents/debugger.toml"

[agents.executor]
description = "Code implementation, refactoring, feature work"
config_file = "${HOME}/.omx/agents/executor.toml"

[agents.verifier]
description = "Completion evidence, claim validation, test adequacy"
config_file = "${HOME}/.omx/agents/verifier.toml"

[agents."style-reviewer"]
description = "Formatting, naming, idioms, lint conventions"
config_file = "${HOME}/.omx/agents/style-reviewer.toml"

[agents."quality-reviewer"]
description = "Logic defects, maintainability, anti-patterns"
config_file = "${HOME}/.omx/agents/quality-reviewer.toml"

[agents."api-reviewer"]
description = "API contracts, versioning, backward compatibility"
config_file = "${HOME}/.omx/agents/api-reviewer.toml"

[agents."security-reviewer"]
description = "Vulnerabilities, trust boundaries, authn/authz"
config_file = "${HOME}/.omx/agents/security-reviewer.toml"

[agents."performance-reviewer"]
description = "Hotspots, complexity, memory/latency optimization"
config_file = "${HOME}/.omx/agents/performance-reviewer.toml"

[agents."code-reviewer"]
description = "Comprehensive review across all concerns"
config_file = "${HOME}/.omx/agents/code-reviewer.toml"

[agents."dependency-expert"]
description = "External SDK/API/package evaluation"
config_file = "${HOME}/.omx/agents/dependency-expert.toml"

[agents."test-engineer"]
description = "Test strategy, coverage, flaky-test hardening"
config_file = "${HOME}/.omx/agents/test-engineer.toml"

[agents."quality-strategist"]
description = "Quality strategy, release readiness, risk assessment"
config_file = "${HOME}/.omx/agents/quality-strategist.toml"

[agents."build-fixer"]
description = "Build/toolchain/type failures resolution"
config_file = "${HOME}/.omx/agents/build-fixer.toml"

[agents.designer]
description = "UX/UI architecture, interaction design"
config_file = "${HOME}/.omx/agents/designer.toml"

[agents.writer]
description = "Documentation, migration notes, user guidance"
config_file = "${HOME}/.omx/agents/writer.toml"

[agents."qa-tester"]
description = "Interactive CLI/service runtime validation"
config_file = "${HOME}/.omx/agents/qa-tester.toml"

[agents."git-master"]
description = "Commit strategy, history hygiene, rebasing"
config_file = "${HOME}/.omx/agents/git-master.toml"

[agents."code-simplifier"]
description = "Simplifies recently modified code for clarity and consistency without changing behavior"
config_file = "${HOME}/.omx/agents/code-simplifier.toml"

[agents.researcher]
description = "External documentation and reference research"
config_file = "${HOME}/.omx/agents/researcher.toml"

[agents."product-manager"]
description = "Problem framing, personas/JTBD, PRDs"
config_file = "${HOME}/.omx/agents/product-manager.toml"

[agents."ux-researcher"]
description = "Heuristic audits, usability, accessibility"
config_file = "${HOME}/.omx/agents/ux-researcher.toml"

[agents."information-architect"]
description = "Taxonomy, navigation, findability"
config_file = "${HOME}/.omx/agents/information-architect.toml"

[agents."product-analyst"]
description = "Product metrics, funnel analysis, experiments"
config_file = "${HOME}/.omx/agents/product-analyst.toml"

[agents.critic]
description = "Plan/design critical challenge and review"
config_file = "${HOME}/.omx/agents/critic.toml"

[agents.vision]
description = "Image/screenshot/diagram analysis"
config_file = "${HOME}/.omx/agents/vision.toml"

# OMX TUI StatusLine (Codex CLI v0.101.0+)
[tui]
status_line = ["model-with-reasoning", "git-branch", "context-remaining", "total-input-tokens", "total-output-tokens", "five-hour-limit"]
EOF
}

sync_dir() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  rsync -a --delete "$src/" "$dst/"
}

main() {
  local codex_dir="$HOME/.codex"
  local agents_dir="$HOME/.agents"
  local omx_agents_dir="$HOME/.omx/agents"
  local tmp_config

  mkdir -p "$codex_dir" "$agents_dir" "$omx_agents_dir"

  install -m 0644 "$DOTFILES_DIR/codex/AGENTS.md" "$codex_dir/AGENTS.md"
  sync_dir "$DOTFILES_DIR/codex/prompts" "$codex_dir/prompts"
  sync_dir "$DOTFILES_DIR/codex/rules" "$codex_dir/rules"
  sync_dir "$DOTFILES_DIR/codex/skills" "$codex_dir/skills"
  sync_dir "$DOTFILES_DIR/agents/skills" "$agents_dir/skills"
  sync_dir "$DOTFILES_DIR/omx/agents" "$omx_agents_dir"

  tmp_config="$(mktemp "${TMPDIR:-/tmp}/codex-config.XXXXXX")"
  render_codex_config "$tmp_config"
  install -m 0644 "$tmp_config" "$codex_dir/config.toml"
  rm -f "$tmp_config"

  log "Codex sync complete"
}

main "$@"
