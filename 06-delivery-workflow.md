# 06. 从需求到发布的 AI 协作流程

## 目标

定义一个企业团队可以直接采用的 AI 参与研发流程。

## 总流程

```text
Issue
-> Design
-> Task Packet
-> Implementation
-> Test
-> Review
-> Security
-> Merge
-> Release
-> Memory Update
```

## Flow Gate Matrix

| 阶段 | 进入条件 | 退出条件 | 必需工件 | 阻断项 |
|---|---|---|---|---|
| Issue | 有业务背景和目标 | 验收标准、风险初判、human owner 已填写 | Issue Brief | 无 owner、目标不清 |
| Design | medium/high risk 或架构影响 | 推荐方案、风险、测试策略、回滚方向确认 | Design Note / ADR | 架构 owner 未确认 |
| Task Packet | Issue 或 Design 已确认 | scope、Memory、Artifact、acceptance criteria 完整 | Task Packet | allowed_paths / blocked_paths 缺失 |
| Implementation | Policy Decision 允许 | Builder Output 和测试证据存在 | Diff、实现报告 | 越权修改、红区未审批 |
| Test | 实现完成 | 核心路径和错误路径验证完成 | Test Report | 测试失败、关键路径未覆盖 |
| Review | 测试证据存在 | findings 处理或明确接受风险 | Review Report | blocking finding 未处理 |
| Security | high risk 或红区 | 安全结论和审批完成 | Security Report | 安全阻断、审批缺失 |
| Merge | CI 通过，审批完成 | 合并完成 | PR、CI Report | CI 失败、Trace 缺失 |
| Release | merge 完成 | 发布完成并进入监控窗口 | Release Note、Rollback Plan | 无回滚方案 |
| Post-release | 发布完成 | 指标正常，Release Owner 签核 | Post-release Report | 指标异常、告警触发 |
| Memory Update | 变更已验证 | Memory Impact 已处理 | Memory Candidate / Update | 高价值知识未处理 |

## 1. Issue 阶段

### 人类输入

- 背景。
- 目标。
- 非目标。
- 用户影响。
- 成功标准。
- 风险等级初判。

### AI 动作

Planner Agent 自动补充：

- 缺失问题。
- 相关模块。
- 验收标准。
- 风险点。
- 相关 Memory。
- 建议拆分任务。

### 输出

```text
Issue Brief
Risk Level
Memory Refs
Task Candidates
```

## 2. Design 阶段

适用于 medium/high risk。

### AI 动作

Planner Agent 生成：

- 方案 A/B/C。
- 推荐方案。
- 权衡取舍。
- 数据和接口影响。
- 测试策略。
- 回滚方案。

### 人类动作

Tech Owner 确认：

- 范围。
- 架构方向。
- 风险接受。
- 是否需要 ADR。

## 3. Task Packet 阶段

将需求转换为标准任务包：

```text
task_id
human_owner
risk_level
allowed_paths
blocked_paths
context_refs
artifact_refs
acceptance_criteria
expected_output
```

没有 Task Packet 的 high risk 任务不得进入实现。

## 4. Implementation 阶段

Builder Agent 执行：

- 读取 Task Packet。
- 读取相关 Memory。
- 只修改 allowed paths。
- 生成代码。
- 补充局部测试。
- 输出实现报告。

限制：

- 不做无关重构。
- 不扩大范围。
- 不修改 blocked paths。
- 不自行降低测试。

## 5. Test 阶段

Tester Agent 执行：

- 检查验收标准。
- 补充核心路径测试。
- 补充错误路径测试。
- 分析覆盖缺口。
- 运行可用测试。

输出：

```text
Test Summary
Failed Tests
Coverage Gaps
Risk-based Test Suggestions
```

## 6. Review 阶段

Reviewer Agent 以代码审查姿态工作：

- 找 bug。
- 找行为回归。
- 找测试缺口。
- 找过度抽象。
- 找 Memory 违背。
- 找风险未声明。

输出必须按严重程度排序。

## 7. Security 阶段

以下情况必须进入 Security：

- risk_level = high。
- 涉及红区。
- 涉及敏感数据。
- 涉及认证、权限、支付、账务、隐私。
- 涉及生产配置。

Security Agent 输出：

- 数据风险。
- 权限风险。
- 依赖风险。
- 日志风险。
- 合规风险。
- 是否阻断。

## 8. PR 阶段

PR 模板必须包含：

```md
## Summary

## Risk Level

## AI Trace

## Memory Used

## Memory Impact

## Tests

## Rollback

## Human Approval
```

## 9. Merge 阶段

合并前检查：

- CI 通过。
- 必要审批完成。
- Memory Impact 已填写。
- 高风险项有回滚方案。
- 没有未处理 blocking finding。

## 10. Release 阶段

Release Agent 可生成：

- release note。
- 影响范围。
- 监控指标。
- 回滚步骤。

但不能独立执行发布。

## 10.5 Post-release Verification

发布后验证是交付闭环的一部分，不是可选项。

必须确认：

- 关键业务指标正常。
- 错误率、延迟、资源使用未异常升高。
- 安全告警未触发。
- 日志中无新增高危错误。
- 灰度或全量发布决策有记录。
- 回滚触发条件未命中。
- Release Owner 完成签核。

如果发布后触发事故或回滚，必须：

1. 绑定原始 `trace_id`。
2. 创建 incident。
3. 复盘是否缺少 Memory、Hook、测试或审批。
4. 必要时新增 `MEM-INCIDENT-*` 或 Hook 候选。

## 11. Memory Update 阶段

合并后，Doc Agent 提取：

- 新架构决策。
- 新业务规则。
- 新坑点。
- 新 runbook。
- 需要废弃的 Memory。
- 值得转 Hook 的规则。

Human Owner 决定是否激活。

## 快速流程和完整流程

### 低风险快速流程

```text
Issue
-> Builder
-> Tester
-> Reviewer
-> PR
-> Merge
```

### 中风险标准流程

```text
Issue
-> Planner
-> Human Confirm
-> Builder
-> Tester
-> Reviewer
-> PR
-> Merge
-> Memory Candidate
```

### 高风险治理流程

```text
Issue
-> Planner
-> Security Precheck
-> Human Approval
-> Builder
-> Tester
-> Reviewer
-> Security Review
-> Release Owner
-> Merge
-> Release
-> Audit
-> Memory Update
```
