# Area2D、Signal 与 Health：一次命中是怎么发生的

Lesson 07 第一次让 Projectile 不只是“飞过去”，而是真正影响 Enemy。

这一课只建立三个心智模型：`Area2D`、Signal、Health。

## 1. CharacterBody2D 和 Area2D 分工不同

Enemy 现在是 `CharacterBody2D`：

```text
Enemy (CharacterBody2D)
└── CollisionShape2D
```

它有实体，会移动，也会被墙挡住。

Projectile 现在改成：

```text
Projectile (Area2D)
├── Sprite2D
└── CollisionShape2D
```

`Area2D` 更适合回答：**有什么 PhysicsBody 进入了我的检测范围？**
它本身不是为了把 Enemy 顶开的，所以很适合子弹、拾取物、触发区。

## 2. Signal 可以先理解成“事件通知”

`Area2D` 已经提供一个内置 Signal：

```text
body_entered
```

意思是：有一个 PhysicsBody 进入了我的检测区域。

Projectile 在 `_ready()` 里写：

```gdscript
body_entered.connect(_on_body_entered)
```

可以读成：

> 当 `body_entered` 发生时，请调用 `_on_body_entered()`。

所以 Signal 的作用不是“每帧主动问有没有撞到”，而是让某件事发生时通知我们。

## 3. Signal 的参数到底从哪来

`body_entered` 不是我们自己声明的，它是 `Area2D` 内置的 Signal。可以把 Godot 引擎内部近似理解成：

```gdscript
signal body_entered(body: Node2D)
# 物理引擎检测到某个 PhysicsBody 进入后，近似执行：
body_entered.emit(entered_body)
```

我们的 `body_entered.connect(_on_body_entered)` 只是在登记回调函数，并没有传入 `body`。真正发生碰撞时，Godot 发出 Signal，并把“这次进入区域的那个 PhysicsBody”作为参数传给回调，因此近似等价于 `_on_body_entered(entered_body)`。

这里的 `body: Node2D` 是回调参数的类型声明，不代表所有 `Node2D` 都会触发 `body_entered`；它主要对应 `CharacterBody2D`、`StaticBody2D`、`RigidBody2D` 等 PhysicsBody。

## 4. 碰撞发生后的调用链

```text
Projectile Area2D 检测到 Enemy
        ↓
body_entered Signal
        ↓
_on_body_entered(enemy)
        ↓
Enemy.take_damage(1)
        ↓
health: 3 → 2
```

Projectile 处理完命中后 `queue_free()`，所以一发子弹不会重复伤害同一个 Enemy。

## 5. Health、Damage、Death 是三件事

Enemy 现在有：

```gdscript
@export var max_health: int = 3
var health: int
```

可以这样区分：

```text
max_health -> 这个 Enemy 最多有多少生命
health     -> 当前还剩多少生命
damage     -> 一次攻击要扣多少生命
Death      -> health <= 0 后发生的结果
```

`take_damage()` 只是修改状态：

```gdscript
health -= amount
```
然后决定是否死亡：

```gdscript
if health <= 0:
    queue_free()
```

## 6. 为什么 Player 和墙不会受伤

Projectile 的 Collision Mask 会检测默认 Layer 1 上的 PhysicsBody，所以它可能“看到” Player、Enemy 或训练墙。

但脚本还会再判断：

```gdscript
if body.scene_file_path != "res://scenes/enemies/Enemy.tscn":
    return
```

因此本课只有 Enemy 会进入伤害逻辑。

这是为了保持课程简单。以后对象种类变多时，可以再学习 Group 或更细的 Collision Layer 设计。

## 7. 本课边界

Enemy 死亡后现在只是从 Scene Tree 中移除。

“死亡后生成经验宝石”是下一课 Lesson 08 的内容，这样我们可以单独看清“死亡”和“掉落”是两个责任。
