# task-loop 分发包设计 (Distribution)

日期：2026-06-17
状态：设计待审
关联：`2026-06-17-task-loop-design.md`（系统本体设计）、`2026-06-17-task-loop.md`（实现计划）

## 一、背景与动机

task-loop 系统当前耦合在 `team-systematic-docs` 文档仓库里——`.claude/`、`.ai/`、`CLAUDE.md`、`README-task-loop.md` 全混在这个文档仓库中。后果：

- 别的 cc 项目想用，只能手动拷文件，没有安装/卸载，没有版本管理。
- 文档仓库兼任系统载体，职责混乱。
- 系统自身的升级/回退无机制。

用户诉求：把 task-loop 做成**可下载、一键装到任意 cc 项目、可干净卸载的独立分发物**。先 cc，codex 留后。

## 二、目标与非目标

### 目标
- 独立 git 仓库 `task-loop`，`git clone` + `bash install.sh` 一键装到任意 cc 项目。
- **项目级安装**（装到目标项目 `.claude/`，只对该项目生效）。
- **智能合并**：保留目标项目已有的 `settings.json`/`CLAUDE.md` 配置，只追加 task-loop 的部分。
- **干净卸载**：`bash uninstall.sh` 反向删除，保留用户产生的 `.ai/memory/` 数据。
- **纯 shell 脚本**：install/uninstall 由用户在终端直接 `bash` 运行，不经过 cc 工具调用——否则 guardian 会拦 uninstall 自己（系统激活后无 task.json 时拦所有写）。

### 非目标
- 不做 codex 硬拦截：codex 无对等的"写操作前跑自定义脚本"机制，v1 只服务 cc。
- 不做用户级/全局安装（`~/.claude/`）。
- 不做自动更新/版本迁移：更新 = `uninstall` + `install`，v1 手动。
- 不做单文件 bootstrap（`curl | bash`）：需托管 URL，v1 用 git clone。

## 三、核心设计决策

| 决策点 | 选择 | 理由 |
|---|---|---|
| 抽离形态 | 独立仓库 `task-loop` | 符合 `git clone` 诉求；team-systematic-docs 退回纯文档 |
| 安装范围 | 项目级 | 哪个项目要用装哪个，干净可逆 |
| codex 支持 | 先只 cc | codex 无对等 hook，硬拦截做不到 |
| 冲突合并 | 智能合并（保留用户配置） | 不覆盖用户已有的 settings.json/CLAUDE.md |
| 可逆机制 | manifest + 标记块 | install 写 manifest、CLAUDE.md 标记块；uninstall 据此反向 |
| 脚本形态 | 纯 shell（不经 cc） | guardian 会拦 cc 工具调用的 uninstall，必须用户直接 bash 跑 |

## 四、task-loop 仓库结构

```text
task-loop/                        独立 git 仓库，用户 git clone 它
  install.sh                      搬运工：把 src/ 装到目标项目，智能合并
  uninstall.sh                    反搬运：读 manifest 精确反向删，保留 memory
  src/                            要分发的内容（原样拷到目标项目）
    hooks/guardian.sh
    scripts/lib-state.sh
    scripts/task-lock.sh
    scripts/task-build.sh
    scripts/task-close.sh
    scripts/task-extend.sh
    commands/lock.md
    commands/build.md
    commands/close.md
    commands/extend.md
    claudemd-section.md           要追加进目标 CLAUDE.md 的三拍章节（含 start/end 标记）
    settings-hook.json            要合并进目标 settings.json 的 hook 片段
    gitignore-lines.txt           要加进目标 .gitignore 的行
  README.md / LICENSE
  tests/                          install/uninstall 自己的测试
```

`src/` 内容直接来自现有 task-loop 实现（`team-systematic-docs` 里已通过 71 断言验证的那套）。task-loop 仓库是这套实现的**唯一来源**。

## 五、install.sh 流程

```text
1. 查依赖        jq/bash。缺 jq → 报错退出 + 给安装命令（scoop/winget/brew）
2. 定位目标根    参数路径或当前目录；校验是目录
3. 查是否已装    .ai/.task-loop-manifest 存在 → 报错"已装，先 uninstall"，不重复装
4. 拷 src/       → 目标 .claude/{hooks,scripts,commands}/（目录不存在则建）
5. 合并 settings.json   jq 把 hook 片段合进目标已有的（见第七节）
6. 追加 CLAUDE.md       标记块追加三拍章节（见第七节）
7. 追加 .gitignore      逐行加 task-loop 需要的行（去重）
8. 写 manifest          → .ai/.task-loop-manifest（见第八节）
9. 提示重启 cc          ⚠️ hook 会话级加载，不重启不生效
```

