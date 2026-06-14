# 13. 接口契约

## 目标

定义 A2A、Hook、Memory、Audit、Policy 等对象的统一字段和机器可读契约。

## 命名规范

统一字段：

```text
trace_id
task_id
agent_id
human_owner
risk_level
data_classification
memory_refs
artifact_refs
policy_decision_id
approval_id
created_at
updated_at
```

避免同一语义出现多个名字。例如：

- 使用 `memory_refs`，不再混用 `context_refs`、`memory_refs_used`。
- 使用 `artifact_refs`，不再混用 `artifact_refs_created`。

## Task Packet v1

```json
{
  "schema_version": "task_packet.v1",
  "trace_id": "TRACE-20260614-0001",
  "task_id": "TASK-0001",
  "human_owner": "alice",
  "intent": "implement_change",
  "risk_level": "medium",
  "data_classification": "internal",
  "scope": {
    "repo": "example-service",
    "branch": "feature/example",
    "allowed_paths": [],
    "blocked_paths": []
  },
  "memory_refs": [],
  "artifact_refs": [],
  "objective": "",
  "non_goals": [],
  "constraints": [],
  "acceptance_criteria": [],
  "required_approvals": [],
  "tool_scopes": [],
  "model_policy": {
    "approved_model_tier": "internal_allowed",
    "external_model_allowed": false
  }
}
```

## Agent Output v1

```json
{
  "schema_version": "agent_output.v1",
  "trace_id": "TRACE-20260614-0001",
  "task_id": "TASK-0001",
  "agent_id": "agent.reviewer.v1",
  "agent_run_id": "RUN-0001",
  "status": "completed",
  "summary": "",
  "artifact_refs": [],
  "memory_refs": [],
  "findings": [],
  "risks": [],
  "memory_candidates": [],
  "next_recommended_agent": null
}
```

## Hook Config v1

```yaml
schema_version: hook_config.v1
hook_id: hook.pr.high-risk-review
event: pr.opened
mode: approval
owner: platform-team
description: ""
condition:
  paths_include: []
  paths_exclude: []
  risk_levels: []
  data_classifications: []
actions:
  - type: load_memory
    refs: []
  - type: run_agent
    agent_id: agent.security.v1
  - type: require_human_approval
    roles: []
failure_policy: fail_closed
timeout_seconds: 120
audit: true
```

## Hook Output v1

```json
{
  "schema_version": "hook_output.v1",
  "hook_id": "hook.pr.high-risk-review",
  "event": "pr.opened",
  "trace_id": "TRACE-20260614-0001",
  "status": "requires_approval",
  "risk_level": "high",
  "policy_decision_id": "POLICY-DECISION-0001",
  "findings": [],
  "required_actions": [],
  "override_allowed": false
}
```

## Memory Manifest v1

```yaml
schema_version: memory.v1
memory_id: MEM-ARCH-001
version: 1
status: active
owner: platform-team
scope: org/backend
classification: internal
source_trust: verified
created_at: 2026-06-14
updated_at: 2026-06-14
expires_at: 2026-12-31
supersedes: []
conflicts_with: []
reviewers: []
```

## Policy Decision v1

```json
{
  "schema_version": "policy_decision.v1",
  "policy_decision_id": "POLICY-DECISION-0001",
  "trace_id": "TRACE-20260614-0001",
  "task_id": "TASK-0001",
  "decision": "require_approval",
  "reasons": [],
  "required_approvals": [],
  "allowed_tools": [],
  "allowed_models": [],
  "data_handling": {
    "redaction_required": true,
    "external_model_allowed": false,
    "retention_policy": "standard_90d"
  }
}
```

## Audit Event v1

```json
{
  "schema_version": "audit_event.v1",
  "trace_id": "TRACE-20260614-0001",
  "timestamp": "2026-06-14T10:00:00Z",
  "event_type": "agent.run.completed",
  "actor": {
    "type": "agent",
    "id": "agent.reviewer.v1"
  },
  "human_initiator": "alice",
  "human_owner": "bob",
  "task_id": "TASK-0001",
  "agent_run_id": "RUN-0001",
  "model": {
    "provider": "approved-provider",
    "model_id": "approved-model",
    "version": "2026-06"
  },
  "memory_refs": [],
  "artifact_refs": [],
  "tool_calls": [],
  "policy_decision_id": "POLICY-DECISION-0001",
  "input_hash": "sha256:...",
  "output_hash": "sha256:..."
}
```

