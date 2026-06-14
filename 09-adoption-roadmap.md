# 09. 企业落地路线图

## 目标

提供一条从小团队试点到企业级治理的落地路径。

## 阶段 0：准备

时间：1 周

产出：

- 选择 1 个试点团队。
- 选择 1 个低到中风险项目。
- 明确 human owner。
- 确定允许使用的 AI 工具。
- 明确禁止输入 AI 的数据类型。

## 阶段 1：基础规范

时间：1 到 2 周

落地项：

- `AGENTS.md`
- Issue 模板。
- PR 模板。
- 基础风险分级。
- AI 使用底线。
- Memory 文件夹。

成功标准：

- 80% AI-assisted PR 填写 AI Trace。
- 80% PR 有测试或验证说明。
- 高风险变更能被人工识别。

## 阶段 2：Memory Ledger

时间：2 到 4 周

落地项：

- 建立 Memory ID 规范。
- 沉淀前 20 条 Memory。
- 每个 PR 增加 Memory Impact。
- 每周 Memory Review。

成功标准：

- 高频团队规则进入 Memory。
- AI Review 能引用 Memory。
- 每周至少 3 条 Memory 被使用或更新。

## 阶段 3：Team Hooks

时间：4 到 8 周

先做 5 个 Hook：

1. 密钥扫描。
2. 高风险路径检查。
3. PR 风险摘要。
4. CI 失败分析。
5. Merge 后 Memory 候选提取。

成功标准：

- 高风险路径变更自动要求 owner。
- 密钥类问题被提交前发现。
- CI 失败平均定位时间下降。

## 阶段 4：Agent 分工

时间：8 到 12 周

落地项：

- Planner Agent。
- Builder Agent。
- Tester Agent。
- Reviewer Agent。
- Security Agent。
- Doc Agent。

成功标准：

- 中风险任务走标准 Agent 链路。
- Builder 和 Reviewer 分离。
- Security Agent 覆盖所有 high risk PR。

## 阶段 5：审计和指标

时间：12 周以上

落地项：

- Trace 存储。
- AI 使用看板。
- Memory 引用看板。
- Hook 命中看板。
- 质量指标看板。

成功标准：

- 能按 trace 复盘一次 AI 参与变更。
- 能统计 AI PR 缺陷率。
- 能统计 Hook 误报率。
- 能统计 Memory 使用率。

## 组织建议

### 小团队

重点：

- 轻文档。
- 硬底线。
- 少量 Hook。
- 强 review。

推荐优先级：

```text
AGENTS.md
PR 模板
Memory
pre-commit Hook
pr-opened Hook
```

### 中型团队

重点：

- Agent 分工。
- Memory owner。
- 高风险审批。
- 指标看板。

### 大型企业

重点：

- 统一策略引擎。
- 跨团队 Memory Registry。
- 审计保留。
- 合规对接。
- 内部 AI 平台。

## 常见失败模式

### 1. 只有文档，没有 Hook

结果：

- AI 和人都会忘记规则。

解决：

- 高频规则转 Hook。

### 2. 只有 AI 写代码，没有 Memory

结果：

- 每个会话都从零开始。

解决：

- PR 后强制提取 Memory 候选。

### 3. Agent 权限过大

结果：

- 一个 AI 既写代码又批准，还能改高风险文件。

解决：

- 分角色、分权限、分风险等级。

### 4. 指标只看效率

结果：

- 短期变快，长期质量下降。

解决：

- 同时看缺陷率、回归率、Hook 命中率、Memory 使用率。

## 90 天试点路线图

```text
Day 1-7
  定义规则、模板、风险分级

Day 8-21
  建 Memory Ledger，开始 PR Memory Impact

Day 22-45
  上线基础 Hook，覆盖安全和高风险路径

Day 46-70
  引入 Agent 分工，建立 A2A Task Packet

Day 71-90
  建审计和指标看板，复盘试点效果
```

## 6-12 个月企业推广路线

```text
Month 1-2
  完成供应商和模型治理，明确 approved model matrix
  建立 AI 研发治理委员会
  建立基础培训和 champion 网络

Month 3-4
  上线 Team Hook Gateway
  建立中心化 Trace Store
  接入 Git、Issue、CI

Month 5-6
  上线 Policy Engine
  接入 IAM、DLP、Secrets Manager
  覆盖高风险路径审批

Month 7-9
  推广到更多团队
  建立 Memory Registry 和组织级模板
  建立质量、采用和 ROI 看板

Month 10-12
  形成企业级运行机制
  接入 SIEM 和合规审计
  完成模型升级准入和评测机制
```

## 企业推广前置条件

- 法务、安全、采购确认允许使用的 AI 工具和模型。
- 数据分级和处理规则已发布。
- Trace 保留周期和访问权限已确定。
- 高风险红区路径已定义。
- 至少一个团队完成试点并通过退出条件。
