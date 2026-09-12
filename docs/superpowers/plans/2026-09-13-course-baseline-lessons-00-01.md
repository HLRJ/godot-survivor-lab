# Godot Survivor Lab 中文课程基线与 Lesson 00–01 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不拖慢个人学习的前提下，把现有 Godot 工程整理成中文学习型开源仓库，完成 Lesson 00、Lesson 01 两个可恢复 Checkpoint，并在公开前完成敏感信息与可运行性检查。

**Architecture:** 保持当前 Godot 工程简单可运行，教学内容围绕实际工程增量生成。`README.md` 只做课程入口，`docs/lessons/` 承载主线，`docs/concepts/` 只在概念首次出现时补充；Lesson 01 新增最小 `Player.tscn`，不写移动脚本，把 `CharacterBody2D` 留给 Lesson 02。

**Tech Stack:** Godot 4.7.2 stable、GDScript、Git、GitHub、Windows PowerShell、Kenney CC0 素材。

**Spec:** `docs/superpowers/specs/2026-09-13-learning-first-course-design.md`

## Global Constraints

- 第一目标是维护者本人快速学会 Godot，第二目标才是对外教学。
- 中文为 v1 主语言；Godot Node/API、GDScript 标识符、Git 命令保留官方英文名称。
- 每课目标 20–45 分钟，原则上不超过 3 个新核心概念。
- 每课结束必须是可运行工程，并创建永久 Lesson Checkpoint Tag。
- 新 Godot 概念必须保留“看见改动 → 运行 → 修改一个值 → 先预测再运行”的学习闭环。
- 不提前创建未来课程、百科式概念文档、GitHub Pages、复杂社区功能或重型测试框架。
- 公开前不得包含本机绝对路径、Token、API Key、`.env`、私钥或其他个人环境信息。

---

## 文件结构锁定

本计划只新增或修改以下文件：

- `README.md`：中文课程首页，只负责定位、学习入口、课程进度和快速开始。
- `LICENSE`：项目源码 MIT License。
- `docs/LICENSE`：原创教学文档 CC BY 4.0 授权说明。
- `LICENSES.md`：解释源码、文档、Kenney 第三方素材的许可证边界。
- `CONTRIBUTING.md`：精简中文贡献规则，不建设复杂社区流程。
- `docs/superpowers/specs/2026-09-12-godot-survivor-lab-design.md`：标记为旧设计并移除本地绝对路径/“private”旧状态。
- `docs/lessons/00-environment.md`：环境、打开、运行、恢复基线。
- `docs/lessons/01-first-scene.md`：创建/理解第一个可复用 Player Scene。
- `docs/concepts/scene-and-node.md`：Lesson 01 首次遇到的 Scene/Node 最小概念页。
- `scenes/player/Player.tscn`：Lesson 01 的最小玩家 Scene，仅包含 `Node2D + Sprite2D`。
- `scenes/main/Main.tscn`：实例化 Player，并将状态文本切换到 Lesson 01。

本计划不创建 `player.gd`；玩家移动属于下一份 Lesson 02 计划。

---

### Task 1: 建立中文课程首页与清晰许可证边界

**Files:**
- Modify: `README.md`
- Create: `LICENSE`
- Create: `docs/LICENSE`
- Modify: `LICENSES.md`
- Create: `CONTRIBUTING.md`
- Modify: `docs/superpowers/specs/2026-09-12-godot-survivor-lab-design.md`

**Interfaces:**
- Consumes: 已批准的中文课程设计规格。
- Produces: 后续 Lesson 文档可链接的统一课程入口和许可证边界。

- [ ] **Step 1: 重写 README 为中文学习入口**

README 第一屏必须直接说明：

```markdown
# Godot Survivor Lab

> 零基础“邪修” Godot：不先学完整引擎，先从一个能玩的 Survivor-like 开始。

这个项目的第一目标是帮助我自己快速上手 Godot；第二目标是把真实走通的学习路径整理成其他新手也能跟的中文教程。

## 从这里开始

- 完全没用过 Godot：从 [Lesson 00：准备环境](docs/lessons/00-environment.md) 开始。
- 已经能打开并运行项目：进入 [Lesson 01：第一个 Scene](docs/lessons/01-first-scene.md)。
- 想查概念：按课程遇到的链接进入 `docs/concepts/`，不要提前背 API。
```