**原则**：install 永远只加不改不删用户已有的东西。所有改动通过"标记/合并/manifest"做到可识别、可逆。

## 六、uninstall.sh 流程

```text
1. 读 manifest          .ai/.task-loop-manifest 不存在 → 安静退出（幂等）
2. 删 manifest 记录的文件   .claude/hooks/guardian.sh 等
3. 反向 settings.json    jq 移除 command 含 guardian.sh 的 PreToolUse 条目
4. 反向 CLAUDE.md        sed 删 <!-- task-loop:start --> 到 :end --> 整块
5. 反向 .gitignore       删 task-loop 加过的行
6. 保留 .ai/memory/      用户知识数据，绝不删
7. 删 manifest + 提示重启 cc
```

可选清理：删空的 `.claude/hooks`、`.claude/scripts` 等目录（仅当目录内无其他文件）。

## 七、冲突合并细节

### 7.1 settings.json —— jq 合并

`src/settings-hook.json`（task-loop 要塞的唯一内容）：
```json
{ "hooks": { "PreToolUse": [{
    "matcher": "Write|Edit|NotebookEdit|Bash",
    "hooks": [{ "type": "command", "command": "bash .claude/hooks/guardian.sh" }]
}] } }
```

install 合并（目标已有 settings.json）：用 jq 把 task-loop 的 PreToolUse 条目追加到目标的 `hooks.PreToolUse` 数组，**按 command 去重**——目标已有 command 含 `guardian.sh` 的条目则跳过。目标的其他配置（permissions、其他 hooks）原样保留。

合并 jq 骨架：
```bash
jq --slurpfile hook src/settings-hook.json '
  ($hook[0].hooks.PreToolUse // []) as $add |
  if (.hooks.PreToolUse // [] | map(.hooks[].command) | any(test("guardian.sh")))
  then .  # 已有 guardian，跳过
  else .hooks.PreToolUse = ((.hooks.PreToolUse // []) + $add) end
' target/.claude/settings.json
```

uninstall 反向：
```bash
jq '.hooks.PreToolUse |= map(select(.hooks[].command | test("guardian.sh") | not))' \
  target/.claude/settings.json
```

目标无 settings.json → 直接拷 hook 片段为 settings.json。
目标 settings.json 非 JSON → 报错退出，绝不覆盖。

### 7.2 CLAUDE.md —— 标记块追加

`src/claudemd-section.md` 内容用固定标记包裹：
```markdown
<!-- task-loop:start -->
# 任务闭环系统 (Task Loop)
…三拍规则、被拦怎么办…
<!-- task-loop:end -->
```

install：检测目标 CLAUDE.md 是否已有 `<!-- task-loop:start -->`，有则跳过（幂等）；无则追加整块到末尾。目标无 CLAUDE.md → 新建。

uninstall：`sed '/<!-- task-loop:start -->/,/<!-- task-loop:end -->/d'` 删整块（含标记），用户原内容不动。

### 7.3 .gitignore —— 追加 task-loop 需要的行

`src/gitignore-lines.txt`：
```
.ai/task.json
.ai/.task-loop-manifest
.ai/memory/draft/*
!.ai/memory/draft/.gitkeep
.ai/memory/active/*
!.ai/memory/active/.gitkeep
```
逐行加到目标 `.gitignore`（已有则跳过）。目标无 `.gitignore` → 新建。uninstall 反向删这些行。

### 7.4 冲突边界（install 自我保护）

| 情况 | 处理 |
|---|---|
| `.ai/.task-loop-manifest` 已存在 | 报错"已装"，要求先 uninstall，不重复装 |
| 目标 settings.json 非合法 JSON | 报错退出，绝不覆盖 |
| 目标 settings.json 已有 guardian hook | 跳过合并 |
| CLAUDE.md 已有 task-loop 标记 | 跳过追加 |
| 目标不是 git 仓库 | 照装，.gitignore 照建（不强制 git） |

## 八、manifest 格式

`.ai/.task-loop-manifest`（JSON），uninstall 的反向依据：

