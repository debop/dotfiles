#!/usr/bin/env bash
# PostToolUse hook: .kt 파일 편집 후 ktlint 자동 검사
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

[[ "$FILE_PATH" == *.kt ]] || exit 0
[[ -f "$FILE_PATH" ]] || exit 0

ktlint --format "$FILE_PATH" 2>/dev/null || true

RESULT=$(ktlint "$FILE_PATH" 2>&1 || true)
if [[ -n "$RESULT" ]]; then
    echo "[ktlint] $FILE_PATH"
    echo "$RESULT" | head -20
fi