README 后续仅保留：学习原则、First Playable 目标、课程阶段、技术栈、许可证入口；不加入徽章墙、路线图大图或未实现功能展示。

- [ ] **Step 2: 添加源码 MIT License**

根目录 `LICENSE` 使用标准 MIT 文本，版权行为：

```text
Copyright (c) 2026 HLRJ
```

- [ ] **Step 3: 添加教学文档 CC BY 4.0 授权说明**

`docs/LICENSE` 写明：`docs/` 下原创教学文档采用 Creative Commons Attribution 4.0 International（CC BY 4.0），允许复制、修改和再发布，但需要署名；第三方资料和素材按各自许可证处理。

- [ ] **Step 4: 重写 LICENSES.md 的边界说明**

必须明确三类：

```text
项目源码（Godot 场景、GDScript、配置）：MIT
原创教学文档（docs/）：CC BY 4.0
Kenney Roguelike Characters / Tiny Dungeon / Interface Sounds：CC0，保留各素材包自带 License.txt
```

不得把 Kenney 素材错误归入 MIT 或 CC BY。

- [ ] **Step 5: 添加精简 CONTRIBUTING.md**

只包含：中文优先、Issue 可报告课程错误/Godot 版本差异、PR 一次解决一个问题、不得提交无授权素材、不得为了“高级架构”破坏新手可读性。

- [ ] **Step 6: 清理旧设计中的公开冲突信息**

将 `docs/superpowers/specs/2026-09-12-godot-survivor-lab-design.md` 开头改为：

```markdown
> 此文档记录最初的个人学习 Demo 设计，已被 `2026-09-13-learning-first-course-design.md` 取代。保留仅用于设计演进记录。
```

删除其中 `G:/AINmg/Codes/godot-survivor-lab` 本地绝对路径，并将 GitHub 状态描述从“private”改为“不在本旧设计中约束仓库可见性”。

- [ ] **Step 7: 做文档与敏感信息静态检查**

在仓库根目录运行：

```powershell
git diff --check
git grep -n -I -E 'G:/AINmg|G:\\AINmg|C:\\Users\\|ghp_|github_pat_|API[_-]?KEY|TOKEN=' -- . ':!assets/third_party/**'
git ls-files | Select-String -Pattern '^\.env$|\.pem$|\.key$'
```

Expected：`git diff --check` 无错误；后两条无输出。

- [ ] **Step 8: 验证 Godot 基线仍可载入**

在仓库根目录运行：

```powershell
& 'D:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --editor --quit
$LASTEXITCODE
```

Expected：退出码 `0`。

- [ ] **Step 9: 提交课程基线**

```bash
git add README.md LICENSE docs/LICENSE LICENSES.md CONTRIBUTING.md docs/superpowers/specs/2026-09-12-godot-survivor-lab-design.md
git commit -m "docs: establish Chinese learning-first course baseline"
```

---

### Task 2: Lesson 00 — 环境、运行与恢复

**Files:**
- Create: `docs/lessons/00-environment.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: 可运行的 Milestone 0 Godot 工程。
- Produces: 新手可以从克隆/已有目录进入项目、成功运行并知道如何恢复到 Lesson 00 Checkpoint。

- [ ] **Step 1: 创建 Lesson 00 文档**

文档严格使用课程固定结构，并覆盖以下实际内容：

```markdown
# Lesson 00：准备环境——先把项目跑起来

## 本课目标
在 Godot 4.7.2 中打开项目并成功运行一次。

## 完成效果
看到 Godot Survivor Lab 的启动画面；关闭运行窗口后能回到编辑器。

