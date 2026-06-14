# 企业级团队 AI 开发范式

版本：v1.1

适用对象：小型到中大型研发团队、技术负责人、工程效能团队、平台团队、安全合规团队。

目标：在 AI 时代，把个人使用 AI 写代码，升级为团队级、企业级、可治理、可审计、可持续演进的研发范式。

## 一句话定义

企业级团队 AI 开发范式，是一套围绕人、Agent、知识、流程、权限、质量和审计建立的协作系统。它不是让 AI 替代工程流程，而是把 AI 纳入工程流程，并用协议、记忆、Hook 和治理机制保证可控。

## 核心结论

```text
个人 AI 开发 = 人和 AI 对话
团队 AI 开发 = 人、AI、知识、流程共同协作
企业级 AI 开发 = 协作可追踪、权限可控制、质量可验证、知识可演进
```

## 文档目录

| 文件 | 内容 |
|---|---|
| `00-executive-summary.md` | 高层摘要和核心原则 |
| `01-operating-model.md` | 团队 AI 开发运行模型 |
| `02-agent-collaboration-protocol.md` | Agent-to-Agent 协作协议 |
| `03-memory-ledger.md` | 带 ID 的团队记忆账本 |
| `04-team-hooks.md` | 团队级 Hook 和事件治理 |
| `05-governance-security.md` | 权限、安全、合规和审计 |
| `06-delivery-workflow.md` | 从需求到发布的 AI 协作流程 |
| `07-quality-evaluation.md` | 质量、评测、指标和度量 |
| `08-templates.md` | 可复制的模板集合 |
| `09-adoption-roadmap.md` | 企业落地路线图 |
| `10-glossary.md` | 术语表 |
| `11-real-world-evaluation.md` | 子代理真实开发场景评估汇总 |
| `12-system-architecture.md` | 平台边界、部署形态和信任边界 |
| `13-interface-contracts.md` | A2A、Hook、Memory、Audit 等机器可读接口契约 |
| `14-state-machines.md` | Task、Memory、Approval、Hook、Incident 状态机 |
| `15-policy-engine.md` | 策略引擎、权限执行、红区和模型治理 |
| `16-runtime-operations.md` | Trace、Artifact、Memory Registry、SLO 和运行运维 |
| `17-adoption-operating-model.md` | 组织推广、治理委员会、RACI 和变革管理 |
| `18-training-roi.md` | 培训认证、成本模型和 ROI 度量 |
| `19-pilot-and-scale-proposal.md` | 面向上级的初期试点方案和后续推广方案 |

## 阅读建议

如果目标是先在一个小组内争取试点，优先阅读 `19-pilot-and-scale-proposal.md`。它是低成本、可衡量的落地入口。

`00` 到 `18` 号文档用于解释完整范式和后续扩展，不建议在第一次汇报时一次性全部展开。

## 范式全景

```text
业务目标
  |
需求事件
  |
Team Hook Gateway
  |
Policy Engine
  |
Agent Orchestrator
  |
A2A Protocol
  |
Builder / Reviewer / Tester / Security / Doc Agents
  |
Memory Ledger + Artifact Store + Audit Log
  |
人类 Owner 决策
  |
CI / Review / Release
  |
知识回写
```

## 四个基本原语

1. **A2A 协议**
   - 定义 Agent 之间如何交接任务。
   - 每次交接必须包含任务目标、上下文引用、权限范围、输入工件、输出格式和审计 ID。

2. **Memory Ledger**
   - 团队知识不是模糊记忆，而是带 ID、版本、owner、状态和生命周期的知识账本。
   - AI 的建议必须能引用来源。

3. **Team Hooks**
   - 在 issue、branch、commit、PR、CI、release 等事件上自动触发 AI 和策略检查。
   - 规范不靠人记，而是在正确节点自动出现。

4. **Human Accountability**
   - AI 可以生成、审查、建议和总结。
   - 人类 owner 对业务判断、风险接受和最终合并负责。

## 最小可落地版本

一个团队可以先从以下 6 个文件开始：

```text
.ai/
  AGENTS.md
  memory/
    MEM-POLICY-001.md
    MEM-ARCH-001.md
    MEM-PITFALL-001.md
  hooks/
    pr-opened.yaml
    pre-commit.yaml
  templates/
    issue-template.md
    pr-template.md
```

先不要追求复杂平台。企业级不是一开始就重，而是从第一天就保留：

```text
ID
版本
owner
权限
审计
验证
生命周期
```

## v1.1 真实场景补强

经过多视角评估后，v1.0 的主要缺口集中在：

- 缺少平台级系统边界和部署形态。
- 缺少机器可读接口契约。
- 缺少 Task、Approval、Hook、Memory 等状态机。
- 安全治理缺少模型供应商、数据出境、权限执行和日志脱敏。
- 真实交付流程缺少阶段门禁和发布后验证。
- 组织推广缺少治理委员会、培训、激励和 ROI。

因此 v1.1 增加 `11` 到 `18` 号文档，把范式从“说明书”推进为“企业平台蓝图 + 组织落地手册”。

## 判断是否企业级

如果团队无法回答下面的问题，就还不是企业级：

- 这段 AI 产出是谁发起的？
- 它读取了哪些上下文？
- 它引用了哪些团队规则？
- 它是否接触了敏感数据？
- 它被允许修改哪些文件？
- 它的输出由谁批准？
- 它是否通过了测试和安全检查？
- 这次变更是否沉淀了新的团队知识？
