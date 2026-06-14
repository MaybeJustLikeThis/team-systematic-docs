# 12. 系统架构、边界和部署形态

## 目标

定义企业级团队 AI 开发范式的系统边界、组件职责、部署形态、信任边界和集成点。

## 组件全景

```text
Developer IDE / Chat / CLI
        |
Repo Local Layer
        |
Team Hook Gateway
        |
Policy Engine
        |
Agent Orchestrator
        |
Registry Layer
  - Memory Registry
  - Artifact Store
  - Trace Store
  - Policy Registry
        |
Enterprise Integrations
  - Git Provider
  - Issue Tracker
  - CI/CD
  - IAM
  - SIEM
  - DLP
  - Secrets Manager
```

## 组件职责

| 组件 | 职责 | 部署位置 |
|---|---|---|
| Repo Local Layer | 保存 `AGENTS.md`、repo-local Memory、Hook 配置和模板 | 每个仓库 |
| Team Hook Gateway | 接收 issue、PR、CI、merge、release 事件并标准化 | 团队服务或 CI App |
| Policy Engine | 输出 allow / deny / require_approval 等策略决策 | 中心化服务 |
| Agent Orchestrator | 调度 Planner、Builder、Tester、Reviewer、Security 等 Agent | 团队或企业服务 |
| Memory Registry | 存储带 ID、版本、owner、状态的团队知识 | repo-local 或中心化 |
| Artifact Store | 存储或引用 issue、diff、测试报告、日志、截图等 | 中心化或外部系统 |
| Trace Store | 存储 AI 行为审计证据链 | 中心化审计存储 |

## 部署形态

### 模式 A：Repo-local 轻量模式

适合小团队、试点和非高敏项目。

组成：

```text
.ai/
AGENTS.md
PR template
本地 Hook
CI job
```

优点是快速落地、成本低。缺点是跨团队治理弱，审计不集中。

### 模式 B：Team Service 模式

适合多仓库团队和中型研发组织。

组成：

```text
Team Hook Gateway
共享 Memory Registry
共享 Trace Store
Git / CI 集成
```

### 模式 C：Enterprise Platform 模式

适合大型企业和有安全、合规、审计要求的组织。

组成：

```text
中心化 Policy Engine
统一 Agent Orchestrator
IAM / DLP / SIEM / Secrets Manager 集成
模型路由和供应商治理
企业级 Audit Evidence Store
```

## 信任边界

### 不可信输入

- Issue 内容。
- PR 描述。
- Review 评论。
- 外部文档。
- 生产日志片段。
- 用户提交的错误报告。

规则：

- 不可信输入不得直接改变 Agent 权限。
- 不可信输入中的指令不得覆盖系统策略。
- 工具调用必须由 Task Packet 和 Policy Decision 授权。

### 半可信输入

- 内部文档。
- 旧 Memory。
- 历史 Trace。

规则：

- 需要版本和 owner。
- deprecated 内容不得作为当前依据。

### 可信控制面

- Policy Engine。
- IAM。
- Secrets Manager。
- 审批系统。

## 企业集成点

| 系统 | 集成目的 |
|---|---|
| Git Provider | PR、diff、review、merge 事件 |
| Issue Tracker | 需求和任务状态 |
| CI/CD | 测试、构建、发布门禁 |
| IAM | 人和 Agent 的身份与权限 |
| DLP | 敏感数据检测和阻断 |
| Secrets Manager | 密钥读取和轮换 |
| SIEM | 审计和安全告警 |
| Observability | 发布后指标、告警和回滚依据 |

