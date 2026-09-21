# Godot Survivor Lab 课程总览

> 这份文件回答三个问题：**每一课做什么、为什么现在学、以后做复杂游戏时哪里还会用到。**
>
> 真正动手时仍然进入 `docs/lessons/`；这里是课程地图，不替代 Lesson 正文。

## 怎么使用这份总览

课程不是按 Godot API 目录排列，而是按一个 Survivor-like 从无到有的真实问题排列：

```text
先出现东西
→ 让它动
→ 让世界有规则
→ 加入敌人和战斗
→ 建立奖励与成长
→ 数据化和系统化
→ 做成像游戏的完整循环
→ 最后交付出去
```

每一课都尽量遵守：

```text
上一课已经做到什么
→ 暴露出一个真实问题
→ 这一课学习一个新工具
→ 解决问题
→ 解释未来复杂游戏如何继续复用
```

---
## Phase A：先学会让东西动起来

### Lesson 00：准备环境 —— 先把项目跑起来【已完成】

**做出什么：** Godot 4.7.2 项目能够稳定打开、运行，并有 Git Checkpoint。

**为什么现在学：** 没有可靠环境，后面任何 Bug 都可能混杂“代码问题”和“环境问题”。

**核心知识：** `project.godot`、Godot Editor、项目运行、`.godot/`、Git 基线。

**以后会用到：** 引擎版本管理、资源导入、CI、团队环境一致性、问题复现。

**Checkpoint：** `lesson-00-environment`

### Lesson 01：第一个 Scene —— 把 Player 放到屏幕上【已完成】

**做出什么：** 第一个可见 Player Scene。

**为什么现在学：** 后续移动、碰撞、武器都需要一个真实对象作为载体。

**核心知识：** Scene、Node、Sprite2D、场景组合。

**以后会用到：** 角色、敌人、UI、关卡、武器、嵌套 Scene、组件复用。

**Checkpoint：** `lesson-01-first-scene`
### Lesson 02：玩家移动 —— WASD 控制 Player【已完成】

**做出什么：** Player 响应输入并进行物理移动。

**为什么现在学：** 静态对象还不是游戏，需要第一次连通“输入 → 状态 → 物理世界”。

**核心知识：** CharacterBody2D、Input Action、velocity、`move_and_slide()`。

**以后会用到：** 角色控制器、载具、AI 移动、冲刺、击退、网络同步。

**Checkpoint：** `lesson-02-player-movement`

### Lesson 03：第一次碰撞 —— Player 被墙挡住【已完成】

**做出什么：** Player 不能穿过 TrainingWall。

**为什么现在学：** 会移动以后马上需要世界边界和规则。

**核心知识：** CollisionShape2D、Collision Layer、Mask。

**以后会用到：** 地形、墙体、Hitbox/Hurtbox、机关、触发区域、拾取、子弹命中。

**Checkpoint：** `lesson-03-collision`
### Lesson 04：Enemy 追踪 —— 游戏自己开始行动【已完成】

**做出什么：** Enemy 自动追向 Player。

**为什么现在学：** 有玩家和场地后，需要第一个由游戏逻辑驱动的对象。

**核心知识：** Node 引用、Vector2 方向、`direction_to()`、物理移动。

**以后会用到：** AI Steering、锁定、导弹、宠物跟随、摄像机、目标选择。

**Checkpoint：** `lesson-04-enemy-chase`

### Lesson 05：不断刷怪 —— 从一个 Enemy 变成持续压力【已完成】

**做出什么：** Enemy 按时间持续生成。

**为什么现在学：** 一个敌人只是演示；Survivor-like 需要运行时不断制造压力。

**核心知识：** PackedScene、`instantiate()`、Timer、运行时生成。

**以后会用到：** 波次、子弹、掉落物、特效、随机房间、对象工厂。

**Checkpoint：** `lesson-05-enemy-spawning`

---
## Phase B：跑通 Survivor 核心循环

### Lesson 06：自动攻击 —— Player 开始反击【已完成】

**做出什么：** Weapon 周期寻找目标并发射 Projectile。

**为什么现在学：** 敌人已经持续追来，需要最小战斗能力。

**核心知识：** Timer、Projectile Scene、方向、持久控制器与一次性实例。

**以后会用到：** 武器冷却、技能、炮塔、法术、连射、Boss 弹幕。

**Checkpoint：** `lesson-06-auto-attack`

### Lesson 07：伤害与死亡 —— 攻击真正产生后果【已完成】

**做出什么：** Projectile 命中 Enemy，Enemy 扣血并死亡。

**为什么现在学：** 会飞的子弹如果没有伤害，只是视觉效果。

**核心知识：** Area2D、Signal、Health、`queue_free()`。

**以后会用到：** 伤害系统、护甲、Buff、Hitbox/Hurtbox、Boss 阶段、可破坏物。

**Checkpoint：** `lesson-07-damage-and-death`
### Lesson 08：经验掉落 —— 击杀开始产生奖励【已完成】

**做出什么：** Enemy 死亡后生成 ExperienceGem。

**为什么现在学：** 战斗需要进入“击杀 → 奖励 → 成长”的循环。

**核心知识：** 自定义 Signal、Scene 组合、死亡事件生成新对象。

**以后会用到：** Loot、金币、装备、死亡特效、任务奖励、积分。

**Checkpoint：** `lesson-08-xp-drop`

### Lesson 09：拾取经验 —— 奖励进入 Player 状态【已完成】

**做出什么：** Player 接触经验球获得 XP。

**为什么现在学：** 掉落物必须真正影响 Player，奖励循环才闭合。

