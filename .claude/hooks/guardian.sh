#!/usr/bin/env bash
set -uo pipefail
# no -e: 必须在 jq 失败后继续，靠 [-n] 空值检查兜底(fail-closed)
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
# 统一为正斜杠（防御 Windows 反斜杠路径绕过命门）
TARGET="${TARGET//\\//}"
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
source .claude/scripts/lib-state.sh

STAGE="$(state_get_stage "$TASK_FILE")"
ALLOWED="$(state_get_scope allowed_paths "$TASK_FILE")"
BLOCKED="$(state_get_scope blocked_paths "$TASK_FILE")"
EXTRA="$(state_get_scope extra_grants "$TASK_FILE")"

# 前缀匹配: 路径以任一前缀开头则命中（前缀来自 stdin，每行一个）
matches_prefix() {  # path
  local p="$1" pat
  while IFS= read -r pat; do
    [ -n "$pat" ] && [[ "$p" == "$pat"* ]] && return 0
  done
  return 1
}

# blocked 铁律: 全阶段生效
if printf '%s\n' "$BLOCKED" | matches_prefix "$REL"; then
  echo "GUARDIAN: $REL 在硬禁区(blocked)，不可修改，/extend 也放不了。" >&2
  exit 2
fi

case "$STAGE" in
  PLAN)
    printf '%s\n' '.ai/plan/' '.ai/memory/draft/' | matches_prefix "$REL" && exit 0
    echo "GUARDIAN: PLAN 阶段只能写方案(.ai/plan/)和知识候选(.ai/memory/draft/)。确认计划后用 /build 进入 BUILD。" >&2
    exit 2 ;;
  BUILD)
    { printf '%s\n' "$ALLOWED"; printf '%s\n' "$EXTRA"; } | matches_prefix "$REL" && exit 0
    echo "GUARDIAN: $REL 超出锁定范围。需要时用 /extend <path> 申请放行。" >&2
    exit 2 ;;
  CLOSE)
    echo '.ai/memory/draft/' | matches_prefix "$REL" && exit 0
    case "$REL" in *.md) exit 0 ;; esac
    echo "GUARDIAN: CLOSE 阶段已冻结实现代码，只能写知识候选和文档。要改代码先 /build 退回。" >&2
    exit 2 ;;
  DONE|*)
    echo "GUARDIAN: 任务已 DONE，无活动任务。新任务用 /lock。" >&2
    exit 2 ;;
esac
