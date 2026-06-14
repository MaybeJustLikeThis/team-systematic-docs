# 03. 带 ID 的团队记忆账本

## 目标

团队 AI 开发的关键不是让模型“记住”，而是让团队知识可引用、可版本化、可审计、可废弃。

Memory Ledger 是企业级团队知识系统。它服务于人和 AI。

## 为什么不是普通文档

普通文档的问题：

- 没有唯一 ID。
- 不知道是否过期。
- 不知道 owner 是谁。
- 不知道被哪些任务引用过。
- AI 引用时无法追踪来源。

Memory Ledger 的要求：

```text
每条知识有 ID
每次变更有版本
每个条目有 owner
每条规则有状态
每次引用可追踪
每次过期可废弃
```

## Memory 类型

| 类型 | ID 前缀 | 示例 |
|---|---|---|
| 企业政策 | `MEM-POLICY-*` | 数据脱敏、安全要求、合规边界 |
| 架构决策 | `MEM-ARCH-*` | 模块边界、技术选型、依赖规则 |
| 业务规则 | `MEM-DOMAIN-*` | 订单状态、计费规则、审批流程 |
| 接口契约 | `MEM-CONTRACT-*` | API 输入输出、兼容性要求 |
| 代码风格 | `MEM-STYLE-*` | 命名、目录、测试风格 |
| 历史坑点 | `MEM-PITFALL-*` | 曾经出过的问题和预防方式 |
| 事故复盘 | `MEM-INCIDENT-*` | 事故原因、影响和修复措施 |
| 运行手册 | `MEM-RUNBOOK-*` | 发布、回滚、排障步骤 |
| 评测标准 | `MEM-EVAL-*` | AI 输出质量、模型评测标准 |

## Memory 状态

```text
draft       草案，尚未生效
active      已确认，正式可引用
deprecated  已过期，不得作为当前依据
conflicted  与其他 Memory 冲突，需要仲裁
archived    历史保留，不参与决策
```

## 标准模板

```md
# MEM-ARCH-001: 模块边界规则

version: 1
status: active
owner: platform-team
scope: org/backend
classification: internal
created_at: 2026-06-14
updated_at: 2026-06-14
expires_at: 2026-12-31
supersedes: []
conflicts_with: []

## 规则

业务模块不得直接访问其他业务模块的数据库表，跨模块访问必须通过公开服务接口。

## 原因

直接访问会导致隐式耦合，破坏模块边界，使后续拆分、测试和权限治理变困难。

## 适用范围

- 后端服务
- 数据访问层
- 业务模块之间的调用

## 例外

只读报表任务可以通过数据仓库访问跨模块数据，但不得访问在线业务库。

## AI 使用要求

当 Agent 修改跨模块调用逻辑时，必须引用本 Memory，并在 PR 中说明是否符合该规则。

## 验证方式

- 代码 review 检查跨模块数据库访问。
- Hook 扫描直接导入其他模块 repository 的情况。
```

## Memory 写入流程

```text
变更或事故发生
  |
Agent 提取 Memory Candidate
  |
Human Owner 审查
  |
设置 ID、owner、scope、状态
  |
进入 draft
  |
团队确认
  |
变为 active
  |
被 Hook、Agent、PR 引用
```

## Memory Impact

每个 PR 都应声明：

```md
## Memory Used
- MEM-ARCH-001@v1
- MEM-STYLE-002@v3

## Memory Proposed
- MEM-PITFALL-014: 缓存键必须包含租户 ID

## Memory Changed
- None

## Memory Deprecated
- None
```

## Memory 冲突处理

如果一个任务同时引用了冲突 Memory，Agent 必须停止并请求仲裁：

```text
MEM-ARCH-001 要求通过服务接口访问
MEM-PERF-003 要求该路径避免 RPC 调用

结论：
存在架构和性能规则冲突，需要 Tech Owner 决策。
```

## 生命周期管理

建议每月做一次 Memory Review：

- 过期 Memory 是否还有效。
- draft 是否需要激活或删除。
- conflicted 是否已仲裁。
- 高频引用 Memory 是否需要转成 Hook。
- 事故类 Memory 是否已有预防机制。

## 企业级规则

1. AI 可以提出 Memory，但不能直接激活 Memory。
2. 高风险变更必须引用相关 active Memory。
3. deprecated Memory 不得作为当前决策依据。
4. Memory 必须有 owner，否则自动降级为 draft。
5. 连续 3 次被 PR 引用的 pitfall，应考虑转成 Hook。

