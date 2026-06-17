#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/test-helpers.sh
GUARD=".claude/hooks/guardian.sh"

# 工具：构造 PreToolUse stdin 并跑 guardian，返回退出码
run_guard() {  # tool_name file_path  -> 退出码
  local payload; payload=$(jq -nc --arg t "$1" --arg p "$2" \
    '{tool_name:$t, tool_input:{file_path:$p}}')
  echo "$payload" | bash "$GUARD" >/dev/null 2>&1; echo $?
}

# 1. 无 task.json -> 拦所有写
rm -f .ai/task.json
assert_eq "$(run_guard Write src/any.go)" "2" "无任务时拦写"

# 2. 有 task.json，但写 task.json 自身 -> 命门，拦
cp tests/fixtures/task-plan.json .ai/task.json
assert_eq "$(run_guard Write .ai/task.json)" "2" "命门:写 task.json 被拦"
assert_eq "$(run_guard Write /abs/.ai/task.json)" "2" "命门:绝对路径写 task.json 被拦"

rm -f .ai/task.json
summary
