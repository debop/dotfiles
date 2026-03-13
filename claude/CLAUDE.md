<!-- OMC:START -->
<!-- OMC:VERSION:4.7.10 -->

# oh-my-claudecode - Intelligent Multi-Agent Orchestration

You are running with oh-my-claudecode (OMC), a multi-agent orchestration layer for Claude Code.
Coordinate specialized agents, tools, and skills so work is completed accurately and efficiently.

<operating_principles>
- Delegate specialized work to the most appropriate agent.
- Prefer evidence over assumptions: verify outcomes before final claims.
- Choose the lightest-weight path that preserves quality.
- Consult official docs before implementing with SDKs/frameworks/APIs.
</operating_principles>

<delegation_rules>
Delegate for: multi-file changes, refactors, debugging, reviews, planning, research, verification.
Work directly for: trivial ops, small clarifications, single commands.
Route code to `executor` (use `model=opus` for complex work). Uncertain SDK usage → `document-specialist` (repo docs first; Context Hub / `chub` when available, graceful web fallback otherwise).
</delegation_rules>

<model_routing>
`haiku` (quick lookups), `sonnet` (standard), `opus` (architecture, deep analysis).
Direct writes OK for: `~/.claude/**`, `.omc/**`, `.claude/**`, `CLAUDE.md`, `AGENTS.md`.
</model_routing>

<agent_catalog>
Prefix: `oh-my-claudecode:`. See `agents/*.md` for full prompts.

explore (haiku), analyst (opus), planner (opus), architect (opus), debugger (sonnet), executor (sonnet), verifier (sonnet), security-reviewer (sonnet), code-reviewer (opus), test-engineer (sonnet), designer (sonnet), writer (haiku), qa-tester (sonnet), scientist (sonnet), document-specialist (sonnet), git-master (sonnet), code-simplifier (opus), critic (opus)
</agent_catalog>

<tools>
External AI: `/team N:executor "task"`, `omc team N:codex|gemini "..."`, `omc ask <claude|codex|gemini>`, `/ccg`
OMC State: `state_read`, `state_write`, `state_clear`, `state_list_active`, `state_get_status`
Teams: `TeamCreate`, `TeamDelete`, `SendMessage`, `TaskCreate`, `TaskList`, `TaskGet`, `TaskUpdate`
Notepad: `notepad_read`, `notepad_write_priority`, `notepad_write_working`, `notepad_write_manual`
Project Memory: `project_memory_read`, `project_memory_write`, `project_memory_add_note`, `project_memory_add_directive`
Code Intel: LSP (`lsp_hover`, `lsp_goto_definition`, `lsp_find_references`, `lsp_diagnostics`, etc.), AST (`ast_grep_search`, `ast_grep_replace`), `python_repl`
</tools>

<skills>
Invoke via `/oh-my-claudecode:<name>`. Trigger patterns auto-detect keywords.

Workflow: `autopilot`, `ralph`, `ultrawork`, `team`, `ccg`, `ultraqa`, `omc-plan`, `ralplan`, `sciomc`, `external-context`, `deepinit`, `deep-interview`, `ai-slop-cleaner`
Keyword triggers: "autopilot"→autopilot, "ralph"→ralph, "ulw"→ultrawork, "ccg"→ccg, "ralplan"→ralplan, "deep interview"→deep-interview, "deslop"/"anti-slop"/cleanup+slop-smell→ai-slop-cleaner, "deep-analyze"→analysis mode, "tdd"→TDD mode, "deepsearch"→codebase search, "ultrathink"→deep reasoning, "cancelomc"→cancel. Team orchestration is explicit via `/team`.
Utilities: `ask-codex`, `ask-gemini`, `cancel`, `note`, `learner`, `omc-setup`, `mcp-setup`, `hud`, `omc-doctor`, `omc-help`, `trace`, `release`, `project-session-manager`, `skill`, `writer-memory`, `ralph-init`, `configure-notifications`, `learn-about-omc`
</skills>

<team_pipeline>
Stages: `team-plan` → `team-prd` → `team-exec` → `team-verify` → `team-fix` (loop).
Fix loop bounded by max attempts. `team ralph` links both modes.
</team_pipeline>

<verification>
Verify before claiming completion. Size appropriately: small→haiku, standard→sonnet, large/security→opus.
If verification fails, keep iterating.
</verification>

<execution_protocols>
Broad requests: explore first, then plan. 2+ independent tasks in parallel. `run_in_background` for builds/tests.
Keep authoring and review as separate passes: writer pass creates or revises content, reviewer/verifier pass evaluates it later in a separate lane.
Never self-approve in the same active context; use `code-reviewer` or `verifier` for the approval pass.
Before concluding: zero pending tasks, tests passing, verifier evidence collected.
</execution_protocols>

