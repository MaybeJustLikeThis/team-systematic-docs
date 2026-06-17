# 任务闭环系统设计 (Task Loop)

日期：2026-06-17
状态：设计待审
关联文档：`00-executive-summary.md` `01-operating-model.md` `03-memory-ledger.md` `04-team-hooks.md` `06-delivery-workflow.md`

## 一、背景与动机

现有体系（team-systematic-docs）把"AI 参与研发"讲得很完整——Task Packet、Memory Ledger、Team Hooks、Policy、Trace。但这些零件分散在 21 个文档里，**没有一个把它们串成"一次 AI 开发任务从头到尾怎么走"的可运行闭环**。

团队协作中的真实痛点：AI 一旦动手，范围失控、计划阶段的"为什么"丢失、规范靠自觉、出事责任黑洞。现有文档定义了概念，但没有给出一个能立刻在 Claude Code 里跑起来的最小实现。

本设计交付一个**单任务闭环系统**：在 AI 开始改代码前锁定范围，计划阶段就提交前置知识，开发结束提交后置知识，三拍之间用人发车、hook 守门的方式控制节奏。

## 二、目标与非目标

### 目标
- 一套可在 Claude Code 原生跑起来的最小配置（hooks + 命令 + 状态文件 + memory）
- 真约束，不靠自觉：范围越界硬拦截
- 计划阶段的前置知识不丢失（现有体系的缺口）
- 知识提交沿用现有 MEM-* 体系，AI 只写 draft

### 非目标
- 不做企业级平台（Agent 编排、多任务调度、权限中心）——那是 `12`–`16` 号文档的事
- 不替代 git/CI 流程——本系统是会话内的，git hook 是另一层
- 不做工具无关方案——明确绑定 Claude Code 原生能力

## 三、核心设计决策

| 决策点 | 选择 | 理由 |
|---|---|---|
| 产物形态 | 可跑的最小配置 | 体系最缺能上手的最小实现 |
| 运行载体 | Claude Code 原生 | 会话内阶段闸门只有原生 hook 能做 |
| 阶段切分 | 三拍 PLAN / BUILD / CLOSE | 最简且覆盖计划+开发+收尾 |
| 范围锁强度 | 硬拦截 + 放行口子 | 真约束，但实际越界可人工放行 |
| 阶段切换 | 人发车 + hook 守门 | 符合"人负责"原则，AI 不能自推进 |
| 实现结构 | 状态文件 + 单一守卫 | 单点真相，最小可跑 |

## 四、系统架构

### 文件结构

```text
.claude/
  settings.json        注册 PreToolUse 守卫
  commands/
    lock.md            /lock  [paths...]  锁定范围 + 进入 PLAN
    build.md           /build             切到 BUILD（先过 gate）
    close.md           /close             切到 CLOSE（先过 gate）/ 完成收尾
    extend.md          /extend [path]     放行口子：临时扩范围
CLAUDE.md              注入当前任务的阶段规则，指向 task.json
.ai/
  task.json            当前任务状态机（单点真相）
  memory/
    draft/             AI 提交的知识候选（不生效）
    active/            已激活团队知识 MEM-*
guardian.sh            PreToolUse 守卫
```

分工：`.claude/` 是 Claude Code 原生要读的位置（hook、命令必须放这）；`.ai/` 是本系统自己的数据（任务状态 + 知识库）。

### 状态机：task.json

```json
{
  "task_id": "TASK-20260617-payrefund",
  "stage": "PLAN",
  "human_owner": "cherry",
  "scope": {
    "allowed_paths": ["src/pay/refund/**"],
    "blocked_paths": ["src/auth/**", "infra/prod/**"],
    "extra_grants": []
  },
  "gate": {
    "plan_confirmed": false,
    "pre_committed": false,
    "tests_passed": false,
    "review_done": false,
    "post_committed": false
  }
}
```

`stage` 取值：`PLAN` | `BUILD` | `CLOSE` | `DONE`

```text
        /lock [paths]
[空] ──────────────────► PLAN
                          │ gate: plan_confirmed + pre_committed
                          │ /build  (不过 → 拒，告诉缺哪个)
                          ▼
                        BUILD ──► 越界 ──► /extend 放行
                          │ gate: tests_passed + review_done
                          │ /close  (不过 → 拒)
                          ▼
                        CLOSE
                          │ gate: post_committed
                          │ /close 再敲 或 /done
                          ▼
                        DONE（清 scope）
```

