# 16. 运行运维、Trace 和发布后验证

## 目标

定义企业 AI 开发平台运行时需要的存储、观测、保留、故障处理和发布后验证机制。

## Trace Store

Trace Store 保存 AI 行为证据链。

要求：

- 支持按 trace_id 查询。
- 支持关联 task、PR、release、incident。
- completed 后进入 sealed，不允许修改，只能追加事件。
- 支持保留策略和归档。
- 高风险 trace 进入更长保留周期。

## Artifact Store

Artifact 类型：

```text
issue
design
diff
test_report
review_report
security_report
ci_log
release_note
incident_report
screenshot
```

每个 Artifact 必须有：

```text
artifact_id
type
source_system
classification
owner
created_at
retention_policy
access_policy
hash
```

## Memory Registry 运行要求

- 支持 ID 唯一性校验。
- 支持版本查询。
- 支持状态过滤。
- 支持 deprecated 拦截。
- 支持 conflict 检测。
- 支持 owner review。

## 发布后验证

Release 不以部署完成为终点，而以线上验证完成为终点。

### Post-release Gate

必需项：

- 关键指标正常。
- 错误率未异常升高。
- 日志无新增高危错误。
- 监控窗口已覆盖。
- 回滚条件未触发。
- Release Owner 签核。

### 回滚触发

示例：

- 错误率超过阈值。
- 关键业务指标下降。
- 安全告警触发。
- 数据一致性异常。
- 客户影响超过预设范围。

## SLO

建议平台 SLO：

| 能力 | SLO |
|---|---|
| Hook Gateway 可用性 | 99.9% |
| Policy Decision p95 | < 2s |
| Advisory Agent p95 | < 120s |
| Blocking Security Review p95 | < 10min |
| Trace 写入成功率 | 99.99% |

## 故障模式

### Hook Gateway 故障

- low risk：允许 fail-open，但记录事件。
- medium risk：进入人工 review。
- high risk：fail-closed。

### Policy Engine 故障

- 默认 fail-closed。
- 可通过 break-glass 进入紧急流程。

### Agent Orchestrator 故障

- 不阻断人类手动流程。
- 但不得自动批准或发布。

## 运行看板

看板指标：

- AI 任务数。
- Agent 成功率。
- Hook 命中率。
- Hook 误报率。
- Policy deny 数。
- 审批等待时间。
- 高风险任务数。
- Trace 完整率。
- Memory 引用率。
- 发布后验证通过率。

