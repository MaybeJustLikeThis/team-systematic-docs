# 08. 模板集合

## AGENTS.md 模板

```md
# AGENTS.md

## Project Rules

- 修改前先阅读相关代码和 Memory。
- 遵循现有目录结构和命名风格。
- 不做无关重构。
- 新功能必须补测试。
- 修 bug 必须补回归测试或说明为什么无法测试。
- 不确定时列出假设，不要伪装确定。
- 不允许读取或输出密钥、客户隐私数据、生产敏感数据。

## Risk Zones

High risk paths:

- auth/
- payment/
- billing/
- privacy/
- infra/prod/
- secrets/

High risk changes require human owner approval.

## Required Output

Every AI-assisted change must include:

- Summary
- Tests
- Risks
- Memory Used
- Memory Impact
- Human Owner
```

## Issue 模板

```md
## Background

## Goal

## Non-goals

## User / Business Impact

## Acceptance Criteria

## Risk Level
- [ ] Low
- [ ] Medium
- [ ] High

## Related Memory

## Suggested Agent Flow
- [ ] Planner
- [ ] Builder
- [ ] Tester
- [ ] Reviewer
- [ ] Security

## Human Owner
```

## PR 模板（治理版）

下面是中后期治理版 PR 模板。试点阶段可先使用 `19-pilot-and-scale-proposal.md` 中的轻量版 AI Usage 模板，避免一开始增加过多填写负担。

```md
## Summary

## Risk Level
- [ ] Low
- [ ] Medium
- [ ] High

## Data Classification
- [ ] Public
- [ ] Internal
- [ ] Confidential
- [ ] Restricted

## Red Zone
- [ ] No red zone touched
- [ ] Red zone read
- [ ] Red zone write
- [ ] Red zone execute

## AI Trace
- Trace ID:
- Agents used:
- Approved model:
- Tool scopes:

## Memory Used
- 

## Memory Impact
Proposed:
- 

Changed:
- 

Deprecated:
- 

## Tests
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual verification
- [ ] Not applicable, reason:

## Security / Privacy
- [ ] No sensitive data touched
- [ ] Sensitive data touched and reviewed
- [ ] Security owner approval required
- [ ] Logs / screenshots are redacted
- [ ] No secrets or credentials included

## Policy / Approval
- Policy decision:
- Approval ticket:
- Retention policy:

## Rollback Plan

## Human Approval
- Owner:
- Reviewer:
```

## Memory 模板

```md
# MEM-TYPE-000: Title

version: 1
status: draft
owner:
scope:
classification: internal
created_at:
updated_at:
expires_at:
supersedes: []
conflicts_with: []

## Rule / Knowledge

## Reason

## Applies To

## Exceptions

## AI Usage

## Verification

## References
```

## Hook 模板

```yaml
hook_id: hook.event.name
event: pr.opened
mode: advisory
owner: platform-team
description: ""

condition:
  paths_include: []
  paths_exclude: []
  risk_levels: []

actions:
  - load_memory:
      refs: []
  - run_agent:
      agent_id: "agent.reviewer.v1"
      output: "review_report"

timeout_seconds: 120
audit: true
```

## Task Packet 模板

```json
{
  "protocol_version": "a2a.v1",
  "trace_id": "",
  "task_id": "",
  "parent_task_id": null,
  "human_owner": "",
  "from": {
    "agent_id": "",
    "role": ""
  },
  "to": {
    "agent_id": "",
    "role": ""
  },
  "intent": "",
  "risk_level": "low",
  "data_classification": "internal",
  "scope": {
    "repo": "",
    "branch": "",
    "allowed_paths": [],
    "blocked_paths": []
  },
  "context_refs": [],
  "artifact_refs": [],
  "tool_scopes": [],
  "model_policy": {
    "approved_model_tier": "",
    "external_model_allowed": false
  },
  "approval_ticket": "",
  "retention_policy": "",
  "objective": "",
  "non_goals": [],
  "constraints": [],
  "acceptance_criteria": [],
  "expected_output": {
    "format": "",
    "required_sections": []
  }
}
```

## AI Review 输出模板

```md
## Findings

### P0 / Blocking

### P1 / High

### P2 / Medium

### P3 / Low

## Test Gaps

## Policy / Memory Violations

## Open Questions

## Recommendation
- [ ] Approve
- [ ] Request changes
- [ ] Block pending owner decision
```

## CI 失败分析模板

```md
## Failed Check

## Failure Summary

## Likely Cause

## Related Changes

## Suggested Fix

## Risk of Fix

## Need Human Input?
```

## Release 检查模板

```md
## Release Summary

## Included Changes

## Risk Level

## Required Approvals

## Monitoring Plan

## Rollback Plan

## Known Limitations

## Post-release Checks
```
