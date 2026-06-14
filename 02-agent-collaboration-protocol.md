# 02. A2A Agent 协作协议

## 目标

A2A 是 Agent-to-Agent 协作协议。它定义不同 Agent 之间如何交接任务、引用上下文、传递工件、声明权限和生成可审计输出。

企业级协作中，Agent 之间不能只传自然语言。必须传结构化任务信封。

## 协议对象

### Task Packet

任务的标准载体。

### Artifact

任务过程中产生或引用的工件，如 issue、diff、测试报告、设计文档、PR、日志、截图。

### Memory Ref

团队知识引用，如 `MEM-ARCH-001@v2`。

### Trace

一次 AI 行为或多 Agent 链路的审计记录。

## 标准 Task Packet

```json
{
  "protocol_version": "a2a.v1",
  "trace_id": "TRACE-20260614-0001",
  "task_id": "TASK-0001",
  "parent_task_id": null,
  "created_at": "2026-06-14T10:00:00Z",
  "human_owner": "team-lead",
  "from": {
    "agent_id": "agent.planner.v1",
    "role": "planner"
  },
  "to": {
    "agent_id": "agent.builder.v1",
    "role": "builder"
  },
  "intent": "implement_change",
  "risk_level": "medium",
  "scope": {
    "repo": "example-service",
    "branch": "feature/example",
    "allowed_paths": [
      "src/example/**",
      "tests/example/**"
    ],
    "blocked_paths": [
      "infra/prod/**",
      "secrets/**"
    ]
  },
  "context_refs": [
    "MEM-ARCH-001@v1",
    "MEM-STYLE-001@v1"
  ],
  "artifact_refs": [
    "ISSUE-123",
    "DESIGN-456"
  ],
  "objective": "实现指定功能并补充测试",
  "non_goals": [
    "不修改数据库 schema",
    "不重构无关模块"
  ],
  "constraints": [
    "遵循现有模块边界",
    "新增行为必须有测试"
  ],
  "acceptance_criteria": [
    "核心路径测试通过",
    "错误路径测试通过",
    "PR 描述包含 Memory Impact"
  ],
  "expected_output": {
    "format": "implementation_report",
    "required_sections": [
      "summary",
      "files_changed",
      "tests",
      "risks",
      "memory_impact"
    ]
  }
}
```

## Agent 输出标准

每个 Agent 的输出必须包含：

```json
{
  "trace_id": "TRACE-20260614-0001",
  "task_id": "TASK-0001",
  "agent_id": "agent.builder.v1",
  "status": "completed",
  "summary": "完成实现并补充测试",
  "artifact_refs_created": [
    "DIFF-789",
    "TEST-REPORT-101"
  ],
  "memory_refs_used": [
    "MEM-ARCH-001@v1",
    "MEM-STYLE-001@v1"
  ],
  "memory_candidates": [
    {
      "type": "pitfall",
      "summary": "该模块的缓存键必须包含租户 ID"
    }
  ],
  "risks": [
    {
      "level": "medium",
      "description": "旧客户端可能依赖默认字段",
      "mitigation": "保留向后兼容默认值"
    }
  ],
  "next_recommended_agent": "agent.reviewer.v1"
}
```

## 协作链路

### 标准开发链

```text
Planner
-> Builder
-> Tester
-> Reviewer
-> Security
-> Doc
-> Human Owner
```

### 快速低风险链

```text
Builder
-> Tester
-> Reviewer
-> Human Owner
```

### 高风险链

```text
Planner
-> Security
-> Human Owner
-> Builder
-> Tester
-> Reviewer
-> Security
-> Release Owner
```

## 失败处理

Agent 不能沉默失败。失败输出必须包含：

```json
{
  "status": "blocked",
  "blocking_reason": "缺少接口契约文档",
  "missing_inputs": [
    "MEM-CONTRACT-*",
    "API response examples"
  ],
  "safe_next_steps": [
    "请求 human owner 补充接口契约",
    "先生成测试计划，不修改代码"
  ]
}
```

## 协议规则

1. 没有 `trace_id` 的 Agent 输出不得进入 PR。
2. 没有 `human_owner` 的任务不得进入高风险路径。
3. Agent 不得访问 scope 之外的文件。
4. Agent 不得引用 deprecated Memory 作为当前依据。
5. Builder Agent 不得批准自己的输出。
6. Security Agent 对 high risk 任务拥有阻断权。
7. Doc Agent 可以提出 Memory 候选，但不能激活策略类 Memory。

