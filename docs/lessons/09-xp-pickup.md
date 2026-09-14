# Lesson 09：拾取经验球并增加 XP

## 本课目标

在 Lesson 08 的“Enemy 死亡后留下 ExperienceGem”基础上，完成最小拾取闭环：Player 身体接触经验球后，经验球消失，Player 的 `experience` 增加。

本课不做 HUD、升级阈值、升级三选一、经验球吸附或 GameManager，只把“掉落 → 拾取 → XP 增长”这条数据链学透。

## 本课只新增三个东西

1. Group：给 Player 一个语义标签 `player`；
2. Player 运行时状态：`experience` 与 `add_experience(amount)`；
3. `call_deferred()`：在物理查询期间需要延后修改物理世界时，等安全时机再执行。

## 先把前面的课接起来

```text
Lesson 07：Projectile 已经用 Area2D.body_entered 检测 Enemy
Lesson 08：Enemy 死亡后生成 ExperienceGem
Lesson 09：ExperienceGem 也用 Area2D.body_entered 检测 Player
```

也就是说，这一课不是重新学一套 Signal，而是把已经会的内置 Signal 用到新的游戏语义上。
## 第一步：Player 持有自己的 XP

在 `player.gd` 中加入：

```gdscript
var experience: int = 0

func add_experience(amount: int) -> void:
    experience += amount
```

这里要分清“状态”和“参数”：

```text
experience = Player 当前持有多少经验
amount     = 这一次外部调用要增加多少经验
```

因此经验来源不需要直接修改 Player 内部变量，只要调用：

```gdscript
player.add_experience(1)
```

以后即使出现价值 5 点、20 点的经验球，Player 的保存逻辑也不需要改变。

## 第二步：用 Group 标记 Player

在 `Player.tscn` 根节点加入 `player` Group。Group 可以先理解成 Node 的“语义标签”。

```gdscript
body.is_in_group("player")
```

比通过具体 Scene 路径判断更适合表达“这个对象是不是玩家”。Scene Groups 和 Global Groups 在运行时都是同一种 Group；本课只需要 Scene 自己使用的 `player` 标签，不必提前做项目级组名管理。
## 第三步：ExperienceGem 变成 Area2D

Lesson 08 的经验球只需要“看得见”，所以普通 Node2D 就够了。Lesson 09 要检测 Player 是否进入它的范围，因此根节点升级为 `Area2D`，并增加 `CollisionShape2D`。

经验球脚本的核心是：

```gdscript
extends Area2D

@export var experience_value: int = 1

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("player"):
        return

    body.call("add_experience", experience_value)
    queue_free()
```

运行时数据流是：

```text
Player 进入 ExperienceGem
→ Godot 发出 body_entered(Player)
→ callback 的 body 接到 Player
→ player Group 判断通过
→ add_experience(1)
→ Gem queue_free()
```

`connect()` 仍然只是注册 callback；真正触发 callback 的是之后发生的物理重叠事件。
## 为什么这里用 `body.call()`

callback 把参数写成：

```gdscript
func _on_body_entered(body: Node2D) -> void:
```

静态类型系统只知道它是 `Node2D`，而 `Node2D` 官方 API 里没有我们自定义的 `add_experience()`。运行时它实际是 Player，所以这里使用：

```gdscript
body.call("add_experience", experience_value)
```

这是在当前课程阶段避免提前引入 `class_name Player` 的最小方案。

## 一个真实踩到的坑：Physics flushing queries

把 ExperienceGem 从普通 Node2D 升级成 Area2D 后，第一次 F5 出现了：

```text
Can't change this state while flushing queries.
Use call_deferred() or set_deferred()...
```

调用链是：

```text
Projectile.body_entered
→ Enemy.take_damage()
→ died.emit(self)
→ EnemySpawner._on_enemy_died()
→ add_child(ExperienceGem Area2D)
```

此时 PhysicsServer 还在处理碰撞查询，立刻把新的 Area2D 注册进物理世界并不安全。
修正后的 Spawner 是：

```gdscript
func _on_enemy_died(dead_enemy: Node2D) -> void:
    call_deferred("_spawn_experience", dead_enemy.global_position)

func _spawn_experience(spawn_position: Vector2) -> void:
    var experience := experience_scene.instantiate() as Node2D
    get_parent().add_child(experience)
    experience.global_position = spawn_position
```

这里有两个关键点：

1. `call_deferred()` 不是“不执行”，而是等当前物理查询结束后再执行；
2. 延迟前先把 `dead_enemy.global_position` 复制成 `Vector2`，不要把马上会 `queue_free()` 的 Enemy 对象引用跨到延迟阶段。

更精确地说，Enemy 被释放后对象引用会变成无效实例，而不是 C/C++ 风格的可随意解引用裸指针。因此跨延迟边界时，优先传稳定的数据值。

## 运行检查

按 `F5`，你应该能看到：

- Enemy 死亡后仍然正常留下 ExperienceGem；
- Player 身体碰到 Gem 后，Gem 立即消失；
- 每颗普通 Gem 增加 1 点 XP；
- 连续拾取时经验按 `1 → 2 → 3...` 增长；
- Debugger 不再出现 `flushing queries` 错误。

本课最终代码不保留临时 `print("Player XP")`，XP 增长由自动测试验证；HUD 会在后续课程再加入。
## 学习检查

能用自己的话回答即可：

1. `body_entered` callback 里的 `body` 参数是谁传进来的？
2. Group 相比直接判断某个 `.tscn` 路径，解决了什么问题？
3. 为什么 `experience_value` 放在 Gem 上，而 `experience` 放在 Player 上？
4. 为什么 ExperienceGem 变成 Area2D 后，Enemy 死亡时不能继续同步 `add_child()`？
5. 为什么 deferred 前先读取 `dead_enemy.global_position`，而不是把 `dead_enemy` 留到延迟方法里再读？

## Checkpoint

完成本课后，对应 Git Tag：

```text
lesson-09-xp-pickup
```

下一步将继续围绕经验系统构建升级条件，而不是在这一课提前加入 HUD 或复杂升级 UI。
