# Lesson 09：经验球拾取与经验值增长——设计

## 1. 本课目标

在 Lesson 08 的“Enemy 死亡后留下 ExperienceGem”基础上，完成最小拾取闭环：Player 身体接触经验球时，经验球消失，Player 的经验值增加 1。

本课继续坚持学习优先，不加入经验条、升级阈值、升级三选一、吸附磁铁或 GameManager；这些能力留给后续课程。

## 2. 前置知识与新增概念

复用：

- Lesson 03：Collision Layer / Mask 与碰撞形状。
- Lesson 05：Scene 实例与节点树。
- Lesson 07：`Area2D.body_entered` 内置 Signal。
- Lesson 08：ExperienceGem Scene、Signal 调用链和 `queue_free()` 生命周期。

本课真正新增：

1. Group：用语义标签识别 Player，而不是依赖 Scene 文件路径。
2. Player 运行时经验状态：`experience` 与 `add_experience(amount)`。
3. 拾取数据流：Area2D 检测 Player → 增加 XP → Gem 自己销毁。
## 3. 方案选择

采用“ExperienceGem 自己检测 Player”的最小方案。

`ExperienceGem` 根节点从 `Node2D` 改为 `Area2D`，增加 `CollisionShape2D` 和脚本；Player 加入 `player` Group。经验球在 `_ready()` 连接自己的 `body_entered`，只对 `body.is_in_group("player")` 的对象响应。

不采用 Player 额外增加 PickupArea2D 的方案，因为那会提前引入拾取半径和额外节点；也不让 Main/GameManager 管理拾取，因为当前没有全局协调需求。

## 4. 运行时数据流

```text
Player 接触 ExperienceGem
        ↓
ExperienceGem.body_entered
        ↓
_on_body_entered(body)
        ↓
body.is_in_group("player")
        ↓ yes
body.add_experience(1)
        ↓
Player.experience: 0 → 1
        ↓
ExperienceGem.queue_free()
```

Player 持有经验状态，因为当前 XP 是 Player 自身局内状态；ExperienceGem 只负责“我值多少经验、谁碰到我时如何交付并消失”。
## 5. Scene 与脚本变化

`Player.tscn`：

- 根节点加入 `player` Group。
- 不新增 Area2D，不改变现有身体碰撞尺寸。

`player.gd`：

```gdscript
var experience: int = 0

func add_experience(amount: int) -> void:
    experience += amount
```

`ExperienceGem.tscn`：

- 根节点改为 `Area2D`。
- 保留现有 Sprite2D 视觉。
- 新增 `CollisionShape2D`，大小与可见宝石大致匹配。
- 设置碰撞层/遮罩，只需要检测 Player 所在 Layer 1。
- 挂载 `experience_gem.gd`。

`experience_gem.gd`：负责连接 `body_entered`、识别 `player` Group、调用 `add_experience()` 并 `queue_free()`。
## 6. 教学流程

这节课继续使用“先搭低认知脚手架，再由学习者亲手补核心链路”的方式。

1. 先解释为什么 ExperienceGem 要从 `Node2D` 变成 `Area2D`。
2. 对照 Lesson 07：Projectile 的 `Area2D.body_entered` 是命中；Lesson 09 同一个内置 Signal 用来做拾取。
3. 学习者亲手给 Player 增加 `experience` 与 `add_experience(amount)`。
4. 学习者亲手写 ExperienceGem 的 `body_entered.connect(...)` 和 callback 核心逻辑。
5. 运行前预测：碰到宝石后，宝石是否消失、XP 是否只加一次。
6. F5 验证，并在 Godot Output 暂时打印 XP 变化；理解后移除调试输出。
7. 学习检查重点回答：Group 解决了什么、`body` 参数从哪里来、为什么先加 XP 再 `queue_free()`。

## 7. 可见成功标准

- Enemy 仍会死亡并掉落 ExperienceGem。
- Player 身体接触 ExperienceGem 后，Gem 消失。
- 每颗 Gem 只增加 1 点 Player XP。
- 非 Player 的 PhysicsBody 接触 Gem 不会获得经验，也不会让 Gem 消失。
- 本课不显示 HUD；经验增长通过测试和临时 Output 验证。

## 8. 自动验证

新增 `tests/lesson_09_xp_pickup_test.gd`，至少验证：

- Player 属于 `player` Group。
- Player 初始 `experience == 0`。
- `add_experience(1)` 后经验变成 1。
- ExperienceGem 根节点是 `Area2D`，包含 `CollisionShape2D` 与脚本。
- Player 与 Gem 重叠后，Player XP 增加 1，Gem 离开 Scene Tree。
- Lesson 02～08 回归继续通过，Main headless 正常运行。

Checkpoint Tag：`lesson-09-xp-pickup`。