## 本课只学这些
1. `project.godot` 是项目入口。
2. Godot 编辑器中的“运行项目”。
3. Git Checkpoint 是你的存档点。
```

“动手做”同时给两条路径：

1. 维护者已有目录：直接用 Godot Import/Open 选择 `project.godot`。
2. 新学习者：`git clone https://github.com/HLRJ/godot-survivor-lab.git` 后打开 `project.godot`。

运行检查必须写清：窗口分辨率约 1280×720、标题为 `Godot Survivor Lab`、页面出现项目基线文字。

“小实验”：把编辑器运行窗口关闭后再次点击 Run Project，先预测是否会丢失工程修改，再观察结果。

“学习检查”只问：`project.godot` 的作用、Run Project 与打开项目的区别、Checkpoint 为什么能降低“改坏工程”的心理成本。

- [ ] **Step 2: 从 README 链接 Lesson 00**

确认首页“从这里开始”中的路径准确为：

```text
docs/lessons/00-environment.md
```

- [ ] **Step 3: 从干净状态执行 Lesson 00 的技术验证**

```powershell
& 'D:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --editor --quit
$LASTEXITCODE
git diff --check
```

Expected：Godot 退出码 `0`，`git diff --check` 无错误。

- [ ] **Step 4: 提交并创建 Lesson 00 Checkpoint**

```bash
git add README.md docs/lessons/00-environment.md
git commit -m "docs: add lesson 00 environment walkthrough"
git tag -a lesson-00-environment -m "Lesson 00: environment ready"
```

执行分支推送后再推 Tag：

```bash
git push origin lesson-00-environment
```

---

### Task 3: Lesson 01 — 第一个可复用 Player Scene

**Files:**
- Create: `scenes/player/Player.tscn`
- Modify: `scenes/main/Main.tscn`
- Create: `docs/lessons/01-first-scene.md`
- Create: `docs/concepts/scene-and-node.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: Kenney `roguelikeChar_transparent.png`，16×16 tile、1 px margin。
- Produces: `Player.tscn`，供 Lesson 02 将根节点升级为 `CharacterBody2D` 并加入移动逻辑。

- [ ] **Step 1: 创建最小 Player.tscn**

使用下面的确定结构，不添加脚本或碰撞：

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://assets/third_party/kenney/roguelike-characters/Spritesheet/roguelikeChar_transparent.png" id="1_player_sheet"]

[sub_resource type="AtlasTexture" id="AtlasTexture_player"]
atlas = ExtResource("1_player_sheet")
region = Rect2(1, 1, 16, 16)

[node name="Player" type="Node2D"]

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = SubResource("AtlasTexture_player")
scale = Vector2(4, 4)
```

这里故意使用 `Node2D + Sprite2D`，不提前引入 `CharacterBody2D`。

- [ ] **Step 2: 在 Main.tscn 实例化 Player**

在文件顶部加入：

```ini
[ext_resource type="PackedScene" path="res://scenes/player/Player.tscn" id="1_player"]
```

在 `Main` 下加入：

```ini
[node name="Player" parent="." instance=ExtResource("1_player")]
position = Vector2(640, 360)
```

将状态文字从 `Milestone 0 - Project baseline` 改为：

```text
Lesson 01 - 第一个 Scene
```

并相应把 `Main.tscn` 的 `load_steps` 设置为正确值。

- [ ] **Step 3: 先验证资源和 Scene 能被 Godot 加载**

```powershell
& 'D:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --editor --quit
$LASTEXITCODE
```

Expected：退出码 `0`，无 missing resource / parse error。

- [ ] **Step 4: 维护者亲自运行并完成本课实验**

打开项目并点击 Run Project。Expected：屏幕中央出现一个放大 4 倍的像素角色。

然后维护者在 Inspector 中把 `Sprite2D.scale` 从 `(4, 4)` 改为 `(6, 6)`；修改前先预测角色会变大还是移动位置，再运行观察。确认理解后改回 `(4, 4)`。

这一步不得由自动化替代，因为它是本课的学习闭环。

- [ ] **Step 5: 创建 Scene/Node 最小概念页**

`docs/concepts/scene-and-node.md` 只解释：