```json
{
  "version": "1.0",
  "installed_at": "2026-06-17T12:00:00",
  "task_loop_version": "1.0",
  "files": [
    ".claude/hooks/guardian.sh",
    ".claude/scripts/lib-state.sh",
    ".claude/scripts/task-lock.sh",
    ".claude/scripts/task-build.sh",
    ".claude/scripts/task-close.sh",
    ".claude/scripts/task-extend.sh",
    ".claude/commands/lock.md",
    ".claude/commands/build.md",
    ".claude/commands/close.md",
    ".claude/commands/extend.md"
  ],
  "merged_settings_json": true,
  "appended_claudemd": true,
  "appended_gitignore": true
}
```

`files` 列出所有由 install 拷贝的文件（uninstall 逐个删）；三个布尔标记记录是否改了 settings.json/CLAUDE.md/.gitignore（uninstall 据此决定是否反向）。

## 九、测试策略

install/uninstall 操作文件系统，测试用 `mktemp -d` 建临时"假项目"隔离跑，纯 bash 断言（复用 task-loop 的 test-helpers 风格）。

```
install 矩阵:
  · 空目录(无 settings.json/CLAUDE.md) → 正确创建所有文件 + manifest
  · 已有用户配置目录 → settings.json 合并保留用户 hook、CLAUDE.md 标记追加
  · 已装目录(manifest 在) → 报错退出，不重复装
  · settings.json 损坏(非 JSON) → 报错退出，不覆盖

uninstall:
  · 装完再卸 → 文件删干净、settings.json/CLAUDE.md 恢复原样、.ai/memory/ 保留
  · 卸完再卸 → 幂等(无 manifest 安静退出)

合并正确性:
  · jq 合并不丢用户已有 PreToolUse 条目
  · 重复合并不重复加 guardian hook(幂等)
  · sed 标记块删除精确(只删 start~end，不动用户内容)
```

端到端（手工，不自动化）：装到真 cc 项目，重启会话，实际写代码验证 guardian 拦截。

## 十、依赖

```
jq     settings.json 合并必需 — install.sh 第一步检查，缺则报错 + 给安装命令
bash   脚本本身 — Windows 需 Git Bash
不依赖 git/fzf/python/网络 — 装的过程纯本地拷贝+合并
```

## 十一、已知坑（必须写进 README + install/uninstall 输出）

### ① cc 的 hook 是会话级加载的——最大"装了没反应"坑

```
install.sh 跑完 → 当前已开的 cc 会话不会激活 guardian
                 → 必须退出重开 cc，新会话才加载 settings.json 的 hook
uninstall.sh 跑完 → 当前会话的 guardian 仍在跑(若已激活)
                 → 同样要重启 cc 才真正卸下
```

install/uninstall 脚本末尾必须打印醒目提示：「⚠️ 请重启 Claude Code 会话使变更生效」。**不自动重启**（会杀掉用户当前会话），只提示。

### ② codex 硬拦截不可用
v1 只服务 cc。install 检测到 codex 项目（有 `AGENTS.md` 无 `.claude/`）时提示「硬拦截仅 cc 支持，codex 将不拦截」，不阻塞安装（脚本/命令仍可用，只是没 guardian）。

### ③ jq 是硬依赖
没有它 settings.json 合并做不了，install 直接拒装。

## 十二、与 team-systematic-docs 的关系（抽离）

task-loop 抽到独立仓库后，`team-systematic-docs` **退回纯文档仓库**：

```
保留:
  00-19 号文档（企业级团队 AI 开发范式）
  docs/superpowers/specs/2026-06-17-task-loop-design.md        ← 系统本体设计存档
  docs/superpowers/specs/2026-06-17-task-loop-distribution-design.md  ← 本设计
  docs/superpowers/plans/2026-06-17-task-loop.md               ← 实现计划存档

移除(已抽到 task-loop 仓库):
  .claude/  (hooks/scripts/commands/settings.json)
  .ai/      (task.json 运行时 + memory)
  CLAUDE.md (三拍章节)
  README-task-loop.md
  tests/    (task-loop 本体的测试，随系统迁走)
```

team-systematic-docs 不再承载可运行的 task-loop 系统，只保留设计文档。系统的唯一可运行来源是 `task-loop` 仓库。

## 十三、v1 范围边界

本设计覆盖：独立仓库 + install.sh + uninstall.sh + manifest + 智能合并 + 测试 + README。

明确留后（不在 v1）：
- codex 硬拦截适配（工具能力限制，需另想机制）
- 用户级/全局安装
- 自动更新与版本迁移
- 单文件 bootstrap / 远程托管
- install 后自动重启 cc（只提示）