<hooks_and_context>
Hooks inject `<system-reminder>` tags. Key patterns: `hook success: Success` (proceed), `[MAGIC KEYWORD: ...]` (invoke skill), `The boulder never stops` (ralph/ultrawork active).
Persistence: `<remember>` (7 days), `<remember priority>` (permanent).
Kill switches: `DISABLE_OMC`, `OMC_SKIP_HOOKS` (comma-separated).
</hooks_and_context>

<cancellation>
`/oh-my-claudecode:cancel` ends execution modes. Cancel when done+verified or blocked. Don't cancel if work incomplete.
</cancellation>

<worktree_paths>
State: `.omc/state/`, `.omc/state/sessions/{sessionId}/`, `.omc/notepad.md`, `.omc/project-memory.json`, `.omc/plans/`, `.omc/research/`, `.omc/logs/`
</worktree_paths>

## Setup

Say "setup omc" or run `/oh-my-claudecode:omc-setup`.
<!-- OMC:END -->

<!-- User customizations -->
@RTK.md

## CLI 도구 (Rust 기반 우선)

| 용도 | 명령 |
|------|------|
| 파일 탐색 | `fd -e kt -t f` |
| 텍스트 검색 | `rg "패턴" --type kotlin` |
| 파일 보기 | `bat src/Foo.kt` |
| 디렉토리 목록 | `eza -la --git` |
| 코드 구조/리팩토링 | `ast-grep -p 'fun $NAME($$$)' -l kotlin` |
| JSON/YAML | `jq`, `yq` |
| JSON greppable 변환 | `gron file.json \| rg "pattern"` |
| JSON 페이저 | `jless file.json` |
| 데이터 처리 (CSV/JSON) | `mlr --json filter '$k == "v"'` |
| GitHub | `gh` (비대화형: `--json`, `--yes`) |
| HTTP 클라이언트 | `xh GET https://api.example.com` |
| HTTP 테스트 자동화 | `hurl test.hurl` |
| HTTP 부하 테스트 | `oha -n 1000 https://api.example.com` |
| 코드 통계 | `tokei` |
| 디스크 사용량 | `dust` |
| 텍스트 치환 | `sd 'foo' 'bar' file.kt` |
| 시크릿 검사 | `gitleaks detect` |
| 커맨드 러너 | `just <recipe>` |
| SDK 버전 관리 | `mise use java@21` |
| Markdown 렌더링 | `glow README.md` |
| 명령어 참조 | `tldr <명령어>` |
| Python 린트 | `ruff check . && ruff format .` |

모든 외부 CLI: 비대화형 플래그(`--yes`, `--quiet`) + JSON 출력(`--json`) 강제.

## Kotlin Backend 환경

### MCP 서버
- `jetbrains` / `intellij-index` — IntelliJ IDE 직접 통합 (빌드·진단·코드탐색)
- `context7` — Kotlin/Spring/Exposed 라이브러리 실시간 문서
- `git` (`uvx mcp-server-git`) — git log·blame·diff 직접 분석
- `sequential-thinking` — 복잡한 아키텍처/쿼리 최적화 단계별 추론
- `filesystem`, `exa`, `playwright`, `github` — 파일·검색·브라우저·PR

### Hooks
- **PostToolUse** `.kt` 편집 → `ktlint --format` 자동 정리 + lint 검사 (`~/.claude/hooks/kotlin-ktlint.sh`)
- **PostToolUse** `.kt` 편집 → `detekt` 정적 분석 (`~/.claude/hooks/kotlin-detekt.sh`)
- **PreToolUse** `.env`·`*.properties` 민감 파일 편집 차단 (`~/.claude/hooks/block-sensitive-files.sh`)

### MCP 서버
- `jetbrains` / `intellij-index` — IntelliJ IDE 직접 통합 (빌드·진단·코드탐색)
- `context7` — Kotlin/Spring/Exposed 라이브러리 실시간 문서
- `git` (`uvx mcp-server-git`) — git log·blame·diff 직접 분석
- `sequential-thinking` — 복잡한 아키텍처/쿼리 최적화 단계별 추론
- `filesystem`, `exa`, `playwright`, `github` — 파일·검색·브라우저·PR

### 스킬
| 스킬 | 용도 |
|------|------|
| `/kotlin-specialist` | Kotlin 고급 패턴 (Flow, Sealed, DSL) |
| `/coroutines-kotlin` | Coroutines/Flow/Channel |
| `/kotlin-spring` | Spring Boot + Kotlin 통합 |
| `/backend-implementation` | 백엔드 개발 워크플로우 |
| `/senior-architect` | 아키텍처 설계 & 트레이드오프 분석 |
| `/kotest` | Kotest + MockK + Spring Boot Test 패턴 |