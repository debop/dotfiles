#!/usr/bin/env bash
# PostToolUse hook: .kt 파일 편집 후 detekt 정적 분석
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

[[ "$FILE_PATH" == *.kt ]] || exit 0
[[ -f "$FILE_PATH" ]] || exit 0

# detekt가 없으면 조용히 종료
command -v detekt &>/dev/null || exit 0

RESULT=$(detekt --input "$FILE_PATH" --report txt:/dev/stdout 2>/dev/null || true)
if [[ -n "$RESULT" ]]; then
    echo "[detekt] $FILE_PATH"
    echo "$RESULT" | grep -E "warning|error" | head -20
fi
