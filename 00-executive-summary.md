# 00. 高层摘要

## 背景

AI 正在改变软件开发，但大多数团队仍停留在个人效率阶段：

```text
开发者打开 AI 工具
-> 输入一个模糊需求
-> 得到一段代码
-> 自己判断是否能用
```

这种方式对个人有帮助，但对团队和企业有明显风险：

- 上下文不可控。
- 知识不可追踪。
- 责任不可归属。
- 质量不可稳定复现。
- 安全和合规边界不清。
- 团队规范依赖个人自觉。

企业级团队 AI 开发范式的目标，是把 AI 从“个人助手”升级为“团队研发系统的一部分”。

## 范式定义

企业级团队 AI 开发范式由六个部分组成：

```text
人类责任体系
+ Agent 协作协议
+ 团队记忆账本
+ 事件级 Hook
+ 策略治理
+ 质量评测闭环
```

它解决的不是“怎么让 AI 写更多代码”，而是：

```text
如何让 AI 在真实团队研发中安全、稳定、可复用、可审计地参与协作。
```

## 核心原则

### 1. AI 不绕过工程流程

AI 产出必须进入正常的需求、设计、开发、测试、评审、发布和复盘流程。

```text
AI 可以加速流程，但不能替代流程。
```

### 2. 上下文必须显式化

不能把团队规范、业务规则、历史决策和踩坑经验只留在人脑、聊天记录或模型上下文里。

它们必须进入可维护的团队知识系统：

```text
Memory Ledger
ADR
Runbook
Policy
Pitfall
Domain Rule
```

### 3. Agent 必须有身份和权限

企业级 AI 系统里不应该存在一个无所不能的“万能 AI”。

不同 Agent 应有不同权限：

- Planner 只做方案。
- Builder 生成代码。
- Reviewer 只审查。
- Tester 生成和运行测试。
- Security 检查安全风险。
- Release 生成发布说明。

### 4. 生成者不能批准自己的输出

AI Builder 写的代码，不能由同一个 Builder 自己批准。

建议流程：

```text
Builder Agent
-> Tester Agent
-> Reviewer Agent
-> Human Owner
```

### 5. 规则要变成 Hook

写在文档里的规范，只是“希望被遵守”。

企业级规范应尽可能转成自动化 Hook：

- 超大文件拦截。
- 密钥扫描。
- 高风险目录审批。
- PR 风险摘要。
- CI 失败分析。
- Release 前检查。

### 6. 每次 AI 协作都要留下 trace

Trace 不一定保存完整 prompt，但至少要保留：

```text
trace_id
event
agent_id
task_id
memory_refs
artifact_refs
input_hash
output_hash
human_owner
decision
timestamp
```

## 三个成熟度阶段

### L1：个人提效

特征：

- 开发者独立使用 AI。
- 无统一规范。
- 无审计。
- 无团队记忆。

风险：

- 质量不稳定。
- 隐性泄密。
- 代码风格漂移。
- 知识无法沉淀。

### L2：团队协作

特征：

- 有统一 AI 使用规则。
- 有 PR 模板。
- 有基础 Memory。
- 有部分 Hook。
- AI 产出进入 review。

这是多数小团队应先达到的目标。

### L3：企业治理

特征：

- Agent 有身份和权限。
- 任务有 trace。
- Memory 有版本和生命周期。
- 高风险动作有审批。
- AI 使用有指标看板。
- 安全和合规策略接入研发流程。

## 推荐最小实践

第一阶段只做五件事：

1. 建 `AGENTS.md`，写清团队 AI 协作原则。
2. 建 `memory/`，用 ID 管理团队规则和历史坑点。
3. 在 PR 模板中增加 AI Trace 和 Memory Impact。
4. 建 3 个 Hook：pre-commit、pr-opened、ci-failed。
5. 定义 5 个 Agent 角色：Planner、Builder、Tester、Reviewer、Security。

## 最终目标

企业级 AI 开发不是让每个人“更会问 AI”，而是让团队拥有一套稳定的 AI 协作操作系统：

```text
需求能被 AI 理解
规范能被 AI 引用
风险能被 Hook 发现
质量能被测试证明
决策能被人类负责
知识能在每次变更后增长
```

