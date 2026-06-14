# 01. 团队 AI 开发运行模型

## 目标

定义团队在 AI 时代如何组织研发协作，让 AI 成为研发系统的一部分，而不是每个开发者各自使用的外部工具。

## 团队角色

### Human Roles

| 角色 | 职责 |
|---|---|
| Business Owner | 定义业务目标、优先级和成功标准 |
| Tech Owner | 对架构、技术债和关键风险负责 |
| Module Owner | 对具体模块的变更质量负责 |
| Security Owner | 对安全、隐私和合规风险负责 |
| Release Owner | 对发布窗口、回滚方案和发布质量负责 |

### Agent Roles

| Agent | 职责 | 允许动作 | 不允许动作 |
|---|---|---|---|
| Planner Agent | 拆解需求、生成方案和风险清单 | 读文档、读代码、写方案 | 直接改生产代码 |
| Builder Agent | 实现代码和局部测试 | 写代码、补测试、生成迁移草案 | 自行合并、自行发布 |
| Tester Agent | 生成测试、补边界用例、分析失败 | 写测试、运行测试、输出覆盖建议 | 修改业务逻辑绕过测试 |
| Reviewer Agent | 审查 diff、找缺陷、检查规范 | 评论、输出风险报告 | 批准自己的代码 |
| Security Agent | 检查敏感信息、权限、依赖和合规 | 阻断高风险 PR、要求审批 | 绕过 owner 决策 |
| Doc Agent | 更新文档、ADR、Memory 候选 | 写文档、生成总结 | 激活政策类 Memory |

## 协作基本流

```text
人类定义目标
  |
Planner Agent 生成任务方案
  |
Human Owner 确认范围
  |
Builder Agent 实现
  |
Tester Agent 验证
  |
Reviewer Agent 审查
  |
Security Agent 风险检查
  |
Human Owner 批准
  |
CI / Release
  |
Doc Agent 回写知识
```

## 工作单元

企业级 AI 协作的基本单位不是 prompt，而是 **Task Packet**。

Task Packet 必须包含：

```text
task_id
目标
非目标
范围
风险等级
相关 Memory
相关 Artifact
允许修改路径
验收标准
输出格式
human_owner
```

## 风险分级

### Low

示例：

- 文档更新。
- UI 文案微调。
- 小范围测试补充。
- 非核心模块重构。

AI 权限：

- 可生成代码。
- 可自动补测试。
- 需要普通 PR review。

### Medium

示例：

- 业务流程改动。
- 数据结构调整。
- API 行为变化。
- 共享组件改动。

AI 权限：

- 可生成实现方案和代码。
- 必须引用相关 Memory。
- 必须通过 Reviewer Agent 和 Human Owner。

### High

示例：

- 权限、支付、账务、隐私、认证、生产脚本。
- 数据迁移。
- 安全策略。
- 发布流程。

AI 权限：

- 只能辅助分析、生成建议和测试。
- 写入需要明确授权。
- 必须 Security Agent 检查。
- 必须 Human Owner 批准。

## 团队节奏

### 每个需求开始前

- 明确目标和非目标。
- 确定风险等级。
- 绑定 human owner。
- 加载相关 Memory。
- 生成 Task Packet。

### 每个 PR 打开时

- 生成变更摘要。
- 生成风险摘要。
- 列出引用的 Memory。
- 检查新增或过期 Memory。
- 生成测试建议。

### 每次合并后

- 记录 AI Trace。
- 回写新的坑点、决策或规则。
- 标记是否需要更新 Hook。
- 更新模块 owner 的知识上下文。

## 责任边界

### AI 负责

- 提供候选方案。
- 加速实现。
- 暴露风险。
- 补充测试。
- 总结变更。
- 提取知识候选。

### 人负责

- 业务取舍。
- 架构取舍。
- 风险接受。
- 合规判断。
- 最终合并。
- 生产发布。

## 团队原则

```text
AI 不背锅，人类 owner 负责。
AI 不越权，权限由任务和风险等级限定。
AI 不凭空记忆，必须引用 Memory。
AI 不绕流程，所有产出进入工程门禁。
AI 不自我批准，生成和审查必须分离。
```