## 五、三拍行为矩阵

每拍用**可写白名单**定义允许范围（不用模糊的"是不是代码"判定，避免歧义）：

| 拍 | 可写白名单 | 守卫硬拦 | 产出 | 出门 gate |
|---|---|---|---|---|
| **PLAN** | `.ai/plan/**`、`.ai/memory/draft/**` | 白名单外一切写入 | Plan Note + 前置知识候选 | `plan_confirmed`、`pre_committed` |
| **BUILD** | `allowed_paths ∪ extra_grants` | 范围外写入；`blocked` 永禁 | Diff + 测试 | `tests_passed`、`review_done` |
| **CLOSE** | `.ai/memory/draft/**`、`**/*.md`(文档) | 再改实现代码 | 后置知识候选 | `post_committed` |

阶段是**递进锁**：CLOSE 想改代码必须先 `/build` 退回。读操作全程不受限。

## 六、两次知识提交

### 前置知识（PLAN 末提交）—— 抓"为什么"
- **范围决策**：为什么锁这些路径 / 为什么明确不碰某些路径
- **方案选型**：A/B/C 里为什么选这个
- **依赖规则**：这次引用了哪些现有 `MEM-*`（必须带 ID）
- **前置约束**：开发阶段要遵守的新发现约束

> 这些东西开发一动手就忘。现在不抓，事后只剩一堆 diff，没人知道为什么。

### 后置知识（CLOSE 提交）—— 抓"经验"
- **真实坑点**：开发中实际踩到的（不是猜的）
- **新决策**：开发中临时定的技术决策
- **行为变化**：API/数据/接口实际变了什么
- **转 hook 候选**：哪条规则值得下次自动化

### 落点与格式
沿用 `03-memory-ledger.md` 的 `MEM-*` 模板。

```text
AI 只能写到  memory/draft/   （候选，不生效）
                 │
                 │  人类在 CLOSE 末审查
                 ▼
            memory/active/   （激活成正式 MEM-*，带 ID/版本/owner）
```

呼应 `03` 铁律：**AI 能提议知识，但不能激活知识**。

## 七、守卫机制（guardian.sh）

### 两个执行体的分工

```text
guardian.sh   (PreToolUse hook)  → 同一拍内的动作约束（越界/阶段违规 → 当场拦）
/build /close (命令脚本)         → 拍间切换 + gate 验证
```

guardian 永不写 task.json，命令脚本永不管动作拦截。

### guardian 拦截逻辑

Claude Code 的 PreToolUse hook：脚本读工具调用 JSON（拿到工具名 + 目标路径），**退出码 2 = 阻断并把理由反馈给 AI，退出码 0 = 放行**。

```text
guardian.sh  ← PreToolUse, 匹配 Write/Edit/NotebookEdit/Bash(写操作)
  读 task.json → { stage, scope.allowed, scope.blocked, scope.extra }
  读 stdin     → { tool_name, 目标路径 }

  if 路径 == .ai/task.json:        exit 2  "系统文件，AI 不能改自己的状态机"
  if 路径 ∈ blocked:               exit 2  "硬禁区，/extend 也放不了"
  if stage == PLAN  && 路径 ∉ PLAN白名单:    exit 2  "PLAN 只能写方案和知识，先 /build"
  if stage == BUILD && 路径 ∉ (allowed ∪ extra):  exit 2  "越界，用 /extend 申请"
  if stage == CLOSE && 路径 ∉ CLOSE白名单:   exit 2  "CLOSE 冻结实现，改代码回 /build"
  else: exit 0
```

**命门**：`.ai/task.json` 对 AI 永远只读。否则 AI 能自己改 `stage`、给自己放行，整套约束作废。

### /extend 放行口子

```text
AI 越界（写非 blocked 路径）→ guardian exit 2，理由反馈给 AI
  → AI 停下，告诉人："我需要改 utils.go，超出锁定范围"
  → 人: /extend src/pay/refund/utils.go
       → task.json.scope.extra_grants += [该路径]   （只人能写）
       → AI 重试，guardian 这次放行
```

