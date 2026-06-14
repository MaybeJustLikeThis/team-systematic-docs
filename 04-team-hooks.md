# 04. 团队级 Hook 和事件治理

## 目标

团队级 Hook 是企业 AI 开发范式中的执行层。它把团队规则从文档变成研发流程中的自动动作。

```text
文档告诉 AI 应该怎么做
Hook 保证不符合规则的动作会被发现或阻止
```

## Hook 事件

| 事件 | 触发时机 | 典型动作 |
|---|---|---|
| `issue.created` | 新需求创建 | 补充验收标准、风险等级、相关 Memory |
| `branch.created` | 分支创建 | 生成 Task Packet、加载上下文 |
| `before.commit` | 提交前 | 密钥扫描、红区路径检查、格式化检查 |
| `commit.created` | 提交后 | 变更摘要、测试建议 |
| `pr.opened` | PR 打开 | 风险摘要、Memory Impact、Review Agent |
| `pr.updated` | PR 更新 | 增量审查、测试缺口分析 |
| `ci.failed` | CI 失败 | 失败归因、建议修复路径 |
| `review.commented` | review 评论 | 判断是否需要更新 Memory |
| `merge.completed` | 合并后 | 生成变更总结、Memory 候选 |
| `release.started` | 发布前 | 风险确认、回滚方案检查 |
| `incident.created` | 事故发生 | 提取复盘模板、绑定相关变更 |

## Hook 类型

### Enrichment Hook

补充上下文，不阻断流程。

示例：

- issue 自动补充相关模块。
- PR 自动生成变更摘要。
- CI 失败自动附带可能原因。

### Advisory Hook

给出建议，不阻断流程。

示例：

- 提醒测试覆盖不足。
- 提醒可能需要更新文档。
- 提醒存在类似历史坑点。

### Blocking Hook

发现硬性违规后阻断。

示例：

- 提交包含密钥。
- 修改生产配置但无审批。
- 高风险目录被低权限 Agent 修改。

### Approval Hook

要求特定人类角色批准。

示例：

- 支付逻辑修改需要 Payment Owner。
- 权限模型修改需要 Security Owner。
- 数据迁移需要 DB Owner。

### Audit Hook

记录行为，不改变流程。

示例：

- 记录 AI 参与任务。
- 记录引用了哪些 Memory。
- 记录谁接受了风险。

## Hook 配置示例

```yaml
hook_id: hook.pr.high-risk-review
event: pr.opened
mode: approval
description: 高风险路径变更必须进入安全和 owner 审批

condition:
  paths_include:
    - "src/auth/**"
    - "src/payment/**"
    - "infra/prod/**"

actions:
  - assign_risk_level:
      value: high
  - load_memory:
      refs:
        - "MEM-POLICY-SECURITY@latest"
        - "MEM-RUNBOOK-RELEASE@latest"
  - run_agent:
      agent_id: "agent.security.v1"
      output: "security_review_report"
  - require_human_approval:
      roles:
        - "security-owner"
        - "module-owner"

timeout_seconds: 180
audit: true
```

## Hook 设计原则

1. 高频 Hook 必须快。
2. Blocking Hook 必须少而硬。
3. Advisory Hook 可以多，但要避免噪音。
4. 每个 Hook 必须有 owner。
5. 每个 Hook 必须有误报处理机制。
6. Hook 失败不能静默通过，必须输出状态。
7. Hook 规则来源最好引用 Memory。

## Hook 输出标准

```json
{
  "hook_id": "hook.pr.high-risk-review",
  "event": "pr.opened",
  "trace_id": "TRACE-20260614-0001",
  "status": "requires_approval",
  "risk_level": "high",
  "memory_refs_used": [
    "MEM-POLICY-SECURITY@v2"
  ],
  "findings": [
    {
      "severity": "high",
      "title": "修改了认证逻辑",
      "description": "该 PR 修改 src/auth 下的 token 校验逻辑",
      "required_action": "security-owner approval"
    }
  ]
}
```

## Hook 成熟度

### L1：提示型

- 自动生成摘要。
- 自动提醒风险。
- 不阻断。

### L2：检查型

- 密钥扫描。
- 文件大小检查。
- Lint/test 自动运行。

### L3：治理型

- 风险分级。
- 权限控制。
- 人工审批。
- Memory 引用校验。

### L4：自演进型

- 从事故和 PR 中提取新 Hook 候选。
- 高频 pitfall 自动建议转 Hook。
- Hook 效果进入指标看板。

