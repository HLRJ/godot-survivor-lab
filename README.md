# Godot Survivor Lab

> 零基础“邪修” Godot：不先学完整引擎，先从一个能玩的 Survivor-like 开始。

这个项目的第一目标是帮助我自己快速上手 Godot；第二目标是把真实走通的学习路径整理成其他新手也能跟的中文教程。

## 从这里开始

- 完全没用过 Godot：从 [Lesson 00：准备环境](docs/lessons/00-environment.md) 开始。
- 已经能打开并运行项目：进入 [Lesson 01：第一个 Scene](docs/lessons/01-first-scene.md)。
- 已理解 Scene / Node：进入 [Lesson 02：玩家移动](docs/lessons/02-player-movement.md)。
- 已会控制 Player 移动：进入 [Lesson 03：碰撞](docs/lessons/03-collision.md)。
- 已理解碰撞：进入 [Lesson 04：Enemy 追踪 Player](docs/lessons/04-enemy-chase.md)。
- 已理解 Enemy 追踪：进入 [Lesson 05：不断刷怪](docs/lessons/05-enemy-spawning.md)。
- 已理解不断刷怪：进入 [Lesson 06：自动攻击](docs/lessons/06-auto-attack.md)。
- 已理解自动攻击：进入 [Lesson 07：伤害与死亡](docs/lessons/07-damage-and-death.md)。
- 已理解伤害与死亡：进入 [Lesson 08：经验掉落](docs/lessons/08-xp-drop.md)。
- 已理解经验掉落：进入 [Lesson 09：拾取经验](docs/lessons/09-xp-pickup.md)。
- 已理解经验拾取：进入 [Lesson 10：升级三选一](docs/lessons/10-level-up-choice.md)。
- 想查概念：只看当前 Lesson 链接到的 `docs/concepts/` 页面，不提前背 API。

## 学习原则

- 先看到结果，再补概念。
- 每次只引入少量新东西，优先保持项目可运行。
- 每个新概念至少亲自运行一次、改一个值、先预测再验证。
- 每课先说明复用了哪些前置 Lesson，再讲本课真正新增的概念。
- 从 Lesson 07 起，每课至少亲手修改或补写一小段核心 GDScript，不只改 Inspector 参数。
- 卡住时优先使用 Git Checkpoint 对比，而不是删项目重来。

## First Playable 目标

1. WASD / 方向键移动。
2. 敌人持续生成并追踪玩家。
3. 玩家自动攻击。
4. 敌人受伤、死亡并掉落经验。
5. 拾取经验后升级三选一。
6. 玩家死亡后可以重新开始。

## 课程阶段

- Phase A：让东西动起来 —— Scene、Node、移动、碰撞、敌人、刷怪。
- Phase B：跑通核心循环 —— 自动攻击、伤害、经验、升级。
- Phase C：让它像个游戏 —— HUD、GameManager、死亡重开、基础手感。
- Phase D：把它交付出去 —— Windows 导出、Git/GitHub、CI。

详细课程设计见：`docs/superpowers/specs/2026-09-13-learning-first-course-design.md`。

## 技术栈

- Godot 4.7.2 stable
- GDScript
- 2D Pixel Art
- Git + GitHub
- Windows first

## 素材

学习阶段使用已随仓库提供的 Kenney CC0 素材，避免为了找图中断学习。第三方素材统一放在 `assets/third_party/`。

## 许可证

- 项目源码：MIT，见根目录 `LICENSE`。
- 原创教学文档：CC BY 4.0，见 `docs/LICENSE`。
- Kenney 第三方素材：CC0，详见 `LICENSES.md` 和各素材包自带的 `License.txt`。

## 当前进度

Lesson 10 已完成：经验达到阈值后会触发升级，战斗暂停并显示三选一；选择移动速度、攻击速度或 Projectile 伤害后，强化真实生效并恢复战斗。同时进一步理解了 Signal 的 connect/emit、Timer、SceneTree 暂停、运行时状态归属与 Main 协调层。