`extra_grants` 是临时放行，任务结束随 scope 一起清空，不污染下一次。`blocked` 是铁律，`/extend` 动不了。

## 八、gate 判定

| gate 字段 | 判定方式 | 触发者 |
|---|---|---|
| `plan_confirmed` | `/build` 时人确认计划 OK | 人 |
| `pre_committed` | 检测 `memory/draft/` 有前置知识文件 | 脚本自动 |
| `tests_passed` | 跑测试脚本，退出码 0 | 脚本自动 |
| `review_done` | `/close` 时人确认 review 已做 | 人 |
| `post_committed` | 检测 `memory/draft/` 有后置知识文件 | 脚本自动 |

能自动检测的全自动（文件存在、测试退出码），主观判断（计划、review）才落到人。无测试项目：`tests_passed` 可显式跳过，不卡死。

## 九、错误处理

| 场景 | 处理 |
|---|---|
| AI 尝试写 task.json | guardian exit 2，永远拦（命门） |
| AI 越界写非 blocked 路径 | guardian exit 2，提示用 `/extend` 申请 |
| AI 越界写 blocked 路径 | guardian exit 2，铁律不可放行 |
| `/build` 时 gate 不过 | 拒绝切换，明确告诉缺哪个 gate |
| guardian 自身出错 | **不静默放行**——exit 非 0 非 2 并告警（fail-closed） |
| task.json 不存在 | guardian 视为无任务，拦所有写，提示先 `/lock` |
| 无测试项目 | `tests_passed` 显式跳过 |

guardian 的 fail-closed 原则：宁可误拦，不可漏放。

## 十、测试策略（本系统自身如何验证）

- **guardian 单测**：构造 `{stage} × {路径类型}` 组合，断言拦截/放行
- **状态机测**：`/lock → /build → /close → /done` 全流程，断言 task.json 各阶段字段正确
- **放行口子测**：`/extend` 后越界路径变可写，`blocked` 仍不可写
- **命门测**：模拟 Write 工具写 task.json，必被拦
- **端到端**：跑一次完整任务，验证前置/后置知识落盘到 `memory/draft/`

## 十一、已知实现风险

1. **Bash 写操作识别**：guardian 能可靠拦 `Write/Edit/NotebookEdit`（目标路径明确）。但 Bash 命令（`echo > f`、`sed -i`、`mv`、`>` 重定向）是否写文件、写哪，难以可靠判定。**最小版策略**：对 `Write/Edit/NotebookEdit` 严格硬拦；对 Bash 用"高危写命令黑名单（rm/mv/cp/>/sed -i 等）+ 范围检查"的弱约束，并在 PLAN/CLOSE 阶段对 Bash 默认提示。后续版本再加强。
2. **跨平台**：`guardian.sh` 是 bash 脚本，Windows 需 Git Bash 环境（本项目当前就在 Windows，已具备）。
3. **白名单粒度**：CLOSE 的 `**/*.md` 可能误伤代码目录内的 md 文件。最小版接受这个偏差，后续可按项目配置 `docs/**` 等精确白名单。

## 十二、范围边界

本系统是**会话内的单任务闭环**。它不覆盖：

- 多任务并发调度（一次只一个 `task.json`，换任务需重新 `/lock`）
- 跨工具留痕（git/CI 层，由现有体系其他部分负责）
- 企业级权限中心 / 审计平台（`12`–`16` 号文档范围）

参考实现将作为本仓库的可运行示例，验证文档体系从"说明书"推进到"能跑"的闭环。

## 十三、与现有体系的关系

| 本系统 | 对应现有文档 |
|---|---|
| `/lock` 锁定 scope | `01` Task Packet 的 `allowed_paths` / `blocked_paths` |
| 两次知识提交 | `03` Memory Ledger + `06` Memory Update 阶段 |
| guardian 守卫 | `04` Team Hooks 的 Blocking Hook |
| gate 门禁 | `06` Flow Gate Matrix |
| 三拍 PLAN/BUILD/CLOSE | `06` 宏观流程在"单次会话"内的微观压缩 |

本系统不是新概念，而是把散在 5 个文档里的零件，**捏成一个会话内可运行的最小闭环**。它的增量在两处：PLAN 阶段就提交前置知识（现有体系只在开发后提取），以及用 hook 编排单任务节奏（现有 hook 是 git 事件级）。
