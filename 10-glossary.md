# 10. 术语表

## A2A

Agent-to-Agent。Agent 之间的结构化任务交接协议。

## Agent

具备明确职责、输入、输出和权限边界的 AI 协作角色。

## Artifact

任务相关工件，如 issue、PR、diff、测试报告、日志、设计文档、截图。

## Audit Log

AI 行为审计记录，用于追踪谁触发了 AI、AI 读取了什么、产出了什么、由谁批准。

## Blocking Hook

发现高风险或硬性违规后阻断流程的 Hook。

## Hook

在研发事件上自动触发的检查、建议、审批或审计动作。

## Human Owner

对任务结果和风险接受负责的人类负责人。

## Memory Ledger

带 ID、版本、owner、状态和生命周期的团队知识账本。

## Memory Impact

一个变更对团队知识的影响，包括使用、提出、修改、废弃哪些 Memory。

## Policy Engine

执行安全、权限、合规和流程策略的规则引擎。

## Red Zone

高风险区域，如认证、支付、隐私、生产配置、密钥、数据迁移。

## Risk Level

任务风险等级。通常分为 low、medium、high。

## Task Packet

企业级 AI 协作的标准任务载体，包含目标、范围、约束、上下文、权限和验收标准。

## Trace

一次 AI 协作链路的追踪记录，通常包含 `trace_id`、agent、artifact、memory、decision 等信息。

## 生成者不能批准自己的输出

Builder Agent 生成的代码必须由 Reviewer Agent 和人类 owner 审查，不能由同一个 Agent 自我批准。

