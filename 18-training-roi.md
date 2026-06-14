# 18. 培训、认证、成本和 ROI

## 目标

定义不同角色如何学习、认证和持续改进，并建立成本与收益模型。

## 分角色培训

| 角色 | 培训内容 |
|---|---|
| Engineer | AI 使用底线、Task Packet、PR 模板、Memory Impact |
| Reviewer | AI 代码常见缺陷、Review checklist、风险升级 |
| Tech Lead | 风险分级、RACI、架构 Memory、ADR |
| Security Owner | 红区策略、数据分级、Trace 审计、供应商治理 |
| Manager | 采用指标、团队激励、非监控承诺、ROI |
| Platform | Hook、Policy Engine、Registry、观测和 SLO |

## 认证等级

### Level 1：AI Contributor

能安全使用 AI 完成低风险任务。

要求：

- 完成基础培训。
- 会填写 AI Trace。
- 会判断敏感数据。

### Level 2：AI Reviewer

能 review AI-assisted PR。

要求：

- 识别 AI 常见缺陷。
- 会检查 Memory Impact。
- 会升级风险。

### Level 3：AI Owner

能负责中高风险 AI 任务。

要求：

- 会审批 Task Packet。
- 会处理红区流程。
- 会参与事故复盘。

## 成本模型

成本项：

- AI 工具 license。
- 模型 API 调用。
- 平台建设人力。
- Hook 维护人力。
- 审计存储。
- 安全和法务评审。
- 培训时间。
- 误报处理时间。
- Review 额外负担。

## ROI 指标

效率收益：

- cycle time 降低。
- CI 失败定位时间降低。
- 测试生成时间降低。
- 文档更新时间降低。

质量收益：

- 缺陷率降低。
- 回归问题降低。
- 高风险变更漏审降低。
- 事故复盘转化为 Hook 的比例提高。

知识收益：

- Memory 增长。
- Memory 被引用次数。
- 新人上手时间降低。
- 重复踩坑减少。

## Adoption Health Metrics

采用健康度：

- 活跃使用率。
- 培训完成率。
- Champion 覆盖率。
- 团队满意度。
- 误报疲劳指数。
- AI Trace 完整率。
- 放弃率。

## 非监控承诺

建议明确写入团队政策：

```text
AI 使用指标用于流程改进、风险治理和平台优化。
不得直接用于个人排名、绩效扣分或惩罚。
安全事故和违规行为按既有公司政策处理。
```

