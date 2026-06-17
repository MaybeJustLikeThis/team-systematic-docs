#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/test-helpers.sh
rm -f .ai/task.json

# lock 两个路径
bash .claude/scripts/task-lock.sh src/pay/refund/ src/util/
assert_eq "$?" "0" "lock 成功退出"
assert_eq "$(jq -r '.stage' .ai/task.json)" "PLAN" "lock 后 stage=PLAN"
assert_match "src/pay/refund/" "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "allowed 含 refund"
assert_match "src/util/" "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "allowed 含 util"
assert_match "TASK-" "$(jq -r '.task_id' .ai/task.json)" "生成 task_id"

# 尾斜杠规范化：传入不带斜杠的路径，应规范化为带斜杠
rm -f .ai/task.json
bash .claude/scripts/task-lock.sh src/pay/refund
assert_match '"src/pay/refund/"' "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "无尾斜杠路径被规范化为带斜杠"

# 反斜杠路径规范化（Windows）
rm -f .ai/task.json
bash .claude/scripts/task-lock.sh 'src\pay\refund'
assert_match '"src/pay/refund/"' "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "反斜杠路径被规范化"

rm -f .ai/task.json
summary
