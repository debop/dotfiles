#!/usr/bin/env bash
# PreToolUse hook: 민감한 파일 편집 차단
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

[[ -n "$FILE_PATH" ]] || exit 0

SENSITIVE_PATTERNS=(".env" "local.properties" "secrets.properties" ".aws/credentials" "serviceAccountKey.json")

for PATTERN in "${SENSITIVE_PATTERNS[@]}"; do
    if [[ "$FILE_PATH" == *"$PATTERN"* ]]; then
        echo '{"decision":"block","reason":"민감한 파일 편집이 차단되었습니다: '"$FILE_PATH"'\n이 파일을 수정하려면 수동으로 편집하세요."}'
        exit 0
    fi
done
