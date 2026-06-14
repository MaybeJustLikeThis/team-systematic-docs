# 05. 治理、安全、合规和审计

## 目标

企业级 AI 开发必须解决四个问题：

```text
谁能让 AI 做什么
AI 能看什么数据
AI 能改什么代码
AI 的行为如何被追踪
```

## 数据分级

| 等级 | 类型 | AI 使用规则 |
|---|---|---|
| Public | 公开文档、公开代码 | 可用于 AI 输入 |
| Internal | 内部规范、非敏感代码 | 可用于受控 AI 输入 |
| Confidential | 客户数据、内部业务数据、未公开策略 | 需要脱敏和权限 |
| Restricted | 密钥、凭据、生产数据、个人隐私、财务敏感数据 | 默认禁止输入 AI |

## Agent 权限模型

### 读权限

| Agent | 默认可读 | 受限可读 | 禁止读取 |
|---|---|---|---|
| Planner | issue、docs、Memory | 架构图、非敏感日志 | 密钥、生产数据 |
| Builder | 代码、测试、docs | 相关日志 | 凭据、用户隐私 |
| Reviewer | diff、测试报告、Memory | 风险上下文 | 密钥 |
| Security | 安全策略、diff、依赖 | 脱敏日志 | 原始敏感数据 |
| Doc | docs、PR summary | 事故摘要 | 密钥、客户数据 |

### 写权限

| Agent | 可写 | 不可写 |
|---|---|---|
| Planner | 方案、任务拆解 | 生产代码 |
| Builder | 代码、测试 | 生产配置、密钥、发布脚本 |
| Tester | 测试、测试报告 | 业务逻辑绕测修改 |
| Reviewer | review 报告 | 业务代码 |
| Security | 风险报告、阻断建议 | 直接修业务逻辑 |
| Doc | 文档、Memory 候选 | 激活 policy Memory |

## 红区

以下区域默认属于红区：

```text
认证和权限
支付和账务
隐私和个人信息
生产配置
密钥和凭据
数据迁移
发布脚本
合规策略
安全策略
```

红区规则：

- AI 可分析，不可直接改动，除非任务明确授权。
- 必须绑定 human owner。
- 必须 Security Agent 检查。
- 必须审计。
- 必须有回滚或缓解方案。

## 审计事件

每次 AI 参与应记录：

```json
{
  "trace_id": "TRACE-20260614-0001",
  "timestamp": "2026-06-14T10:00:00Z",
  "event": "pr.opened",
  "agent_id": "agent.reviewer.v1",
  "human_owner": "alice",
  "task_id": "TASK-0001",
  "risk_level": "medium",
  "data_classification": "internal",
  "memory_refs": [
    "MEM-ARCH-001@v1"
  ],
  "artifact_refs": [
    "PR-123",
    "DIFF-456"
  ],
  "input_hash": "sha256:...",
  "output_hash": "sha256:...",
  "decision": "changes_requested"
}
```

## 安全检查清单

### 输入侧

- 是否包含密钥。
- 是否包含个人隐私数据。
- 是否包含客户原始数据。
- 是否包含生产日志。
- 是否可以脱敏。
- 是否需要更低权限模型或本地模型。

### 输出侧

- 是否生成了硬编码密钥。
- 是否绕过权限检查。
- 是否降低了认证强度。
- 是否泄露内部结构。
- 是否生成危险命令。
- 是否改变合规声明。

### 流程侧

- 是否有 human owner。
- 是否有风险等级。
- 是否进入 PR review。
- 是否通过测试。
- 是否通过安全检查。
- 是否有审计 trace。

## 合规原则

1. 最小必要上下文。
2. 默认不输入敏感数据。
3. 数据先脱敏，再进入 AI。
4. 高风险动作需要人工确认。
5. AI 输出不作为最终法律、财务、安全判断。
6. 审计记录保存周期由企业政策决定。

## 事故处理

如果发现 AI 导致安全或质量事故：

```text
1. 绑定 trace_id
2. 找到触发事件和 Agent
3. 找到引用的 Memory 和 artifact
4. 判断是规则缺失、Hook 缺失、权限过宽还是人工审批失败
5. 修复代码或配置
6. 新增 MEM-INCIDENT
7. 如可自动检测，新增 Hook
8. 更新团队培训材料
```

