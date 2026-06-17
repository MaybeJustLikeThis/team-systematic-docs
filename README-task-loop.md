# Task Loop —— 单任务闭环系统

一次 AI 开发任务的三拍节奏：**PLAN → BUILD → CLOSE**，人发车，hook 守门。

## 快速开始
1. `/lock src/your/module/`           锁定范围，进入 PLAN
2. 写方案到 `.ai/plan/`，前置知识到 `.ai/memory/draft/`
3. `/build --confirm`                 过 gate，进入 BUILD
4. 在范围内写代码；越界时 `/extend <path>` 申请放行
5. `/close --tested --reviewed`       进入 CLOSE
6. 后置知识写到 `.ai/memory/draft/`，再 `/close` 收尾
7. 审查 `draft/`，值得保留的激活到 `memory/active/`

## 它防住什么
- 范围越界：guardian 硬拦 allowed 外的写入
- 自我放行：`.ai/task.json` 对 AI 只读，AI 改不了自己的状态
- 跳过计划：BUILD 必须 PLAN 末有前置知识 + 人确认
- 经验蒸发：收尾强制写后置知识才能 DONE

## 命中硬禁区(blocked)怎么办
不能放行。这是铁律。如 `src/auth/`、`infra/prod/` 这类，`/extend` 也拒绝。

## 依赖
- jq（JSON 处理，Windows 用 scoop/winget 装）
- Git Bash（Windows）

## 设计文档
- spec: `docs/superpowers/specs/2026-06-17-task-loop-design.md`
- plan: `docs/superpowers/plans/2026-06-17-task-loop.md`
- 知识格式: `03-memory-ledger.md`
