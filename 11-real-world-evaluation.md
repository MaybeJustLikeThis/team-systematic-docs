# 11. 真实开发场景评估汇总

## 评估背景

本评估以真实软件开发团队为场景：AI 会参与 issue 分析、设计、代码实现、测试、review、CI 失败分析、PR 合并、发布和复盘。

评估视角包括：

- 研发流程闭环。
- 安全、隐私和合规。
- 工程工具化落地。
- 组织推广和采用。
- 企业架构完整性。

## 总体结论

v1.0 具备企业级团队 AI 开发范式的核心骨架：A2A、Memory Ledger、Team Hook、Human Owner、Trace、红区、质量指标和落地路线图已经成体系。

但在真实开发场景下，它还不能直接作为企业平台蓝图。主要问题不是方向错误，而是执行层不够硬：

```text
有原则，但执行语义不足。
有流程，但阶段门禁不足。
有模板，但机器校验不足。
有安全意识，但供应商和数据治理不足。
有路线图，但组织采用机制不足。
```

## 综合评分

| 维度 | 评分 |
|---|---:|
| 概念完整性 | 8.0 |
| 研发流程闭环 | 7.1 |
| 安全合规基线 | 5.5 |
| 工程工具化可落地性 | 6.0 |
| 组织采用 | 7.0 |
| 企业平台蓝图 | 6.5 |
| 综合 | 6.7 |

## P0 问题

### P0-1：缺少系统边界和部署形态

文档提到 Team Hook Gateway、Policy Engine、Agent Orchestrator、Artifact Store 和 Audit Log，但没有定义它们的职责、部署方式、信任边界、数据流和集成点。

影响：

- 平台团队不知道应该实现什么。
- 安全团队不知道控制点在哪里。
- 研发团队不知道哪些能力是 repo-local，哪些是中心服务。

处理：

- 新增 `12-system-architecture.md`。

### P0-2：缺少统一接口契约

A2A、Hook、Audit、Memory 和模板都使用 trace、risk、memory、artifact 等字段，但命名和必填语义不统一。

影响：

- 后续无法做 schema 校验。
- Hook、Agent、CI、PR 系统难以互操作。
- 审计链路容易断。

处理：

- 新增 `13-interface-contracts.md`。

### P0-3：缺少核心状态机

Task、Memory、Hook、Approval、Trace、Incident、Agent Run 都需要状态机。没有状态机，流程图无法支撑真实平台运行。

处理：

- 新增 `14-state-machines.md`。

### P0-4：安全治理缺少供应商、模型和数据出境控制

真实企业开发中，AI 可能读取代码、PR、Issue、日志、截图和客户上下文。v1.0 没有定义模型供应商、数据驻留、训练使用、保留周期、跨境传输和私有端点策略。

处理：

- 新增 `15-policy-engine.md`。

### P0-5：发布闭环缺少线上验证

原流程到 Release 和 Memory Update 为止，但真实交付应以线上验证和事故回流为闭环终点。

处理：

- 本次在 `16-runtime-operations.md` 中定义发布后验证、回滚触发和运行看板。

## P1 问题

### P1-1：风险分级缺少判定矩阵

Low / Medium / High 需要从路径、数据等级、API 兼容性、schema、权限、生产配置、用户影响等维度判定。

### P1-2：责任模型缺少 RACI / DRI

已有角色列表，但缺少 Responsible、Accountable、Consulted、Informed 的阶段矩阵。

### P1-3：Hook 误报、失败和豁免机制不足

真实团队需要知道 fail-open / fail-closed、豁免人、豁免时长、事后复核和审计规则。

### P1-4：Trace 存储和审计证据链不足

需要定义 trace 存储位置、保留周期、访问权限、不可篡改策略、SIEM 对接和 prompt 保存边界。

### P1-5：组织推广缺少治理委员会、培训、激励和 ROI

工程文档较完整，但企业采用还需要组织机制。

处理：

- 新增 `17-adoption-operating-model.md`。
- 新增 `18-training-roi.md`。

## P2 问题

- 模板缺少填好的好例子。
- 低风险流程仍偏重。
- 指标缺少采集口径和阈值。
- Memory 容易变成仪式负担。
- Agent、Prompt、模型版本缺少生命周期。

## 修订优先级

```text
第一优先级：
  系统架构、接口契约、状态机、策略引擎

第二优先级：
  运行运维、Trace、Artifact、发布后验证

第三优先级：
  组织采用、培训认证、ROI、激励机制

第四优先级：
  示例模板、轻量流程、指标阈值
```

