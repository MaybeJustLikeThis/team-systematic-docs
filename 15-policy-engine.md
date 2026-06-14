# 15. 策略引擎、权限执行和模型治理

## 目标

把安全、合规和团队规则从文档变成可执行策略。

## Policy Engine 输入

```text
Task Packet
User / Agent identity
Requested tools
Requested files
Data classification
Memory refs
Artifact refs
Event type
Risk signals
```

## Policy Engine 输出

```text
allow
deny
require_approval
require_redaction
require_local_model
require_security_review
```

## 风险判定矩阵

| 信号 | 风险提升 |
|---|---|
| 修改认证、权限、支付、账务、隐私 | high |
| 修改生产配置或发布脚本 | high |
| 涉及 Restricted 数据 | high |
| 修改公开 API 或数据库 schema | medium/high |
| 修改共享库或核心模块 | medium |
| 仅文档、测试、低风险 UI 文案 | low |

规则：

- 多个信号取最高风险。
- Security Owner 可以升级风险。
- 降级风险必须记录理由和审批。

## 数据处理矩阵

| 数据类型 | 默认等级 | 外部模型 | 脱敏 | 落盘 | 审批 |
|---|---|---|---|---|---|
| 公开文档 | public | 允许 | 不需要 | 允许 | 不需要 |
| 内部代码 | internal | 视供应商策略 | 建议 | 允许 | 视项目 |
| 生产日志 | restricted | 禁止 | 必须 | 受限 | 必须 |
| PII | restricted | 禁止 | 必须 | 受限 | 必须 |
| 密钥/凭据 | restricted | 禁止 | 不适用 | 禁止 | 不允许 |
| 漏洞细节 | confidential | 受限 | 视情况 | 受限 | 必须 |

## 模型供应商治理

每个模型必须进入 approved model matrix：

```yaml
model_id: approved-model
provider: approved-provider
allowed_data:
  - public
  - internal
training_use: disabled
retention: zero_or_contractual
region: approved-region
cross_border_allowed: false
private_endpoint: true
approved_by:
  - security
  - legal
  - procurement
```

## 权限执行

原则：

- 默认拒绝。
- 任务级短期授权。
- 工具级 allowlist。
- 路径级 sandbox。
- 网络 egress 控制。
- 高风险 JIT approval。
- 审批过期自动失效。

## 红区读写执行

红区分三类权限：

```text
read
write
execute
```

规则：

- 红区 read 也需要审批或脱敏。
- 红区 write 必须 human owner + security owner。
- 红区 execute 必须 release owner 或 ops owner。
- break-glass 必须事后复核。

## 密钥和凭据

规则：

- AI 不得读取明文密钥。
- 工具使用短期凭据。
- 凭据从 Secrets Manager 注入。
- 发现泄露后自动吊销和轮换。
- Trace 中不得保存明文密钥。

## 不可信上下文和 Prompt Injection

规则：

- Issue、PR、外部文档、日志都视为不可信输入。
- 不可信输入中的“忽略规则”“运行命令”“泄露密钥”等指令必须被忽略。
- 工具调用只能来自 Task Packet 和 Policy Decision。
- 外部链接和依赖需要隔离验证。

