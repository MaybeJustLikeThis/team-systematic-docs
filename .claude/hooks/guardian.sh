#!/usr/bin/env bash
set -uo pipefail
# PreToolUse 守卫。读 stdin JSON，按 task.json 的 stage + scope 拦截写类工具。
# 退出码: 0 放行, 2 阻断(stderr 反馈给 AI)。

TASK_FILE=".ai/task.json"

# 无任务 -> 拦所有写
if [ ! -f "$TASK_FILE" ]; then
  echo "GUARDIAN: 无活动任务，先用 /lock 锁定范围后再写文件。" >&2
  exit 2
fi

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"
# fail-closed: 解析不出工具名，阻断
[ -n "$TOOL_NAME" ] || { echo "GUARDIAN: 无法解析工具调用(fail-closed)" >&2; exit 2; }

# 只拦截写类工具，其余放行
case "$TOOL_NAME" in
  Write|Edit|NotebookEdit) ;;
  Bash)  exit 0 ;;   # Bash 弱约束在 Task 6 接入
  *)     exit 0 ;;
esac

# 目标路径（Write/Edit 用 file_path，Notebook 用 notebook_path）
TARGET="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')"
# fail-closed: 写类工具但读不到目标路径，阻断
[ -n "$TARGET" ] || { echo "GUARDIAN: 无法解析写入目标(fail-closed)" >&2; exit 2; }
# 绝对路径 -> 相对项目根
REL="${TARGET#"$PWD"/}"
REL="${REL:-$TARGET}"

# 命门：task.json 对 AI 永远只读
case "$REL" in
  .ai/task.json|*/task.json)
    echo "GUARDIAN: .ai/task.json 是系统状态文件，AI 不可修改。" >&2
    exit 2 ;;
esac

# Task 4 在此插入 stage 分支（PLAN/BUILD/CLOSE 白名单 + blocked）
exit 0
