# Godot Survivor Lab

> 零基础“邪修” Godot：不先学完整引擎，先从一个能玩的 Survivor-like 开始。

这个项目的第一目标是帮助我自己快速上手 Godot；第二目标是把真实走通的学习路径整理成其他新手也能跟的中文教程。

## 从这里开始

- 完全没用过 Godot：从 [Lesson 00：准备环境](docs/lessons/00-environment.md) 开始。
- 已经能打开并运行项目：进入 [Lesson 01：第一个 Scene](docs/lessons/01-first-scene.md)。
- 想查概念：只看当前 Lesson 链接到的 `docs/concepts/` 页面，不提前背 API。

## 学习原则

- 先看到结果，再补概念。
- 每次只引入少量新东西，优先保持项目可运行。
- 每个新概念至少亲自运行一次、改一个值、先预测再验证。
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

Lesson 01 已完成：已经理解 Scene / Node / Sprite2D，并把可复用的 Player Scene 放进主场景。下一步是 Lesson 02：WASD 玩家移动。
