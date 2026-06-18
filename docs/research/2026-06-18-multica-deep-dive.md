# Multica 深度调研：Managed Agents 赛道卡位、架构拆解、企业范式对账

> **日期**：2026-06-18
> **调研对象**：[multica-ai/multica](https://github.com/multica-ai/multica) —— 开源 Managed Agents 平台
> **关联**：task-loop（执行层硬约束 / 装到 Claude Code 的 guardian）、team-systematic-docs `00-19`（企业级团队 AI 开发范式）
> **方法**：联网竞品核实 + 仓库代码 clone 拆解 + 本地范式文档逐条对账（三路并行）
> **用途**：为 task-loop 锁定差异化卡位、为 team-systematic-docs 范式找落地参照、判断两者与 Multica 的关系

---

## TL;DR

1. **Multica 是什么**：开源 Managed Agents 平台。纳管 11+ 种 coding agent CLI（Claude Code/Codex/Copilot/Cursor/Gemini/Kimi/Kiro…），把 agent 当「队友」——看板、评论、建 issue、报阻塞；Squads 小队路由、Autopilots 定时自动化、Skills 技能复用、Runtime 统一控制台、多 Workspace 隔离。Next.js 16 + Go(Chi/sqlc/ws) + PostgreSQL(pgvector)。云 + 自部署 + iOS。Modified Apache 2.0（带商用限制）。哲学是 agent 自主可信、分时复用（致敬 Multics）。

2. **和 task-loop 的关系：互补，不是竞品**。Multica 是**控制面/编排层**（管多 agent、调度、协作可见性、知识复用）；task-loop 是**执行面的纪律层**（单个 agent 改文件时怎么被硬约束）。技术栈正交——Multica 纳管 CC 时，可以给那个 CC 装上 task-loop 的 guardian。

3. **三块核心发现**：
   - **竞品**：「文件级硬约束 + 人发车 + fail-closed」三轴同时满足的，**全赛道没有第二家**。最近的是 AWS Kiro（机制几乎一样，但闭源、IDE、agent 驱动流程）和 claude-guardrails（形态最像，但静态配置、无动态 lock、无强制知识）。task-loop 真正没人做的是后半截：把约束包进强制的人发车流程 + 强制两次知识沉淀。
   - **架构**：Multica 的 `Backend` 单方法接口把 13 种异构 CLI 折叠进 `Execute(ctx,prompt,opts)->*Session`，输入用字段并集、输出归一成 7 种 Message 枚举——这套抽象值得 task-loop 未来跨 CLI 时抄。**关键结论：guardian 不该塞进 agent CLI 内部，应放在 daemon 的 execenv 层（spawn 子进程前写 `.claude/settings.json`）**，与 Multica 现有的 per-provider 文件落盘机制同构。但 Multica 自己**完全不做 hook 约束**——它对 claude 直接 `--permission-mode bypassPermissions` 全放权。
   - **对账**：Multica 强在「调度+编排+知识+协作可见性」，team-systematic-docs 范式强在「门禁+策略+审计+责任」。范式 `04/05/15/16` 定义的「执行时防越界硬约束层」（路径边界→Policy 决策→Blocking 拦截→fail-closed→人发车→不可篡改审计），**Multica 整块跳过**。task-loop 正是补这一层。

4. **一句话定位 task-loop**：不是又一个 AI 编程工具，是 Claude Code 的「刹车 + 纪律官」——**自主 agent 时代的合规与可审计层**。

---

## 一、Multica 是什么

开源 Managed Agents 平台。把编码 agent 变成「真正的队友」：像给同事派活一样把 issue 分给 agent，它自主接手、写代码、报阻塞、更新状态。不再复制粘贴 prompt、不用盯着运行过程。

**名字**：Multica = **Mul**tiplexed **I**nformation and **C**omputing **A**gent，致敬 1960 年代 Multics 分时系统。核心比喻：AI 时代重新做「分时」，只是现在多路复用的「用户」是人类 + 自主 agent。「两个工程师 + 一组 agent = 二十人的推进速度」。

**功能**：
- **Agent 即队友**：profile、看板、评论、建 issue、主动报阻塞。
- **Squads**：多 agent + 人组小队，leader agent 路由——`@前端组` 代替 `@张或李或王`。
- **自主执行**：完整生命周期（排队/认领/执行/完成失败），WebSocket 实时推。
- **Autopilots**：Cron/Webhook/手动定时触发，自动建 issue 派 agent（日报、周报、巡检）。
- **Skills 复用**：每个解决方案沉淀为全队技能。
- **统一 Runtime**：本地 daemon + 云端，自动探测可用 CLI。
- **多 Workspace**：团队级隔离。

**技术栈**：Next.js 16 (App Router) / Go (Chi + sqlc + gorilla/websocket) / PostgreSQL 17 + pgvector / 本地 daemon 执行各 CLI。代码量 Go ~8M + TS ~7.8M，monorepo（pnpm + turbo）。

---

## 二、竞品卡位：Managed Agents / AI Coding Agent 赛道横向

> 全部功能描述经联网核实（2026-06）。**事实修正**：原设想中的「网易工蜂 AI」并不存在——工蜂是**腾讯**的代码托管产品（code.tencent.com），网易的 AI 编程产品叫 CodeWave（低代码方向），两者都不在 managed-agents 赛道。

### 2.1 横向对比表

| 产品 | 定位 | 信任模型 | 边界约束粒度 | 开源/协议 | 形态 | 知识沉淀 | 多 agent |
|---|---|---|---|---|---|---|---|
| **task-loop**（我方） | CC 的 fail-closed 文件级硬约束 + 人发车三拍 | **人主导/受约束** | **文件级硬约束（lock）** | **MIT** | 纯 shell 分发物，只服务 CC | 带 ID memory，强制两次提交 | 否 |
| **Claude Code**（基线） | Anthropic 官方 agentic CLI | 自主放权 | deny/ask/allow + Plan 模式 | 闭源 | CLI / IDE | CLAUDE.md（静态） | 是（subagents） |
| **Devin**（Cognition） | 自主 AI 软件工程师 | 自主放权（async） | issue/PR 级 | 闭源 | 云 SaaS | Knowledge Base + Playbooks | 是（并行云 agent） |
| **Multica**（参照） | 开源 Managed Agents 平台 | 自主可信 | issue 级（无文件级） | Modified Apache 2.0 | 云+自部署+iOS | Skills | 是（Squads+Autopilots） |
| **Copilot Coding Agent** | 异步自主编码（跑在 GH Actions） | 自主放权（async） | 仓/分支级，禁改 `.github` | 闭源 | 云（GitHub） | living specs | 部分 |
| **Cursor** | AI-native IDE | 自主放权（Background Agent） | Rules + Skills（软约束） | 闭源 | IDE | project Memories | 是 |
| **OpenHands** | 开源模型无关云 agent | 自主放权 | 沙箱边界（非文件锁） | **MIT** | 本地 Docker/云 | 无强制 | 是（可扩展） |
| **Google Jules** | 异步自主云 VM agent | 自主放权 | repo/PR 级 | 闭源 | 云 | 透明 plan | 是（最多 60 并发） |
| **AWS Kiro** ⚠️ | spec-driven agentic IDE，**最接近的相邻产品** | **半受约束** | **Steering 文件 + Hooks（文件级 + Pre/Post Tool Use，exit code 控制放行/拦截）** | 闭源（AWS） | IDE | steering files | 是 |
| **Plandex** | 终端大型多文件 agent | 半受约束（diff 先审） | 分支/diff 级 | AGPL | CLI（Go） | 计划版本控制 | 是 |
| **claude-guardrails**（dwarvesf） ⚠️ | CC 安全配置包 | 受约束（安全导向） | **deny 规则 + PreToolUse 路径拦截** | 开源 | CC 配置包 | 无 | 否 |

> ⚠️ = 与 task-loop 概念空间高度重叠。

### 2.2 差异化卡位：三轴拆解

把赛道按 task-loop 押注的三个轴拆开，逐一核对：

**轴 1 · 文件级硬约束（越界 exit 2）**：几乎所有主流 agent（Devin/Copilot/Jules/Cursor/OpenHands）边界都停在 issue/PR/repo 级，靠「在 PR/分支上改、事后 review」兜底，**不阻止 agent 在范围内写哪个文件**。唯一沾边的是 **AWS Kiro** 的 Agent Hooks（`Pre Tool Use` + tool name 匹配 + file pattern + shell 命令，exit code 控制放行/拦截）和 CC 生态的 **claude-guardrails** + 多个社区 PreToolUse hook——它们是 task-loop 在 CC 生态内的**直接竞品**。但两者都是**静态一次性配置**，没人把「锁定范围」做成**任务运行时动态声明**的动作（task-loop 的 `/lock`）。

**轴 2 · 人发车（人推进阶段，AI 不能自走）**：task-loop 是**反潮流的孤独押注**。整个赛道方向是「更自主」：Devin 强调 async、Copilot 强调 assign 后独立工作、Jules 强调 60 并发、Multica 的 Autopilots 直接 cron/webhook 触发无需人 assign。学术侧有呼应——OpenAI Harness Engineering（humans steer, agents execute）、Martin Fowler《Humans and Agents in Software Engineering Loops》——但都停留在文章层面，**没有产品化成强制阶段门禁**。**没有竞品把阶段切换做成必须由人触发的硬流程**。

**轴 3 · fail-closed（宁可误拦）**：CC 官方文档明确 PreToolUse hook exit 2 = 阻断并告知模型，社区共识「安全 hook 应 fail closed」。但这是**能力**不是**默认哲学**——所有 agent 默认 fail-open。**把 fail-closed 作为第一性原理的，目前只有 task-loop**。
> ⚠️ **风险提示**：CC 生态有活跃 bug 报告显示这个机制有边缘情况——[#24327](https://github.com/anthropics/claude-code/issues/24327)（exit 2 有时让 Claude 直接停而非重试）、[#31250](https://github.com/anthropics/claude-code/issues/31250)（lock file 模式静默失败）、Windows + 多 agent 场景已知问题。task-loop 把产品押在这条机制上，需持续跟进。

### 2.3 task-loop 押注的独特价值

**没有竞品同时满足三轴**。最近的两个：

- **AWS Kiro**：机制几乎一样，但闭源、IDE 形态、AWS 绑定、spec-driven 流程是 agent 驱动。它把能力做成**产品功能**，task-loop 做成**极轻的、可装到任意 CC 项目的开源纪律层**。用户群不重叠。
- **claude-guardrails + 社区 hooks**：形态最像，但都是**静态安全配置**，缺 task-loop 的两块独特拼图：**运行时动态 `/lock`** 和**强制两次知识提交**。

**task-loop 真正没人做的是后半截**：约束本身（exit 2、文件锁）是 CC 平台能力，谁都能用；但「人发车三拍 + 前置后置强制两次知识落地」是**工作流方法论的产品化**，竞品里是空白。Devin 有 Knowledge Base、Copilot 有 living specs、Kiro 有 steering files——但都是**可选的、agent 自主消费**的；task-loop 把知识提交做成**阶段门禁的硬要求**。

### 2.4 一句话市场定位

> **task-loop 不是又一个 AI 编程工具，而是 Claude Code 的「刹车 + 纪律官」：给信任不起自主 agent 的团队，把文件级硬约束、人发车阶段、强制知识沉淀这三件被全行业忽视的事，做成一个 fail-closed 的极轻开源 hook——让 AI 干活时不会再越界、不会再黑箱推进、不会再丢上下文。**

对外讲法明确切割：**不与 Devin/Copilot/Jules 比「谁更自主」**（那条路故意不走），定位成**「自主 agent 时代的合规与可审计层」**。对标 Kiro hooks/steering（承认机制相似）+ claude-guardrails（承认生态内有邻居），差异化死守三条：**运行时动态 lock、人发车硬流程、强制两次知识提交**。

---

## 三、Multica 架构拆解：daemon ↔ server ↔ agent-CLI 协议

> 基于 `git clone --depth 1` 的代码拆解（clone 于本地 `/d/Mycase/_research_multica`）。

### 3.1 结论速览

Multica 是**单 Go 二进制 + 多形态**：同一个 `multica` 既是用户 CLI 也是 server。核心创新在 `server/pkg/agent/` 一套**统一的 `Backend` 接口**，把 13 种异构 CLI 的差异折叠进 `Execute(ctx, prompt, opts) -> *Session`。**关键发现：Multica 不用 Claude hook 做约束——它对 claude 直接 `--permission-mode bypassPermissions` 放权，约束全靠写进 workdir 的 CLAUDE.md/AGENTS.md 文本 + 每轮 prompt 注入。**

### 3.2 系统数据流

```
Web/CLI 用户 ──HTTP──►  Server (Go, Chi)
                        │ POST /api/issues → 写 agent_task_queue(queued)
                        │ 调度器选 runtime → dispatched
                        │ daemonws.NotifyTaskAvailable(runtime, task)  [WS wakeup hint, 无正文]
                        │ 监听 progress/complete HTTP 回写 → 广播 task:* WS 事件
                        ▼
                  Daemon (同 multica 二进制, 跑用户机器)
                  1. 启动 detectAgentCLIs() → 扫 PATH 找 claude/codex/...
                  2. POST /api/daemon/register → 每个 (workspace × CLI) 注册一条 agent_runtime
                  3. 双通道取任务:
                     - taskWakeupLoop: 长连 WS 收 task:available
                     - pollLoop: 兜底每 3s POST .../tasks/claim (原子领取)
                  4. handleTask:
                     - execenv.Prepare: 建隔离 workdir, 写 CLAUDE.md/skills/MCP 配置
                     - agent.New(provider) → 选 backend
                     - backend.Execute → spawn 子进程 (stream-json/acp/json)
                     - executeAndDrain: 边读 stdout 边批量化上报
                  5. 回写 ReportProgress/Messages/Complete/Fail + 每 15s 心跳
                        │ exec.CommandContext(claude -p --output-format stream-json ...)
                        ▼
                  agent 子进程 跑在隔离 workdir 里
```

**两段式取任务的精髓**：WS 只传 wakeup 提示（`{runtime_id, task_id}`，无任务正文），daemon 收到后仍走 HTTP claim 原子领取。WS 断了不丢任务（pollLoop 兜底），claim 原子性交给 Postgres 行锁，避免 WS at-least-once 投递导致重复执行。

### 3.3 核心数据模型（Postgres，sqlc 生成）

| 表 | 作用 | 关键字段 |
|---|---|---|
| `agent` | 工作区的「虚拟员工」 | `runtime_id`(FK), `runtime_mode`(local/cloud), `max_concurrent_tasks` |
| `agent_runtime` | **一台机器某 CLI 的执行槽** | `workspace_id, daemon_id, provider`, `UNIQUE(workspace_id, daemon_id, provider)` |
| `agent_task_queue` | 任务队列 | `status`(queued/dispatched/running/completed/failed/cancelled), 部分索引 `WHERE status IN ('queued','dispatched')` |
| `task_message` | agent 执行流消息 | `task_id, seq, type, content, input(JSONB), output` |
| `skill`/`skill_file`/`agent_skill` | 技能实体+多文件+多对多 | |
| `squad`/`squad_member` | 多 agent 协作单元 | `leader_id`(agent), `member_type` |
| `runtime_profile` | **自定义 runtime**：任意二进制挂到某 protocol_family | `protocol_family`(须是 SupportedTypes 之一), `command_name`, `fixed_args` |

`runtime_profile` 设计巧妙：用户注册自定义二进制（如 fork 的 claude），`protocol_family=claude` 让 daemon 仍走 claude backend 协议解析，但实际启动 `command_name` 指向的二进制。

### 3.4 agent CLI 适配抽象（最有借鉴价值）

**接口** `server/pkg/agent/agent.go:16-21`：

```go
type Backend interface {
    Execute(ctx context.Context, prompt string, opts ExecOptions) (*Session, error)
}
```

整个抽象**只有一个方法**。差异通过两条通道吸收：

- **输入侧 `ExecOptions`**：字段是所有 CLI 能力的并集，每个 backend 按需消费，未知字段静默忽略。含 `Cwd/Model/SystemPrompt/MaxTurns/Timeout/ResumeSessionID/ExtraArgs/McpConfig/ThinkingLevel` 等。
- **输出侧 `Session` + 统一 `Message`**：不管 claude 吐 stream-json、hermes 吐 ACP、codex 吐 app-server JSON，全归一成 7 种 `MessageType`（text/thinking/tool-use/tool-result/status/error/log）。

```go
type Session struct {
    Messages <-chan Message   // 流式事件
    Result   <-chan Result    // 终态 + Usage
}
```

**工厂 + 单一白名单**：`New(agentType, cfg)` switch 分发，`SupportedTypes` slice 是单一事实源，须与 DB 的 `protocol_family` CHECK 约束（migration 120）和 `New` switch 三处同步。加新 CLI = 新增一个文件 + 三处登记。

**每个 backend 文件三件事**（以 `claude.go` 为例）：拼 CLI 参数（硬编码默认 `-p --output-format stream-json --verbose --permission-mode bypassPermissions`）→ `exec.CommandContext` 起子进程 → stdout 扫描器按私有 wire 格式逐行解析转译成统一 `Message`。跨平台差异用 build tag 拆分（`_windows.go` vs `_other.go`）。

### 3.5 daemon ↔ server 协议

**HTTP（daemon 主动，server `DaemonAuth` 鉴权）**：`/register`、`/deregister`、`/heartbeat`（15s，顺带拉 pending 动作）、`/runtimes/{rid}/tasks/claim`（**原子领取**）、`/tasks/{tid}/start|progress|messages|complete|fail|usage`。complete/fail 走指数退避重试。

**WebSocket（轻量，不传任务正文）**：
- Server→Daemon 唤醒：`{"type":"task:available","payload":{"runtime_id":..,"task_id":..}}`，daemon 收到后唤醒 pollLoop 去 claim。
- Daemon→Server 心跳：`daemon:heartbeat` / `daemon:heartbeat_ack`（镜像 HTTP 心跳响应，含挂起的 CLI 升级/model 枚举/skill 导入请求）。`runtime_gone:true` 让 daemon 主动 prune 死 runtime。

**消息批量化上报**：`executeAndDrain` 起 goroutine，500ms ticker + flush 回调，把连续增量合并成带递增 seq 的 batch 一次性上报。前端 `multica issue run-messages --since N` 增量轮询。

### 3.6 隔离环境 execenv（context 注入，非 hook）

`server/internal/daemon/execenv/` 是 workdir 准备层。**Multica 不写 `.claude/settings.json` 的 hooks**，约束全靠落盘文本：

| provider | 写入的 runtime brief | skills 发现路径 |
|---|---|---|
| claude | `workDir/CLAUDE.md` | `workDir/.claude/skills/` |
| codex/copilot/opencode/openclaw/hermes/cursor/pi | `workDir/AGENTS.md` | 各自 `.codex/` `.github/` `.opencode/`… |
| gemini | `workDir/GEMINI.md` | — |

MCP：claude/opencode 走 `--mcp-config <tmpfile>`；cursor/openclaw 写各自 config 文件。CLAUDE.md 里塞 agent 人格、技能索引、guardrails 文本、reply 规则。**没有任何 PreToolUse/PostToolUse hook 注入**——claude 直接 bypassPermissions 全放权。`issueguard` 包只做 issue 去重，与工具拦截无关。

---

## 四、企业范式对账：team-systematic-docs `00-19` vs Multica

### 4.1 对账表

| 范式原语（文档出处） | Multica 实现 | 实现方式 | 差距 |
|---|---|---|---|
| **A2A 协议**（02/13）Task Packet：`allowed_paths/blocked_paths/risk_level/trace_id/human_owner` | 部分 | Squads 路由、agent 自主执行链路 | 缺**结构化 Task Packet**。交接是 issue/workspace 级（自然语言+看板），无任务级路径边界信封、无 `trace_id` 贯穿。02 规则「Agent 不得访问 scope 之外的文件」无载体 |
| **Memory Ledger**（03/13）带 ID/版本/状态/生命周期的知识账本 | 部分 | Skills 技能复用 | Skills 是「能力复用」**不是「带 ID 版本、可废弃、可仲裁的规则账本」**。无 `MEM-INCIDENT/PITFALL` 分类、无 deprecated 拦截、无 PR 级 Memory Impact |
| **Team Hooks**（04/13/14）事件触发；Blocking/Approval/Audit；`fail_closed` | 弱实现 | Autopilots 定时自动化 | Autopilots 是「触发器→建 issue→派 agent」的**入站编排**，不是「事件→策略决策→阻断」的**出站门禁**。缺 before.commit/pr.opened 的 Blocking Hook、Hook 状态机、shadow 观察期 |
| **Human Accountability**（01/05）人类 owner 终签、高风险双签 | 部分 | Agent profile/看板/报阻塞 | 有「人能看能评论」，**缺「高风险强制人发车 + 双角色审批 + 审批过期失效」**。01「AI 不自我批准，生成审查必须分离」无强制载体 |
| **Task 状态机**（14）跨阶段门禁（review/approved/merged/verified） | 部分 | Agent Run 状态机 | 有 **Agent Run 级**状态机，**无 Task 级跨阶段门禁**。14 要求「released→verified 才闭环」，Multica 完成即完成，无发布后验证门 |
| **Policy Engine**（15/13）输入→allow/deny/require_approval；默认拒绝；红区三类权限；路径 sandbox | **未实现** | — | **最大结构性缺口**。无中心化策略决策点、无 risk→decision 矩阵、无「默认拒绝」基线 |
| **治理-红区**（05/15）认证/支付/密钥/生产配置默认红区，write 需双签 | **未实现** | — | 无红区概念。边界是 workspace 级隔离，**不是文件路径级红线区** |
| **审计-Trace Store**（05/13/16）sealed 不可改证据链 | 弱实现 | WebSocket 执行流、看板 | 有执行可见性，**不是审计级不可篡改证据链**。无 input/output_hash、无 policy_decision_id、无 sealed 归档。00「它被允许改哪些文件？」无法逐条回答 |
| **模型供应商治理**（15）approved model matrix、数据出境 | 未覆盖 | 多 CLI 纳管 | 「多 CLI 纳管」是运行时接入，**不是模型供应商级数据治理** |
| **数据分级**（05/15）Public/Internal/Confidential/Restricted | 未覆盖 | — | 无数据分级、无输入侧脱敏 |
| **Prompt Injection 防护**（15）不可信输入指令隔离 | 未覆盖 | — | Multica 把 issue 当 agent 任务来源，**未做指令隔离** |
| **质量评测闭环**（07）golden set/缺陷率/DoD | 未覆盖 | — | 无评测机制、无完成定义 |

### 4.2 反向差距：Multica 做了、范式未明确覆盖

| Multica 能力 | 范式对应 | 性质 |
|---|---|---|
| Runtime 统一纳管（自动探测 11+ CLI） | 12 提部署形态，未涉及多 CLI 统一接入 | Multica 补了**异构 runtime 工程化接入层** |
| 多 Workspace 隔离 | 12 提信任边界，未定义租户隔离 | workspace 是**多租户原语**，范式边界是**数据信任级** |
| Autopilots 定时主动造任务 | 04 Hook 是「事件→门禁」（gate 型） | Multica 补了**push 型主动编排**，范式全是 gate 型。正交能力 |
| Agent 即队友（社交化呈现） | 01 是权限角色，非社交实体 | Multica 补了**协作可见性/社交化呈现** |

> **关键判断**：Multica 强在「调度+编排+知识沉淀+协作可见性」，范式强在「门禁+策略+审计+责任」。重叠区只在 agent 分工这一窄带，其余近乎正交。

### 4.3 最关键：防越界硬约束层（task-loop 的正名位置）

**范式文档中关于「约束 AI 不越界」的论述（原文支撑）**：

- **权限模型**（15）：*默认拒绝。任务级短期授权。工具级 allowlist。**路径级 sandbox**。*
- **Task Packet 内嵌边界**（02/13）：`"allowed_paths":["src/**"]`, `"blocked_paths":["infra/prod/**","secrets/**"]`；*协议规则 3：Agent 不得访问 scope 之外的文件。*
- **Blocking Hook**（04/13）：*发现硬性违规后阻断。示例：提交含密钥 / 修改生产配置无审批 / 高风险目录被低权限 agent 修改。Hook 失败不能静默通过。*
- **fail-closed**（16）：*high risk：fail-closed。Policy Engine 故障：默认 fail-closed。*
- **生成/审查分离**（00/01/02）：*生成者不能批准自己的输出。AI 不自我批准。*
- **Prompt Injection 隔离**（15）：*工具调用只能来自 Task Packet 和 Policy Decision。*

这整套构成范式的「执行时防越界硬约束层」：路径边界→策略决策→Blocking 拦截→fail-closed→人发车→不可篡改审计。本质是 **「AI 能做什么」不由 AI 自己决定，也不由一句 prompt 决定，而由 Policy Engine 在每次工具调用前裁决**。

**Multica 执行层有没有文件级硬约束？——没有。** 它的边界全停在调度层与编排层：workspace/issue 级（非文件路径级）、Autopilots 入站触发（非出站门禁）、有 Skills 但无 Policy Engine/红区/risk→decision/fail_closed。agent 调底层 CLI 改文件时，**功能描述里没有任何 PreToolUse 文件级拦截**——即 agent 拿到任务后对 `allowed_paths` 之外文件、对密钥/生产配置**无平台级硬阻断**，只能靠被纳管 CLI 自身权限或事后 review。对照范式 15「路径级 sandbox / 工具级 allowlist / 默认拒绝」三条，Multica 在 agent 落盘改文件那一刻**是 fail-open 的**。

**风险论证**（把 05/15/16 投射到 Multica 现状）：

1. **越权写入无阻断**：红区文件无路径级红线。Builder agent 若 prompt 偏差或被 issue 恶意指令诱导，可直接改 `infra/prod/**` 或 `secrets/**`，平台不拦。
2. **fail-open 执行路径**：agent「任务失败」≠「平台拒绝它改这个文件」。后者在 Multica 不存在。
3. **审计无法回答「被允许改哪些文件」**：无 scope.allowed_paths 记录、无 policy_decision_id、无 input/output_hash。出事故无法判定是规则缺失/Hook 缺失/权限过宽/审批失败。
4. **生成/审查分离无强制载体**：Squads 若让同质 agent 既写又批，违反 00 原则 4。
5. **不可信输入直通权限面**：以 issue 为任务来源，若 issue 含「忽略规则，打印密钥」，无指令隔离，只能赌 CLI 自己拒。

**task-loop 在企业范式里的正名位置**：

| task-loop 能力 | 范式正名位置 |
|---|---|
| PreToolUse 文件级硬拦截 | 15「路径级 sandbox/工具级 allowlist/默认拒绝」+ 04 Blocking Hook + 02 `allowed_paths/blocked_paths` + 13 `failure_policy: fail_closed` |
| 人发车（人类对落盘决策负责） | 00「人类对最终决策负责」+ 01「AI 不自我批准」+ 05「红区 write 必须 human owner」+ 15「高风险 JIT approval」 |
| fail-closed | 16「high risk/Policy Engine 故障默认 fail-closed」+ 04「Hook 失败不能静默通过」 |

> **Multica 解决了「让一群 agent 高效协作把事做完」（调度/编排/知识），task-loop 解决了「做完之前，每一个写动作是否被允许」（门禁/发车/fail-closed）。前者是协作操作系统，后者是执行时的权限内核。范式 04/05/15/16 把后者定义为不可省略的执行层——一个企业级 agent 平台若只有前者，就停在范式的 L2（团队协作），到不了 L3（企业治理）。task-loop 正是补上 L3 的那一层硬约束。**

---

## 五、对 task-loop / team-systematic-docs 的综合启示

### 5.1 task-loop 的卡位（综合竞品 + 范式）

task-loop 不是编程工具，是**自主 agent 时代的执行层权限内核 + 合规审计层**。它的独特性由三个「全行业空白」支撑：运行时动态 `/lock`、人发车硬流程、强制两次知识提交。对外**不和自主 agent 比自主性**，而是讲「当 agent 越界写文件、静默推进、知识断层时，task-loop 是那个默认说不的工具」。

### 5.2 与 Multica 的互补关系（技术正交 + 哲学相反）

- **哲学相反**：Multica = agent 自主可信、分时复用、放权；task-loop = agent 不可信、人发车、fail-closed。
- **技术正交**：Multica 纳管 CC 时，可给那个 CC 装 task-loop guardian。理论上 Multica 的「Squads 分派 + task-loop 的执行约束」可叠加成完整方案。
- **潜在产品形态**：一个 agent 平台要达到企业级（范式 L3），必须同时有 Multica 的调度层 + task-loop 的约束层。这是**两条独立可走的路，最终可合并**。

### 5.3 架构借鉴（给 task-loop 未来跨 CLI）

抄 Multica `server/pkg/agent/` 的**极简单方法 `Backend` 接口 + 统一 7 种 Message 枚举 + 输入字段并集静默降级**。但**先别抽 adapter（YAGNI）**——codex.go 2009 行、hermes.go 1785 行说明适配层有长尾复杂度。task-loop 现在只纳管 cc，等真要接第二个 CLI 再抽。

**guardian 放置的关键结论**：不塞进 agent CLI 内部，放 daemon 的 execenv 层（spawn 子进程前写 `.claude/settings.json`），与 Multica per-provider 文件落盘机制同构。跨 CLI 时 guardian 应 provider-aware：cc 走硬 hook，其他走软约束（写进 AGENTS.md）或 output 后置审计，共享同一份规则定义。

### 5.4 范式正名（task-loop 在 00-19 里的位置）

task-loop = 范式 `04/05/15/16` 定义的「执行时防越界硬约束层」的最小可运行实现。team-systematic-docs 的范式是「说明书」，Multica 是「调度层的参照实现」，**task-loop 是「约束层的参照实现」**——三者构成一个完整的论证闭环：范式说应该有什么 → Multica 证明了调度层能落地 → task-loop 证明了被 Multica 跳过的约束层也能落地且更轻。

### 5.5 风险与行动项

- **持续跟进 CC hook edge case bug**（[#24327](https://github.com/anthropics/claude-code/issues/24327)、[#31250](https://github.com/anthropics/claude-code/issues/31250)、Windows 多 agent）——task-loop 把产品押在这条机制上。
- **持续观察相邻竞品**：AWS Kiro（机制最近的闭源对手）、claude-guardrails + 社区 PreToolUse hook（生态内直接邻居）。task-loop 的差异化（动态 lock + 人发车 + 强制知识）要持续在 README/对外材料里讲清楚。
- **考虑给 Multica 提一个集成视角**：论证「Multica + task-loop = 企业级完整方案」，可能在 task-loop README 或一篇技术文章里讲——这是 task-loop 进入更大生态的切入点。

---

## 附录：来源与文件引用

**竞品（2026-06 联网核实）**：Devin [devin.ai](https://devin.ai/) · Copilot Coding Agent [GitHub Blog](https://github.blog/news-insights/product-news/github-copilot-meet-the-new-coding-agent/) · Cursor [cursor.com](https://cursor.com/) · OpenHands [GitHub](https://github.com/OpenHands/openhands) · Google Jules [jules.google](https://jules.google/) · **AWS Kiro**（最相关）[kiro.dev/docs/hooks](https://kiro.dev/docs/hooks/) · Plandex [GitHub](https://github.com/plandex-ai/plandex) · **CC hooks 生态**（直接竞品）[Claude Code Hooks Docs](https://code.claude.com/docs/en/hooks)、[claude-guardrails](https://github.com/dwarvesf/claude-guardrails)、bug [#24327](https://github.com/anthropics/claude-code/issues/24327)/[#31250](https://github.com/anthropics/claude-code/issues/31250) · 人发车理念 [OpenAI Harness Engineering](https://openai.com/index/harness-engineering/)、[Martin Fowler](https://martinfowler.com/articles/exploring-gen-ai/humans-and-agents.html) · 工蜂归属 [code.tencent.com](https://code.tencent.com/)（腾讯，非网易）。

**Multica 代码**（clone `/d/Mycase/_research_multica`，用完可删）：适配器 `server/pkg/agent/{agent.go, <cli>.go}` · daemon 主循环 `server/internal/daemon/daemon.go`（runTask@3104、executeAndDrain@3751、pollLoop@2358）· WS `server/internal/daemon/{wakeup.go, daemonws/}` · 协议 `server/pkg/protocol/{messages,events}.go` · workdir 准备 `server/internal/daemon/execenv/` · 路由 `server/cmd/server/router.go:509` · DB schema `server/migrations/{001,004,008,026,084,120}_*.up.sql`。
