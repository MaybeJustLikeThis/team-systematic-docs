# task-loop 分发包实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 task-loop 系统做成独立可分发的 `task-loop` 仓库——`git clone` + `bash install.sh` 一键装到任意 cc 项目，`bash uninstall.sh` 干净卸载（保留 memory），智能合并不覆盖用户配置。

**Architecture:** 独立仓库 `task-loop`，`src/` 放要分发的系统文件（从 team-systematic-docs 现有实现拷），`install.sh`/`uninstall.sh` 是纯 shell 搬运工（用户直接 bash 跑，不经 cc）。install 用 jq 合并 settings.json、标记块追加 CLAUDE.md、写 manifest；uninstall 读 manifest 精确反向删。最后 team-systematic-docs 退回纯文档。

**Tech Stack:** Bash（Git Bash on Windows）、jq（settings.json 合并）、sed（CLAUDE.md 标记块）。测试纯 bash + mktemp 隔离。

**关联 spec:** `docs/superpowers/specs/2026-06-17-task-loop-distribution-design.md`

---

## 技术背景（实现者必读）

### 两个仓库
```
D:\Mycase\task-loop\              ← 新建的独立分发仓库（本计划的主体）
  install.sh / uninstall.sh / src/ / tests/ / README.md
D:\Mycase\team-systematic-docs\   ← 现有仓库，最后退回纯文档（Task 11）
  现有 .claude/ .ai/ CLAUDE.md tests/ 是 src/ 的来源
```
**Task 1-10 在 `task-loop` 仓库工作，Task 11 在 `team-systematic-docs` 工作。**

### 为什么 install/uninstall 是纯 shell 脚本（不经 cc）
guardian 激活后无 task.json 时拦所有写。如果 uninstall 走 cc 工具调用，guardian 会拦 uninstall 自己。所以 install/uninstall 必须是用户在终端直接 `bash install.sh` 跑的脚本，绕开 cc。

### jq 合并 settings.json（install）
把 task-loop 的 PreToolUse 条目追加到目标 settings.json 的 `hooks.PreToolUse`，按 command 含 `guardian.sh` 去重：
```bash
jq --slurpfile hook src/settings-hook.json '
  ($hook[0].hooks.PreToolUse // []) as $add |
  if (.hooks.PreToolUse // [] | map(.hooks[].command) | any(test("guardian.sh")))
  then . else .hooks.PreToolUse = ((.hooks.PreToolUse // []) + $add) end
' target/.claude/settings.json
```

### jq 反向 settings.json（uninstall）
移除 command 含 guardian.sh 的条目：
```bash
jq '.hooks.PreToolUse |= map(select(.hooks[].command | test("guardian.sh") | not))' \
  target/.claude/settings.json
```

### sed 删 CLAUDE.md 标记块（uninstall）
```bash
sed '/<!-- task-loop:start -->/,/<!-- task-loop:end -->/d' target/CLAUDE.md
```

### 测试隔离
install/uninstall 测试用 `mktemp -d` 建临时"假目标项目"，跑脚本后断言文件状态，不碰真实仓库。

### manifest
`.ai/.task-loop-manifest`（JSON），install 写、uninstall 读。字段见 spec 第八节。

---

## 文件结构总览（task-loop 仓库）

```text
task-loop/
  install.sh                      9 步安装流水线
  uninstall.sh                    反向卸载
  src/                            要分发到目标项目的内容
    hooks/guardian.sh             ← 从 team-systematic-docs 拷
    scripts/{lib-state,task-lock,task-build,task-close,task-extend}.sh
    commands/{lock,build,close,extend}.md
    settings-hook.json            ← Task 2 新建（hook 片段）
    claudemd-section.md           ← Task 2 新建（三拍章节，含标记）
    gitignore-lines.txt           ← Task 2 新建
  tests/
    test-helpers.sh               断言辅助（从 team-systematic-docs 拷 + 扩展）
    run-all.sh
    test-install.sh               install 测试
    test-uninstall.sh             uninstall 测试
  README.md
  LICENSE
```

---

## Task 1: 初始化 task-loop 仓库 + 从 team-systematic-docs 拷 src/

**仓库:** `D:\Mycase\task-loop`（新建）
**来源:** `D:\Mycase\team-systematic-docs`

- [ ] **Step 1: 建仓库骨架**

```bash
mkdir -p /d/Mycase/task-loop/src/hooks /d/Mycase/task-loop/src/scripts \
         /d/Mycase/task-loop/src/commands /d/Mycase/task-loop/tests
cd /d/Mycase/task-loop
git init
```

