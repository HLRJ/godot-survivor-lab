# Lesson 07：让 Projectile 真正打伤 Enemy

## 本课目标

把 Lesson 06 的“Projectile 会自动飞向 Enemy”升级成真正的战斗闭环：命中、掉血、死亡。

完成后 Enemy 默认需要被 Projectile 命中 3 次才会消失。

## 本课只学三个东西

1. `Area2D`：检测 PhysicsBody 进入范围；
2. Signal：让“命中发生”变成一个事件通知；
3. Health：保存生命值，并在归零时死亡。

本课不做经验掉落，Lesson 08 再处理。

## 先把前面的课接起来

Lesson 07 不是突然新写一套战斗代码，而是在前面已经完成的结构上继续长一层：

```text
Lesson 02：Player 用 velocity + move_and_slide() 移动
Lesson 04：Enemy 用 direction_to() 找到 Player 的方向
Lesson 05：EnemySpawner 用 PackedScene + instantiate() 生成 Enemy
Lesson 06：Weapon 用同样的 instantiate() 生成 Projectile，Projectile 按 direction 飞行
Lesson 07：保留以上全部逻辑，只给 Projectile 增加“命中检测”，给 Enemy 增加“生命值”
```

所以本课真正新增的只有 `Area2D`、`Signal`、`Health`；`direction_to()`、`instantiate()`、Scene 复用、`@export` 都是在复用旧知识。

## Projectile 结构发生了什么变化

Lesson 06：

```text
Projectile (Node2D)
└── Sprite2D
```

Lesson 07：

```text
Projectile (Area2D)
├── Sprite2D
└── CollisionShape2D
```
变化的关键不是“换个节点名字”，而是 Projectile 现在能监听身体进入自己的检测区域。

## 关键代码变化：从“会飞”到“能打中”

Lesson 06 的 Projectile 只有移动：

```gdscript
extends Node2D

func _physics_process(delta: float) -> void:
    position += direction * speed * delta
```

Lesson 07 没有推翻这段代码，而是在它外面增加“检测命中”的能力：

```gdscript
extends Area2D

@export var damage: int = 1

func _ready() -> void:
    body_entered.connect(_on_body_entered)
```

注意：`_physics_process()` 里的飞行公式仍然完全保留。这就是课程的衔接方式：旧能力继续存在，新能力叠加上去。

## 命中链路

Projectile 在 `_ready()` 中连接：

```gdscript
body_entered.connect(_on_body_entered)
```

当 Enemy 进入 Projectile 的 Area2D 时，会调用：

```gdscript
func _on_body_entered(body: Node2D) -> void:
```

确认这个 body 是 Enemy 后：

```gdscript
body.call("take_damage", damage)
queue_free()
```

也就是：Enemy 掉血，Projectile 自己消失。

## Enemy 的 Health

这部分是在 Lesson 04 的 `enemy.gd` 上继续增加状态，而不是重写 Enemy。原来的追踪代码仍然保留：

```gdscript
func _physics_process(_delta: float) -> void:
    var direction := global_position.direction_to(player.global_position)
    velocity = direction * speed
    move_and_slide()
```

Lesson 07 只额外加入：

```gdscript
@export var max_health: int = 3
var health: int

func _ready() -> void:
    health = max_health

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        queue_free()
```

这里的数据流是：`Projectile.damage` 传给 `amount` → `health` 被修改 → `health <= 0` 时 Enemy 从 Scene Tree 移除。

Enemy 默认：

```text
Max Health = 3
```

运行时会把当前 `health` 初始化成 `max_health`。
每次受到 1 点伤害：

```text
3 → 2 → 1 → 0
```

到 0 时执行 `queue_free()`，Enemy 从 Scene Tree 中移除。

## 运行检查

按 `F5` 运行项目。

你应该看到：

- EnemySpawner 继续生成 Enemy；
- Player 继续自动发射可见 Projectile；
- Projectile 命中 Enemy 后不再穿过去，而是消失；
- 同一只 Enemy 默认被命中多次后会消失；
- Player 和训练墙不会因为 Projectile 而掉血或消失。

如果 Enemy 一发就消失，先检查 `Enemy.tscn` 的 `Max Health` 是否仍是 `3`。

## 亲手代码实验：让 Health 变得“看得见”

这一步直接改 GDScript，不只改 Inspector。

打开 `scripts/enemies/enemy.gd`，找到：

```gdscript
func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        queue_free()
```

先在 `health -= amount` 后面亲手加一行：

```gdscript
print("Enemy health: ", health)
```

运行前先预测：默认 `Max Health = 3`、Projectile `Damage = 1` 时，同一只 Enemy 被连续命中应该依次打印什么？

按 `F5`，打开 Godot 底部 `Output`，观察类似 `2 → 1 → 0` 的输出。这样你看到的不只是“Enemy 消失了”，而是运行时状态真的在变化。

接着做一个因果实验：暂时把死亡代码改成：

```gdscript
if health <= 0:
    pass
```

这里不能只把 `queue_free()` 注释掉，因为注释不算 GDScript 语句；`if` 代码块如果完全为空会解析失败。`pass` 表示“这个分支合法存在，但暂时什么都不做”。

先预测再运行：Health 到 0 以后 Enemy 是否还会消失？继续中弹时 Health 会不会进入负数？观察后恢复 `queue_free()`，并删除刚才的 `print()` 调试行，保存文件。

## Inspector 参数实验

代码实验恢复干净以后，再做参数实验。

1. 先用默认 `Max Health = 3` 运行，观察一只 Enemy 需要多次命中才死亡；
2. 停止运行，打开 `scenes/enemies/Enemy.tscn`；
3. 选中根节点 `Enemy`；
4. Inspector 找到 `Max Health = 3`；
5. **先预测**：改成 `1` 后，Enemy 会发生什么变化？
6. 改成 `1`，按 `F5` 再观察；
7. 你应该看到 Enemy 被第一发 Projectile 命中后直接死亡；
8. 最后把 `Max Health` 恢复为 `3`，保存。

## 学习检查

能用自己的话回答即可：

1. `CharacterBody2D` 和 `Area2D` 在这课里分别负责什么？
2. `body_entered` 是谁提供的 Signal？
3. 为什么 Projectile 命中后要 `queue_free()`？
4. `max_health`、`health`、`damage` 分别表示什么？
5. Enemy 死亡和“死亡后掉经验”为什么要拆成两课？

## 想再多懂一点

见：

[Area2D、Signal 与 Health：一次命中是怎么发生的](../concepts/area2d-signal-health.md)

## Checkpoint

完成实验并把 Enemy `Max Health` 恢复为 `3` 后，对应 Git Tag：

```text
lesson-07-damage-and-death
```

下一课：**Lesson 08：Enemy 死亡后掉落经验。**
