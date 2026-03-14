# Codex Dotfiles

이 디렉터리는 Codex / oh-my-codex 공유 설정의 source of truth 다.

포함 대상:
- `AGENTS.md`
- `prompts/`
- `rules/`
- `skills/`
- `../agents/skills/`
- `../omx/agents/`

로컬 전용 파일은 저장소에 포함하지 않는다.
- `auth.json`
- `history.jsonl`
- `archived_sessions/`
- `log/`
- `sqlite/`
- 각종 캐시와 state 파일

설치 및 갱신:
- `bash ~/dotfiles/setup.sh`
- 수동 동기화: `codex-sync`
- 자동 동기화: 셸에서 `codex ...` 실행 직전에 `bin/sync-codex.sh --quiet` 가 먼저 실행된다.
- 실행 전 preflight hook: `bin/codex-preflight.sh`
- launchd 감시: `bin/codex-sync-watch.sh`

기본 추천 구성:
- Skills: `openai-docs`, `playwright`, `gh-fix-ci`
- Agents: `architect`, `executor`, `verifier`, `debugger`, `code-reviewer`, `test-engineer`
- MCP: `git`, `filesystem`, `context7`, `playwright`, `intellij`, `intellij-index`, `notion`

환경 변수로 오버라이드 가능:
- `DOTFILES_DIR`
- `CODEX_INTELLIJ_APP`
- `CODEX_IJ_MCP_SERVER_PORT`
- `CODEX_INTELLIJ_INDEX_URL`
- `HOMEBREW_PREFIX`