- Node 是一个有职责的对象。
- Scene 是一棵可保存、可复用的 Node 树。
- `Player.tscn` 为什么可以被 `Main.tscn` 实例化。
- `Node2D` 与 `Sprite2D` 在本课分别负责什么。

不提前解释 `CharacterBody2D`、Signal、Resource。

- [ ] **Step 6: 创建 Lesson 01 文档**

核心内容必须围绕“自己做出 Player Scene → 放进 Main → 运行看到角色”展开。

本课三个核心概念固定为：`Scene`、`Node`、`Sprite2D`。

运行检查：角色在窗口中央可见，Main 仍能独立运行。

学习检查至少包含：

1. 为什么不把所有东西都直接塞进 `Main.tscn`？
2. `Player.tscn` 是 Scene 还是 Node？为什么两种说法在不同语境都可能出现？
3. `Sprite2D` 在当前 Player 中只负责什么？

Checkpoint 写为 `lesson-01-first-scene`。

- [ ] **Step 7: 更新 README 当前进度**

将“当前进度”更新为 Lesson 01 已完成，并把下一步明确为 Lesson 02：玩家移动。

- [ ] **Step 8: 验证、提交并创建 Lesson 01 Checkpoint**

```powershell
& 'D:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --editor --quit
$LASTEXITCODE
git diff --check
```

Expected：Godot 退出码 `0`，diff check 无错误。

然后：

```bash
git add scenes/player/Player.tscn scenes/main/Main.tscn docs/lessons/01-first-scene.md docs/concepts/scene-and-node.md README.md
git commit -m "feat: add lesson 01 first player scene"
git tag -a lesson-01-first-scene -m "Lesson 01: first reusable scene"
git push origin lesson-01-first-scene
```

---

### Task 4: 公开前安全检查并切换为开源仓库

**Files:**
- No required content change unless verification exposes a concrete problem.

**Interfaces:**
- Consumes: 已完成 Task 1–3 的仓库状态。
- Produces: 可公开访问、无本地敏感信息、默认分支可运行的中文教学仓库。

- [ ] **Step 1: 做完整敏感信息扫描**

```powershell
git grep -n -I -E 'G:/AINmg|G:\\AINmg|C:\\Users\\|ghp_|github_pat_|API[_-]?KEY|TOKEN=|PASSWORD=' -- . ':!assets/third_party/**'
git ls-files | Select-String -Pattern '^\.env$|\.env\.|\.pem$|\.key$|id_rsa|id_ed25519'
```

Expected：两条命令都无输出。若有输出，先删除具体敏感内容并以 `chore: remove local-only information before public release` 提交，再重新运行扫描直到无输出。

- [ ] **Step 2: 做公开前最终 Godot 与 Git 验证**

```powershell
& 'D:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --editor --quit
$godotExit = $LASTEXITCODE
git diff --check
$status = git status --porcelain
Write-Output "godot_exit=$godotExit"
Write-Output "git_status_count=$($status.Count)"
```

Expected：`godot_exit=0`，`git_status_count=0`。

- [ ] **Step 3: 验证两个 Lesson Tag 都在远端**

```bash
git ls-remote --tags origin lesson-00-environment lesson-01-first-scene
```

Expected：两个 Tag 都有远端 SHA。

- [ ] **Step 4: 将仓库切换为 Public**

```bash
gh repo edit HLRJ/godot-survivor-lab --visibility public --accept-visibility-change-consequences
```

- [ ] **Step 5: 验证公开状态**

```bash
gh repo view HLRJ/godot-survivor-lab --json nameWithOwner,visibility,url,defaultBranchRef
```

Expected：`visibility` 为 `PUBLIC`，默认分支为 `main`。

- [ ] **Step 6: 做陌生学习者入口检查**

在浏览器未登录 GitHub 的情况下打开仓库首页，确认无需权限即可看到 README；按 README 点击 Lesson 00、Lesson 01、`LICENSE`、`LICENSES.md` 均能到达正确文件。

如果以上入口全部正常，本计划完成。下一份独立计划从 `Lesson 02：玩家移动` 开始，不在本计划继续扩展。
