# team-systematic-docs

纯文档仓库：企业级团队 AI 开发范式（`00-19` 号文档）+ task-loop 系统的设计存档（spec/plan）。

## 强关联仓库：task-loop（实现）

`D:\Mycase\task-loop` — GitHub: [MaybeJustLikeThis/task-loop](https://github.com/MaybeJustLikeThis/task-loop)

两者**高度强相关，跨仓库联动开发**：
- 本仓库是 task-loop 的**设计来源**（spec + plan）。
- task-loop 是 task-loop 系统的**唯一可运行实现来源**（`src/` 是唯一真相）。

### 设计存档位置（在本仓库 `docs/superpowers/`）

- `specs/2026-06-17-task-loop-design.md` — 系统本体设计（三拍/guardian/状态机）
- `specs/2026-06-17-task-loop-distribution-design.md` — 分发包设计（install/uninstall/合并）
- `plans/2026-06-17-task-loop.md` — 本体实现计划
- `plans/2026-06-17-task-loop-distribution.md` — 分发实现计划

## 联动开发约定

- **本仓库不再承载可运行的 task-loop 系统**（`.claude/` `.ai/` `CLAUDE.md` `README-task-loop.md` `tests/` 已抽走）。要看运行时代码去 `D:\Mycase\task-loop\src\`。
- **spec 是真相之源**：改设计先改本仓库 spec/plan，再同步到 task-loop 实现；task-loop 实现若产生语义变更，回写本仓库 spec/plan。两边不漂移。
- **跨仓库无需切会话**：Claude Code 的 Read/Write/Edit/Bash 用绝对路径可直接读写对方仓库。例如：
  - `Read D:\Mycase\task-loop\src\hooks\guardian.sh` — 看实现
  - `Bash: cd /d/Mycase/task-loop && bash tests/run-all.sh` — 验证 task-loop 实现
  - 在 task-loop 改了 src/ 后，本仓库 spec 若受影响，一并更新。

## 何时只在本仓库动

- 改团队范式文档（`00-19`）。
- 改 task-loop 的**设计**（spec/plan/状态机定义/拦截语义），不含具体 shell 实现。

改完本仓库若涉及 task-loop 实现，记得提示用户去 task-loop 仓库同步代码并跑测试。