- [ ] **Step 2: 从 team-systematic-docs 拷现有实现到 src/**

```bash
TS=/d/Mycase/team-systematic-docs
cp "$TS/.claude/hooks/guardian.sh" src/hooks/
cp "$TS/.claude/scripts/lib-state.sh" "$TS/.claude/scripts/task-lock.sh" \
   "$TS/.claude/scripts/task-build.sh" "$TS/.claude/scripts/task-close.sh" \
   "$TS/.claude/scripts/task-extend.sh" src/scripts/
cp "$TS/.claude/commands/lock.md" "$TS/.claude/commands/build.md" \
   "$TS/.claude/commands/close.md" "$TS/.claude/commands/extend.md" src/commands/
```

- [ ] **Step 3: 拷测试框架基础（test-helpers + run-all）**

```bash
cp "$TS/tests/test-helpers.sh" tests/
cp "$TS/tests/run-all.sh" tests/
# run-all.sh 里排除 test-helpers.sh 的逻辑已含（team-systematic-docs 修过）
```

- [ ] **Step 4: 验证拷过来的 guardian + 脚本能跑（用 team-systematic-docs 的 fixture 思路快速验证）**

```bash
# guardian.sh 语法检查
bash -n src/hooks/guardian.sh && echo "guardian 语法 OK"
# 各脚本语法检查
for f in src/scripts/*.sh; do bash -n "$f" && echo "$f OK"; done
```
Expected: 全部 OK。

- [ ] **Step 5: 写 .gitignore + LICENSE + 初始 commit**

`/d/Mycase/task-loop/.gitignore`:
```gitignore
# 本仓库自身不分发运行时状态（开发期若本地测试产生的）
.ai/
```

```bash
cd /d/Mycase/task-loop
printf 'MIT\n' > LICENSE
git add .
git commit -m "feat: 初始化 task-loop 仓库，从 team-systematic-docs 拷 src/"
```

---

## Task 2: 分发片段文件（settings-hook / claudemd-section / gitignore-lines）

**Files:**
- Create: `src/settings-hook.json`
- Create: `src/claudemd-section.md`
- Create: `src/gitignore-lines.txt`

- [ ] **Step 1: 写 src/settings-hook.json**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|NotebookEdit|Bash",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/guardian.sh" }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: 写 src/claudemd-section.md（含 start/end 标记）**

从 `team-systematic-docs/CLAUDE.md` 取三拍章节内容，用标记包裹。完整内容：
```markdown

<!-- task-loop:start -->
# 任务闭环系统 (Task Loop)

本仓库启用单任务闭环。AI 的所有文件写入受 `.claude/hooks/guardian.sh` 守卫。

## 当前任务
状态文件：`.ai/task.json`（AI 只读，不可修改——改了会被 guardian 拦）。
若 `.ai/task.json` 不存在，说明没有活动任务，先让用户 `/lock <paths>`。

## 三拍
- **PLAN**：只能写 `.ai/plan/`（方案）和 `.ai/memory/draft/`（前置知识）。不动业务代码。
- **BUILD**：只能在 `allowed_paths`+`extra_grants` 范围内写代码。越界被拦时，告诉用户需要 `/extend <path>`。
- **CLOSE**：实现代码冻结，只能写知识候选和文档。

## 切换靠人发车
`/lock` → `/build --confirm` → `/close --tested --reviewed` → `/close`（收尾）。AI 不自行推进阶段。

## 知识
两次提交都写到 `.ai/memory/draft/`：PLAN 末写前置知识（为什么这么改），CLOSE 写后置知识（踩的坑、新决策）。AI 只写 draft，激活到 `active/` 由人决定。

## 被 guardian 拦了怎么办
读 stderr 的 GUARDIAN 提示，按提示行动（申请 /extend、或退回上阶段），不要反复重试相同动作。
<!-- task-loop:end -->
```

- [ ] **Step 3: 写 src/gitignore-lines.txt**

```
.ai/task.json
.ai/.task-loop-manifest
.ai/memory/draft/*
!.ai/memory/draft/.gitkeep
.ai/memory/active/*
!.ai/memory/active/.gitkeep
```

- [ ] **Step 4: 验证 JSON 合法 + commit**

```bash
jq empty src/settings-hook.json && echo "settings-hook.json 合法"
git add src/
git commit -m "feat: 分发片段(settings-hook/claudemd-section/gitignore-lines)"
```

---

## Task 3: manifest 读写库 + 测试

**Files:**
- Create: `tests/test-helpers.sh` 的扩展（加 install 测试辅助）—— 实际上新建 `tests/install-helpers.sh`
- Create: `src/manifest.sh`（manifest 读写函数，被 install/uninstall source）
- Create: `tests/test-manifest.sh`

- [ ] **Step 1: 写失败测试 tests/test-manifest.sh**

```bash
#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/test-helpers.sh
source src/manifest.sh

TMP=$(mktemp -d)
# 写 manifest
manifest_write "$TMP" "v1.0" ".claude/hooks/guardian.sh" ".claude/scripts/lib-state.sh"
assert_eq "$?" "0" "manifest_write 成功"
# 读回校验
assert_eq "$(jq -r '.version' "$TMP/.ai/.task-loop-manifest")" "v1.0" "version 正确"
assert_match "guardian.sh" "$(jq -rc '.files' "$TMP/.ai/.task-loop-manifest")" "files 含 guardian"
assert_eq "$(manifest_exists "$TMP")" "yes" "manifest_exists 检测到"
# 删 manifest
manifest_delete "$TMP"
assert_eq "$(manifest_exists "$TMP")" "no" "manifest_delete 后不存在"

rm -rf "$TMP"
summary
```

- [ ] **Step 2: 跑测试确认失败**

Run: `bash tests/test-manifest.sh`
Expected: FAIL（src/manifest.sh 不存在）。

- [ ] **Step 3: 实现 src/manifest.sh**

```bash
#!/usr/bin/env bash
# .ai/.task-loop-manifest 读写。install 写，uninstall 读。
# manifest 根目录由 $1 传入（目标项目根）。

manifest_path() { echo "$1/.ai/.task-loop-manifest"; }

manifest_exists() {  # root -> yes/no
  [ -f "$(manifest_path "$1")" ] && echo yes || echo no
}

manifest_write() {  # root version file1 file2 ...
  local root="$1" version="$2"; shift 2
  mkdir -p "$root/.ai"
  local files_json; files_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)
  jq -n --arg v "$version" --argjson files "$files_json" \
    '{version:$v, installed_at:now|todateiso8601, files:$files,
      merged_settings_json:false, appended_claudemd:false, appended_gitignore:false}' \
    > "$(manifest_path "$root")"
}

manifest_get() {  # root key -> 值
  jq -r ".$2 // empty" "$(manifest_path "$1")"
}

manifest_set_flag() {  # root key value
  local f; f="$(manifest_path "$1")"
  local tmp; tmp=$(mktemp)
  jq --arg k "$2" --argjson v "$3" '.[$k]=$v' "$f" > "$tmp" && mv "$tmp" "$f"
}

manifest_delete() { rm -f "$(manifest_path "$1")"; }
```

- [ ] **Step 4: 跑测试确认通过**

Run: `bash tests/test-manifest.sh`
Expected: 全部 PASS。

- [ ] **Step 5: Commit**

```bash
git add src/manifest.sh tests/test-manifest.sh
git commit -m "feat: manifest 读写库"
```

---

## Task 4: install.sh 核心——依赖检查 + 定位 + 已装检测 + 拷文件 + 写 manifest

**Files:**
- Create: `install.sh`
- Create: `tests/install-helpers.sh`（mktemp 假项目辅助）
- Create: `tests/test-install.sh`

- [ ] **Step 1: 写 tests/install-helpers.sh（mktemp 假项目 + 断言）**

```bash
#!/usr/bin/env bash
# install/uninstall 测试辅助：建临时假目标项目
source tests/test-helpers.sh

# 建一个空假项目，返回其路径
make_fake_project() {
  local d; d=$(mktemp -d)
  echo "$d"
}
# 在假项目里建一个带用户配置的 .claude/settings.json + CLAUDE.md
seed_user_config() {  # project_root
  local root="$1"
  mkdir -p "$root/.claude"
  cat > "$root/.claude/settings.json" <<'EOF'
{ "permissions": { "allow": ["Bash(git:*)"] },
  "hooks": { "PreToolUse": [{ "matcher":"Read", "hooks":[{"type":"command","command":"echo read"}] }] } }
EOF
  echo "# 用户原有 CLAUDE" > "$root/CLAUDE.md"
  echo "*.log" > "$root/.gitignore"
}
assert_file_exists() { [ -f "$1" ] && echo "  PASS: $1 存在" || echo "  FAIL: $1 不存在"; }
assert_file_contains() { grep -q "$2" "$1" && echo "  PASS: $1 含 $2" || echo "  FAIL: $1 不含 $2"; }
```

- [ ] **Step 2: 写失败测试 tests/test-install.sh（核心：拷文件 + manifest）**

```bash
#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/install-helpers.sh

ROOT=$(make_fake_project)
bash install.sh "$ROOT" 2>/dev/null
assert_eq "$?" "0" "install 到空项目成功"
# 核心文件拷到位
for f in .claude/hooks/guardian.sh .claude/scripts/lib-state.sh \
         .claude/scripts/task-lock.sh .claude/commands/lock.md; do
  assert_file_exists "$ROOT/$f"
done
# manifest 写了
assert_file_exists "$ROOT/.ai/.task-loop-manifest"
assert_match "guardian.sh" "$(jq -rc '.files' "$ROOT/.ai/.task-loop-manifest")"

rm -rf "$ROOT"
summary
```

- [ ] **Step 3: 跑测试确认失败**

Run: `bash tests/test-install.sh`
Expected: FAIL（install.sh 不存在）。

- [ ] **Step 4: 实现 install.sh（核心部分）**

```bash
#!/usr/bin/env bash
set -uo pipefail
# task-loop 安装脚本。用法: bash install.sh [target_project_root]
# 默认装到当前目录；给参数则装到该目录。

HERE="$(cd "$(dirname "$0")" && pwd)"          # task-loop 仓库根
TARGET="${1:-$PWD}"

# 1. 依赖检查
command -v jq >/dev/null 2>&1 || { echo "install: 缺 jq。Windows: scoop/winget install jq；macOS: brew install jq" >&2; exit 1; }
[ -d "$TARGET" ] || { echo "install: 目标不是目录: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

# 2. 拷贝来源
SRC="$HERE/src"

# 3. 已装检测
if [ -f "$TARGET/.ai/.task-loop-manifest" ]; then
  echo "install: 目标已装 task-loop（manifest 存在）。先 bash uninstall.sh 再装。" >&2
  exit 1
fi

# 4. 拷 src/ → 目标 .claude/
mkdir -p "$TARGET/.claude/hooks" "$TARGET/.claude/scripts" "$TARGET/.claude/commands"
cp "$SRC/hooks/"*.sh "$TARGET/.claude/hooks/"
cp "$SRC/scripts/"*.sh "$TARGET/.claude/scripts/"
cp "$SRC/commands/"*.md "$TARGET/.claude/commands/"

# 5-6. settings.json/CLAUDE.md/.gitignore 合并 —— Task 5/6 接入
# （占位：此处后续插入 merge_settings / append_claudemd / append_gitignore）

# 8. 写 manifest
source "$SRC/manifest.sh"
FILES=(
  .claude/hooks/guardian.sh
  .claude/scripts/lib-state.sh .claude/scripts/task-lock.sh
  .claude/scripts/task-build.sh .claude/scripts/task-close.sh .claude/scripts/task-extend.sh
  .claude/commands/lock.md .claude/commands/build.md
  .claude/commands/close.md .claude/commands/extend.md
)
manifest_write "$TARGET" "1.0" "${FILES[@]}"

# 9. 提示
echo "task-loop 已装到 $TARGET"
echo "⚠️  请重启 Claude Code 会话使 guardian hook 生效（cc 在会话启动时加载 hook）。"
```

注意：`source "$SRC/manifest.sh"` —— manifest.sh 在 src/ 下（Task 3 放的），分发时它不拷到目标（FILES 不含它），只被 install/uninstall source。

- [ ] **Step 5: 跑测试确认通过**

Run: `bash tests/test-install.sh`
Expected: 全部 PASS。

- [ ] **Step 6: Commit**

```bash
git add install.sh tests/install-helpers.sh tests/test-install.sh
git commit -m "feat: install.sh 核心(依赖检查/已装检测/拷文件/写manifest)"
```

---

## Task 5: install.sh —— settings.json jq 合并

**Files:**
- Modify: `install.sh`（接入合并逻辑）
- Modify: `tests/test-install.sh`（加合并断言）

- [ ] **Step 1: 追加测试（已有用户配置时合并保留）**

在 test-install.sh 的 `summary` 前加：
```bash
ROOT=$(make_fake_project)
seed_user_config "$ROOT"   # 已有 settings.json(含 Read hook) + CLAUDE.md + .gitignore
bash install.sh "$ROOT" 2>/dev/null
# settings.json: 保留用户 Read hook + 追加 guardian hook
assert_file_contains "$ROOT/.claude/settings.json" "Read"        # 用户 hook 还在
assert_file_contains "$ROOT/.claude/settings.json" "guardian.sh"  # task-loop hook 加了
assert_file_contains "$ROOT/.claude/settings.json" "permissions"  # 用户其他配置还在
rm -rf "$ROOT"
```

- [ ] **Step 2: 跑测试确认失败**

Run: `bash tests/test-install.sh`
Expected: 新增断言里 guardian.sh 那条 FAIL（还没合并），但 Read/permissions 可能 PASS（seed 写的）。

- [ ] **Step 3: 实现——在 install.sh 的"5-6 合并"占位处替换为 settings.json 合并**

把占位注释替换为：
```bash
# 5. 合并 settings.json（保留用户已有配置，追加 guardian hook）
merge_settings() {
  local target="$1/.claude/settings.json"
  if [ ! -f "$target" ]; then
    cp "$SRC/settings-hook.json" "$target"
  else
    jq empty "$target" 2>/dev/null || { echo "install: $target 不是合法 JSON，拒绝覆盖" >&2; exit 1; }
    local tmp; tmp=$(mktemp)
    jq --slurpfile hook "$SRC/settings-hook.json" '
      ($hook[0].hooks.PreToolUse // []) as $add |
      if (.hooks.PreToolUse // [] | map(.hooks[].command) | any(test("guardian.sh")))
      then . else .hooks.PreToolUse = ((.hooks.PreToolUse // []) + $add) end
    ' "$target" > "$tmp" && mv "$tmp" "$target"
  fi
  manifest_set_flag "$TARGET" merged_settings_json true
}
merge_settings "$TARGET"
```

- [ ] **Step 4: 跑测试确认通过**

Run: `bash tests/test-install.sh`
Expected: 全部 PASS。

- [ ] **Step 5: Commit**

```bash
git add install.sh tests/test-install.sh
git commit -m "feat: install.sh settings.json jq 合并(保留用户配置)"
```

---

## Task 6: install.sh —— CLAUDE.md 标记块 + .gitignore

**Files:**
- Modify: `install.sh`
- Modify: `tests/test-install.sh`

- [ ] **Step 1: 追加测试**

在 test-install.sh summary 前加：
```bash
ROOT=$(make_fake_project); seed_user_config "$ROOT"
bash install.sh "$ROOT" 2>/dev/null
# CLAUDE.md: 用户原内容 + task-loop 标记块
assert_file_contains "$ROOT/CLAUDE.md" "用户原有 CLAUDE"           # 用户内容在
assert_file_contains "$ROOT/CLAUDE.md" "<!-- task-loop:start -->"   # 标记块加了
assert_file_contains "$ROOT/CLAUDE.md" "三拍"                       # 章节内容在
# .gitignore: 追加 task-loop 行
assert_file_contains "$ROOT/.gitignore" "*.log"                     # 用户原行在
assert_file_contains "$ROOT/.gitignore" ".ai/task.json"             # task-loop 行加了
# 幂等: 再装一次(先模拟 manifest 不在 → 实际已装会拒, 这里测合并幂等用单独逻辑)
rm -rf "$ROOT"
```

- [ ] **Step 2: 跑测试确认失败**

Run: `bash tests/test-install.sh`
Expected: 标记块/三拍/.ai/task.json 断言 FAIL。

- [ ] **Step 3: 实现——在 install.sh 的 merge_settings 后追加**

```bash
# 6. 追加 CLAUDE.md 标记块
append_claudemd() {
  local target="$1/CLAUDE.md"
  if grep -q '<!-- task-loop:start -->' "$target" 2>/dev/null; then
    : # 已有标记，跳过（幂等）
  else
    { [ -f "$target" ] && cat "$target" || true; cat "$SRC/claudemd-section.md"; } > "$target.tmp" && mv "$target.tmp" "$target"
  fi
  manifest_set_flag "$TARGET" appended_claudemd true
}
append_claudemd "$TARGET"

# 7. 追加 .gitignore
append_gitignore() {
  local target="$1/.gitignore"
  touch "$target"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    grep -qxF -- "$line" "$target" || echo "$line" >> "$target"
  done < "$SRC/gitignore-lines.txt"
  manifest_set_flag "$TARGET" appended_gitignore true
}
append_gitignore "$TARGET"
```

- [ ] **Step 4: 跑测试确认通过**

Run: `bash tests/test-install.sh`
Expected: 全部 PASS。

- [ ] **Step 5: 跑全量**

Run: `bash tests/run-all.sh`
Expected: smoke + manifest + install 全过。

- [ ] **Step 6: Commit**

```bash
git add install.sh tests/test-install.sh
git commit -m "feat: install.sh CLAUDE.md 标记块追加 + .gitignore"
```

---

## Task 7: uninstall.sh —— 反向删文件 + manifest + 保留 memory

**Files:**
- Create: `uninstall.sh`
- Create: `tests/test-uninstall.sh`

- [ ] **Step 1: 写失败测试 tests/test-uninstall.sh**

```bash
#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/install-helpers.sh

ROOT=$(make_fake_project)
bash install.sh "$ROOT" >/dev/null 2>&1
# 制造一些用户 memory 数据（uninstall 必须保留）
mkdir -p "$ROOT/.ai/memory/active"
echo "珍贵知识" > "$ROOT/.ai/memory/active/MEM-001.md"

bash uninstall.sh "$ROOT" 2>/dev/null
assert_eq "$?" "0" "uninstall 成功"
# 装的文件删了
for f in .claude/hooks/guardian.sh .claude/scripts/lib-state.sh .claude/commands/lock.md; do
  [ ! -f "$ROOT/$f" ] && echo "  PASS: $f 已删" || echo "  FAIL: $f 没删"
done
# manifest 删了
[ ! -f "$ROOT/.ai/.task-loop-manifest" ] && echo "  PASS: manifest 已删" || echo "  FAIL: manifest 没删"
# memory 保留
assert_file_contains "$ROOT/.ai/memory/active/MEM-001.md" "珍贵知识"

rm -rf "$ROOT"
summary
```

- [ ] **Step 2: 跑测试确认失败**

Run: `bash tests/test-uninstall.sh`
Expected: FAIL（uninstall.sh 不存在）。

- [ ] **Step 3: 实现 uninstall.sh（核心：删文件 + manifest，保留 memory）**

```bash
#!/usr/bin/env bash
set -uo pipefail
# task-loop 卸载脚本。用法: bash uninstall.sh [target_project_root]
HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$PWD}"
[ -d "$TARGET" ] || { echo "uninstall: 目标不是目录: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
source "$HERE/src/manifest.sh"

MANIFEST="$(manifest_path "$TARGET")"
if [ ! -f "$MANIFEST" ]; then
  echo "uninstall: 未找到 manifest（$MANIFEST），可能没装过。安静退出。"
  exit 0
fi

# 2. 删 manifest 记录的文件
while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$TARGET/$f" ] && rm -f "$TARGET/$f"
done < <(jq -r '.files[]' "$MANIFEST")

# 5. 保留 .ai/memory —— 不动
# 7. 删 manifest（先读 flags，再删）
MERGED_SETTINGS=$(manifest_get "$TARGET" merged_settings_json)
APPENDED_CLAUDE=$(manifest_get "$TARGET" appended_claudemd)
APPENDED_GIT=$(manifest_get "$TARGET" appended_gitignore)
manifest_delete "$TARGET"

# 3-5. 反向 settings/CLAUDE/.gitignore —— Task 8 接入（占位）

# 可选清理空目录
for d in .claude/hooks .claude/scripts .claude/commands; do
  [ -d "$TARGET/$d" ] && [ -z "$(ls -A "$TARGET/$d" 2>/dev/null)" ] && rmdir "$TARGET/$d" 2>/dev/null || true
done

echo "task-loop 已从 $TARGET 卸载（.ai/memory 已保留）"
echo "⚠️  请重启 Claude Code 会话使卸载生效。"
```

- [ ] **Step 4: 跑测试确认通过**

Run: `bash tests/test-uninstall.sh`
Expected: 全部 PASS。

- [ ] **Step 5: Commit**

```bash
git add uninstall.sh tests/test-uninstall.sh
git commit -m "feat: uninstall.sh 反向删文件+manifest, 保留 memory"
```

---

## Task 8: uninstall.sh —— 反向 settings.json + CLAUDE.md + .gitignore

**Files:**
- Modify: `uninstall.sh`
- Modify: `tests/test-uninstall.sh`

- [ ] **Step 1: 追加测试**

在 test-uninstall.sh 的 memory 断言后、rm 前加：
```bash
# 反向后用户原配置恢复
assert_file_contains "$ROOT/.claude/settings.json" "Read"        # 用户 Read hook 回来了
! grep -q "guardian.sh" "$ROOT/.claude/settings.json" && echo "  PASS: guardian hook 已移除" || echo "  FAIL: guardian 没移除"
assert_file_contains "$ROOT/CLAUDE.md" "用户原有 CLAUDE"          # 用户内容在
! grep -q "task-loop:start" "$ROOT/CLAUDE.md" && echo "  PASS: 标记块已删" || echo "  FAIL: 标记块没删"
assert_file_contains "$ROOT/.gitignore" "*.log"                   # 用户 gitignore 行在
! grep -q ".ai/task.json" "$ROOT/.gitignore" && echo "  PASS: task-loop gitignore 行已删" || echo "  FAIL: 没删"
```

- [ ] **Step 2: 跑测试确认失败**

Run: `bash tests/test-uninstall.sh`
Expected: guardian 移除/标记块删除/gitignore 删除 断言 FAIL（还没反向合并）。

- [ ] **Step 3: 实现——在 uninstall.sh 的"3-5 反向"占位处替换**

```bash
# 3. 反向 settings.json（移除 guardian hook）
if [ "$MERGED_SETTINGS" = "true" ] && [ -f "$TARGET/.claude/settings.json" ]; then
  tmp=$(mktemp)
  jq '.hooks.PreToolUse |= map(select(.hooks[].command | test("guardian.sh") | not))' \
    "$TARGET/.claude/settings.json" > "$tmp" && mv "$tmp" "$TARGET/.claude/settings.json"
fi
# 4. 反向 CLAUDE.md（删标记块）
if [ "$APPENDED_CLAUDE" = "true" ] && [ -f "$TARGET/CLAUDE.md" ]; then
  sed '/<!-- task-loop:start -->/,/<!-- task-loop:end -->/d' "$TARGET/CLAUDE.md" > "$TARGET/CLAUDE.md.tmp" \
    && mv "$TARGET/CLAUDE.md.tmp" "$TARGET/CLAUDE.md"
fi
# 5. 反向 .gitignore（删 task-loop 加的行）
if [ "$APPENDED_GIT" = "true" ] && [ -f "$TARGET/.gitignore" ]; then
  tmp=$(mktemp)
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    grep -vxF -- "$line" "$TARGET/.gitignore" >> "$tmp" || true
  done < "$HERE/src/gitignore-lines.txt"
  mv "$tmp" "$TARGET/.gitignore"
fi
```

- [ ] **Step 4: 跑测试确认通过**

Run: `bash tests/test-uninstall.sh`
Expected: 全部 PASS。

- [ ] **Step 5: Commit**

```bash
git add uninstall.sh tests/test-uninstall.sh
git commit -m "feat: uninstall.sh 反向 settings/CLAUDE/.gitignore 合并"
```

---

## Task 9: 边界保护——损坏检测、幂等、重复装

**Files:**
- Modify: `tests/test-install.sh`
- Modify: `tests/test-uninstall.sh`

- [ ] **Step 1: 追加 install 边界测试**

test-install.sh summary 前加：
```bash
# 边界1: 已装 → 拒绝重复装
ROOT=$(make_fake_project)
bash install.sh "$ROOT" >/dev/null 2>&1
bash install.sh "$ROOT" 2>/dev/null; assert_eq "$?" "1" "已装时重复 install 拒绝"
rm -rf "$ROOT"
# 边界2: settings.json 损坏 → 拒绝、不覆盖
ROOT=$(make_fake_project); mkdir -p "$ROOT/.claude"
echo "{这不是 json" > "$ROOT/.claude/settings.json"
bash install.sh "$ROOT" 2>/dev/null; assert_eq "$?" "1" "损坏 settings.json 时拒绝"
assert_file_contains "$ROOT/.claude/settings.json" "这不是 json"  # 原文件没被覆盖
rm -rf "$ROOT"
```

- [ ] **Step 2: 追加 uninstall 幂等测试**

test-uninstall.sh summary 前加：
```bash
# 卸完再卸 → 幂等安静退出
ROOT=$(make_fake_project)
bash install.sh "$ROOT" >/dev/null 2>&1
bash uninstall.sh "$ROOT" >/dev/null 2>&1
bash uninstall.sh "$ROOT" 2>/dev/null; assert_eq "$?" "0" "重复 uninstall 幂等"
rm -rf "$ROOT"
```

- [ ] **Step 3: 跑全量**

Run: `bash tests/run-all.sh`
Expected: 全过。损坏检测那条 install.sh 已有 `jq empty` 保护（Task 5），应通过；若 FAIL 说明保护没覆盖，修 install.sh。

- [ ] **Step 4: Commit**

```bash
git add tests/
git commit -m "test: install/uninstall 边界(损坏/幂等/重复装)"
```

---

## Task 10: README + 端到端 + 重启提示验证

**Files:**
- Create: `README.md`
- Create: `tests/test-e2e.sh`

- [ ] **Step 1: 写 README.md**

```markdown
# task-loop

单任务闭环系统：AI 改代码前先锁定范围，PLAN/BUILD/CLOSE 三拍由人发车、guardian hook 守门硬拦截。Claude Code 原生。

## 安装（到你的 cc 项目）
```
git clone <task-loop 仓库>
cd /path/to/your-cc-project
bash /path/to/task-loop/install.sh
# ⚠️ 重启 Claude Code 会话使 guardian 生效
```

## 卸载（保留你的 .ai/memory 知识）
```
bash /path/to/task-loop/uninstall.sh   # 在你的项目根跑
# ⚠️ 重启 Claude Code 会话使卸载生效
```

## 用法（装好后在 cc 里）
`/lock <paths>` → `/build --confirm` → `/close --tested --reviewed` → `/close`
详见被装进你项目 CLAUDE.md 的"任务闭环系统"章节。

## 依赖
- jq（settings.json 合并）
- bash（Windows 需 Git Bash）

## 已知坑
- **cc 的 hook 会话级加载**：install/uninstall 后必须重启 cc 才生效。
- **codex 不支持硬拦截**：v1 只服务 cc。codex 项目装了能用脚本/命令，但 guardian 不拦截。
- 设计文档：见 spec。
```

- [ ] **Step 2: 写端到端测试 tests/test-e2e.sh**

```bash
#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/install-helpers.sh

ROOT=$(make_fake_project); seed_user_config "$ROOT"
# 完整: install → guardian 真能跑 → uninstall → 恢复
bash install.sh "$ROOT" >/dev/null 2>&1
assert_eq "$?" "0" "e2e: install"
# guardian 在装好的目标里能跑(构造 task.json 测一次拦截)
mkdir -p "$ROOT/.ai"
echo '{"stage":"PLAN","scope":{"allowed_paths":["src/x/"],"blocked_paths":[],"extra_grants":[]},"gate":{}}' > "$ROOT/.ai/task.json"
echo '{"tool_name":"Write","tool_input":{"file_path":"src/y/z.go"}}' \
  | bash "$ROOT/.claude/hooks/guardian.sh" >/dev/null 2>&1
assert_eq "$?" "2" "e2e: guardian 在目标项目拦越界写"
rm -f "$ROOT/.ai/task.json"
# uninstall 恢复
bash uninstall.sh "$ROOT" >/dev/null 2>&1
assert_eq "$?" "0" "e2e: uninstall"
assert_file_contains "$ROOT/.claude/settings.json" "Read"   # 用户配置恢复
rm -rf "$ROOT"
summary
```

- [ ] **Step 3: 跑端到端 + 全量**

Run: `bash tests/run-all.sh`
Expected: 全过（smoke + manifest + install + uninstall + e2e）。

- [ ] **Step 4: Commit**

```bash
git add README.md tests/test-e2e.sh
git commit -m "docs+test: README 与端到端验证"
```

---

## Task 11: team-systematic-docs 退回纯文档

**仓库:** `D:\Mycase\team-systematic-docs`（切回这个仓库操作）

- [ ] **Step 1: 确认 task-loop 仓库已完成 Task 1-10 且测试全过**

```bash
cd /d/Mycase/task-loop && bash tests/run-all.sh
```
Expected: 全过。若不过，先修 task-loop，不要动 team-systematic-docs。

- [ ] **Step 2: 切到 team-systematic-docs，删系统文件**

```bash
cd /d/Mycase/team-systematic-docs
git checkout docs/task-loop-dist-spec   # 或 master，看 spec 已合到哪
# 删系统文件（已抽到 task-loop 仓库）
git rm -r .claude .ai tests
git rm CLAUDE.md README-task-loop.md
```
**注意保留**：`docs/superpowers/`（spec + plan 存档）、`00-19` 号文档、`visuals/`（若要留）。

- [ ] **Step 3: 验证 team-systematic-docs 仍是合法文档仓库**

```bash
ls docs/superpowers/specs/ docs/superpowers/plans/   # 设计存档在
ls 00-executive-summary.md                            # 文档在
git status                                            # 只有删除记录
```

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: team-systematic-docs 退回纯文档，task-loop 系统已抽到独立仓库"
```

---

## 完成标准

- [ ] `task-loop` 仓库：`bash tests/run-all.sh` 全绿（manifest + install + uninstall + e2e + smoke）
- [ ] `task-loop` 仓库：`install.sh` / `uninstall.sh` 能在临时项目完整装/卸，智能合并不丢用户配置
- [ ] `team-systematic-docs`：系统文件已删，保留设计存档 + 00-19 文档
- [ ] 手工验证：在一个真实空目录 `git init` + `bash task-loop/install.sh` + 重启 cc，确认 guardian 真激活（写文件被拦）
