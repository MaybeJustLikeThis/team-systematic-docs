#!/usr/bin/env bash
# 端到端流程测试: 跑通 lock -> PLAN -> BUILD(含 extend) -> CLOSE -> DONE -> scope 清空 整条链路。
# 这是对整个任务闭环系统的最终验证: 任意一环脚本/guardian 出 bug 都会在这里暴露。
cd "$(dirname "$0")/.."
source tests/test-helpers.sh
rm -rf .ai/task.json .ai/plan .ai/memory/draft/*
mkdir -p .ai/plan .ai/memory/draft

# guardian 辅助: 喂一段 PreToolUse JSON, 返回退出码(0 放行 / 2 阻断)
run_guard() { echo "$1" | bash .claude/hooks/guardian.sh >/dev/null 2>&1; echo $?; }
# 构造 Write 工具调用的 JSON
wf() { echo "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$1\"}}"; }

# 1. lock -> PLAN
bash .claude/scripts/task-lock.sh src/app/ >/dev/null
assert_eq "$(jq -r '.stage' .ai/task.json)" "PLAN" "e2e: PLAN"

# 2. PLAN 阶段写代码被拦
assert_eq "$(run_guard "$(wf src/app/x.go)")" "2" "e2e: PLAN 写代码拦"

# 3. 写前置知识 -> build --confirm -> BUILD
echo pre > .ai/memory/draft/MEM.md
bash .claude/scripts/task-build.sh --confirm >/dev/null
assert_eq "$(jq -r '.stage' .ai/task.json)" "BUILD" "e2e: BUILD"

# 4. 范围外拦 -> extend -> 放行
assert_eq "$(run_guard "$(wf src/other/y.go)")" "2" "e2e: 越界拦"
bash .claude/scripts/task-extend.sh src/other/ >/dev/null
assert_eq "$(run_guard "$(wf src/other/y.go)")" "0" "e2e: extend 后放行"

# 5. close --tested --reviewed -> CLOSE -> 写后置 -> close -> DONE + scope 清空
bash .claude/scripts/task-close.sh --tested --reviewed >/dev/null
assert_eq "$(jq -r '.stage' .ai/task.json)" "CLOSE" "e2e: CLOSE"
echo post > .ai/memory/draft/MEM-post.md
bash .claude/scripts/task-close.sh >/dev/null
assert_eq "$(jq -r '.stage' .ai/task.json)" "DONE" "e2e: DONE"
assert_eq "$(jq -rc '.scope.allowed_paths' .ai/task.json)" "[]" "e2e: scope 清空"

rm -f .ai/task.json; rm -rf .ai/plan; rm -f .ai/memory/draft/*
summary
