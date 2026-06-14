# 17. 组织推广和治理运行模型

## 目标

把 AI 开发范式从少数 power users 推广到整个研发组织。

## AI 研发治理委员会

成员：

- Engineering Lead。
- Platform Owner。
- Security Owner。
- Legal / Privacy。
- Procurement。
- Developer Experience。
- 试点团队代表。

职责：

- 批准 AI 工具和模型。
- 定义企业底线策略。
- 审批高风险例外。
- 仲裁跨团队冲突。
- 评估 ROI 和风险。
- 决定试点扩展或暂停。

## RACI 矩阵

| 活动 | Engineer | Tech Owner | Security | Platform | Legal | Manager |
|---|---|---|---|---|---|---|
| 低风险 AI 变更 | R | A | I | C | I | I |
| 高风险 AI 变更 | R | A | C | C | C | I |
| 模型供应商审批 | I | C | C | R | A | C |
| Hook 策略变更 | C | A | C | R | I | I |
| 数据出境例外 | I | C | R | C | A | I |
| 事故复盘 | R | A | C | C | C | I |

R = Responsible，A = Accountable，C = Consulted，I = Informed。

## Champion 网络

每个团队指定 1 到 2 名 AI Champion。

职责：

- 收集团队痛点。
- 推动模板使用。
- 维护本团队 Memory。
- 反馈 Hook 误报。
- 帮助新人培训。

## 推广原则

```text
先试点，再扩散。
先建议，再阻断。
先低风险，再高风险。
先人类扮演 Agent 角色，再工具化 Agent。
```

## 阻力管理

常见阻力：

- 担心 AI Trace 变成员工监控。
- 担心 reviewer 负担增加。
- 担心责任变重但授权不增加。
- 担心流程变慢。

回应原则：

- 不用 AI 指标做个人排名。
- Human Owner 有拒绝 AI 输出的权利。
- 高风险流程增加的是授权和保护，不只是责任。
- Hook 误报必须有反馈和修复 SLA。

## 试点准入条件

- 有明确负责人。
- 有低到中风险项目。
- 有基础 CI。
- 有 PR review 习惯。
- 有安全联系人。
- 团队愿意维护 Memory。

## 试点退出条件

满足以下条件才扩展：

- AI Trace 覆盖率达到目标。
- 无严重安全事故。
- Hook 误报率可接受。
- 团队满意度不下降。
- PR 周期或测试补充效率有改善。
- 关键缺陷率不升高。