**核心知识：** Area2D、Group、Player XP、`call_deferred()`、对象生命周期。

**以后会用到：** 拾取、背包、任务物品、交互、Physics Callback 安全修改 SceneTree。

**Checkpoint：** `lesson-09-xp-pickup`
### Lesson 10：升级三选一 —— XP 变成玩家决策【已完成】

**做出什么：** 达到经验阈值后暂停战斗，三选一强化并恢复游戏。

**为什么现在学：** XP 只是数字没有意义，需要转换成成长和选择。

**核心知识：** 自定义 Signal 完整数据流、SceneTree Pause、`PROCESS_MODE_WHEN_PAUSED`、Main 协调层、状态归属。

**以后会用到：** 天赋、技能选择、商店、暂停菜单、对话选择、模态 UI、游戏状态协调。

**Checkpoint：** `lesson-10-level-up-choice`

### Lesson 11：升级数据化 —— 从硬编码走向 Resource【当前】

**做出什么：** 不改 GDScript，只改 `.tres` 就能同时改变升级按钮文字与真实强化数值。

**为什么现在学：** Lesson 10 已经真实出现 UI 与行为代码重复写 `+40 / -0.1 / +1` 的数据散落问题。

**核心知识：** Resource、`.tres`、`class_name`、`@export` Resource、数据与行为分离。

**以后会用到：** 武器配置、技能、装备、敌人属性、Buff、Loot Table、角色配置、关卡参数和大量平衡数据。

**Checkpoint：** `lesson-11-upgrade-data`

---
## Phase C：从“能跑”变成“像游戏”

### Lesson 12：HUD —— 让重要状态可见【计划】

**做出什么：** 屏幕实时显示 HP、等级、XP 和局内时间。

**为什么现在学：** 系统已经有越来越多内部状态，玩家却看不见。

**核心知识：** Control、Label、ProgressBar、UI 数据刷新、显示层与游戏状态分离。

**以后会用到：** 血条、法力、任务追踪、Boss UI、弹药、冷却、Debug Overlay。

**Checkpoint：** `lesson-12-hud`

### Lesson 13：GameManager —— 集中协调真正的全局状态【计划】

**做出什么：** 局内时间、流程状态等跨 Scene 责任开始集中管理。

**为什么现在学：** 到这个阶段才真正出现“多个系统都需要知道”的全局职责。

**核心知识：** Autoload、全局生命周期、职责边界、Signal。

**以后会用到：** 场景切换、全局设置、Run State、关卡流程、音频管理、全局事件。

**Checkpoint：** `lesson-13-game-manager`
### Lesson 14：死亡与重开 —— 完成一局游戏的闭环【计划】

**做出什么：** Player 死亡 → Game Over → 一键重新开始。

**为什么现在学：** 一个只能开始不能结束或重来的项目，还不是完整游戏循环。

**核心知识：** 游戏状态、Scene Reload、Game Over UI、状态重置。

**以后会用到：** Checkpoint、关卡失败、复活、Retry、Run-based Roguelike 循环。

**Checkpoint：** `lesson-14-restart-loop`

### Lesson 15：游戏手感 —— 让正确的逻辑“感觉也正确”【计划】

**做出什么：** 命中、攻击和关键事件获得声音与视觉反馈。

**为什么现在学：** 功能正确不等于游戏好玩；反馈决定玩家是否感受到自己的行为。

**核心知识：** Audio、Hit Flash、基础特效、屏幕反馈。

**以后会用到：** Camera Shake、Particles、Animation、Juice、音效层、打击感。

**Checkpoint：** `lesson-15-game-feel`

---
## Phase D：把作品真正交付出去

### Lesson 16：导出 Windows EXE【计划】

**做出什么：** 得到脱离 Godot Editor 也能运行的 Windows 游戏。

**为什么现在学：** 作品只有能交给别人运行，才真正从“工程”变成“交付物”。

**核心知识：** Export Preset、资源打包、运行检查。

**以后会用到：** Steam/TapTap 构建、版本发布、平台打包、Release Pipeline。

**Checkpoint：** `lesson-16-windows-export`

### Lesson 17：Git / GitHub 实战【计划】

**做出什么：** 能自己 Branch、Commit、Diff、Tag、恢复错误修改。

**为什么现在学：** 前面已经真实使用了 Git，现在再总结，比一开始背命令更容易理解每个工具解决什么问题。

**核心知识：** Branch、Commit、Tag、Diff、恢复策略。

**以后会用到：** 所有长期软件/游戏项目、团队协作、实验分支、版本发布。

**Checkpoint：** `lesson-17-git-workflow`
### Lesson 18：GitHub Actions【计划】

**做出什么：** Push / PR 后自动用 Headless Godot 验证项目。

**为什么现在学：** 项目已经有足够多真实回归测试，自动化 CI 现在终于有实际价值。

**核心知识：** GitHub Actions、Workflow、Headless Test、自动质量门禁。

**以后会用到：** 自动测试、构建、发布、多人协作、跨平台验证。

**Checkpoint：** `lesson-18-ci`

---

## 课程设计的核心原则

不要为了“API 很重要”就提前学它，而要尽量等到：

```text
我已经遇到了一个真实问题
↓
旧方案开始暴露限制
↓
新概念正好解决它
↓
通过失败实验理解为什么
↓
再知道未来何时复用
```

因此课程中的“简单写法”不一定是错误写法。Lesson 10 先用字符串和硬编码跑通升级闭环，Lesson 11 再在真实数据重复出现后引入 Resource，正是这种渐进式设计。
