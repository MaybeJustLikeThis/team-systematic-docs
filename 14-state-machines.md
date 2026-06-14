# 14. 状态机

## 目标

真实平台不能只靠流程图。每个核心对象都需要状态、迁移条件、阻断条件和责任人。

## Task 状态机

```text
draft
-> ready
-> in_progress
-> in_review
-> approved
-> merged
-> released
-> verified
-> closed

任意状态 -> blocked
任意状态 -> cancelled
released -> incident_linked
```

### 迁移规则

| From | To | 条件 |
|---|---|---|
| draft | ready | human_owner、risk_level、acceptance_criteria 已填写 |
| ready | in_progress | Task Packet 创建，Policy Decision 允许 |
| in_progress | in_review | Builder Output 完成，测试证据存在 |
| in_review | approved | Reviewer / Security / Human Owner 满足要求 |
| approved | merged | CI 通过，无 blocking finding |
| merged | released | Release Owner 批准 |
| released | verified | 发布后指标满足验证条件 |
| verified | closed | Memory Impact 已处理 |

## Approval 状态机

```text
requested
-> approved
-> rejected
-> expired
-> overridden
```

规则：

- high risk 审批必须有理由。
- approval 必须绑定 human identity。
- approval 必须有有效期。
- override 必须记录 break-glass reason。

## Memory 状态机

```text
candidate
-> draft
-> active
-> deprecated
-> archived

active -> conflicted
conflicted -> active
conflicted -> deprecated
```

规则：

- candidate 可由 Agent 提出。
- draft 必须有人类 owner。
- active 必须经过 reviewer。
- deprecated 必须声明替代项或过期原因。
- conflicted 不得作为自动决策依据。

## Hook 状态机

```text
draft
-> shadow
-> advisory
-> blocking
-> deprecated
```

### 阶段含义

- `shadow`：只记录结果，不影响流程。
- `advisory`：给建议，不阻断。
- `blocking`：可阻断流程。

规则：

- 新 Hook 默认先进入 shadow。
- shadow 观察期后才能进入 advisory。
- blocking Hook 必须有 owner、误报处理、override 策略。

## Agent Run 状态机

```text
queued
-> running
-> completed
-> failed
-> blocked
-> cancelled
```

规则：

- failed 必须有 error_type。
- blocked 必须有 missing_inputs。
- completed 必须有 output_hash。

## Incident 状态机

```text
detected
-> triaged
-> mitigated
-> resolved
-> reviewed
-> memory_updated
-> closed
```

规则：

- 如果事故涉及 AI，必须绑定 trace_id。
- reviewed 后必须判断是否新增 Memory 或 Hook。
- memory_updated 后才能 closed。

## Trace 状态机

```text
open
-> completed
-> sealed
-> archived
```

规则：

- completed 表示任务结束。
- sealed 表示审计记录不可再修改，只能追加补充事件。
- archived 按保留策略归档。

