# Lesson 08：Enemy 死亡后掉落经验

## 本课目标

把 Lesson 07 的“Enemy 会死亡”继续向前推进一步：Enemy 死亡时主动发出自定义 Signal，EnemySpawner 接收这个事件，并在死亡位置生成 ExperienceGem。

完成后你会看到：Enemy 被打到 0 血后消失，同时原地留下绿色经验球。

## 本课只学三个东西

1. 自定义 Signal：自己完成 `signal → connect → emit → callback`；
2. `PackedScene`：保存“可实例化 Scene 模板”的资源类型；
3. 生命周期与数据传递：对象销毁前把需要的信息通知出去。

本课只负责“掉落”，暂时不做拾取和经验值增长。

## 先把前面的课接起来

Lesson 08 没有重新造一套生成系统，而是把两个已经存在的能力接起来：

```text
Lesson 05：EnemySpawner 已经会 PackedScene + instantiate() 生成 Enemy
Lesson 07：Enemy 已经知道自己什么时候 health <= 0 并死亡
Lesson 08：Enemy 死亡时 emit，Spawner 监听后 instantiate ExperienceGem
```

## 第一步：Enemy 声明自己的死亡事件

在 `enemy.gd` 中加入：

```gdscript
signal died(dead_enemy: Node2D)
```

这句话只是在声明协议：以后谁发出 `died`，要携带一个 `Node2D` 参数。

它和函数参数很像：

```gdscript
func take_damage(amount: int)
```

表示调用函数时要提供一个 `int`；而 `signal died(dead_enemy: Node2D)` 表示 emit 这个 Signal 时要提供一个 `Node2D`。

## 第二步：死亡条件成立时真正 emit

Lesson 07 原来是：

```gdscript
if health <= 0:
    queue_free()
```

Lesson 08 改成：

```gdscript
if health <= 0:
    died.emit(self)
    queue_free()
```

这里的 `self` 就是当前正在死亡的那一只 Enemy 实例。

如果死的是 `Enemy_2`，可以近似理解成：

```gdscript
died.emit(Enemy_2)
```

所以 Signal 参数不是凭空出现的，而是由 `emit(...)` 明确送出去。

## 第三步：Spawner 监听每一只新 Enemy

Spawner 创建 Enemy 时，本来就会拿到这个实例：

```gdscript
var spawned_enemy = enemy_scene.instantiate()
```

然后加入：

```gdscript
spawned_enemy.died.connect(_on_enemy_died)
```

这里的 `spawned_enemy` 不是 Signal 参数，而是 `instantiate()` 返回的对象引用。`connect()` 的意思是：这只 Enemy 以后发出 `died` 时，调用 `_on_enemy_died`。

本课暂时没有写 `as CharacterBody2D`，因为 `died` 是我们自己的 Enemy 脚本新增的成员，不是 `CharacterBody2D` 内置 API。以后引入 `class_name Enemy` 后，可以获得更完整的静态类型提示。

## 第四步：callback 接住死亡 Enemy

Spawner 最后加入：

```gdscript
func _on_enemy_died(dead_enemy: Node2D) -> void:
    var experience := experience_scene.instantiate() as Node2D
    experience.global_position = dead_enemy.global_position
    get_parent().add_child(experience)
```

完整参数链路是：

```text
Enemy_2 死亡
    ↓
died.emit(self)
    ↓
self = Enemy_2
    ↓
_on_enemy_died(Enemy_2)
    ↓
dead_enemy = Enemy_2
```

因此 callback 能读取 `dead_enemy.global_position`，并让经验球出生在同一个位置。

## `queue_free()` 以后为什么还能读位置

当前顺序是先 `emit()`，再 `queue_free()`。默认 Signal callback 会在 `emit()` 的当前调用链里同步执行，所以 `_on_enemy_died()` 读取位置时 Enemy 还存在。

可以近似理解成：

```text
died.emit(self)
    ↓
立即执行已连接 callback
    ↓
callback 读取位置并生成 ExperienceGem
    ↓
emit() 返回
    ↓
queue_free() 把 Enemy 排队删除
```

`queue_free()` 也不是这一行执行时立刻让对象从内存消失，而是安全地排队释放。不过依然推荐“先通知、后销毁”，代码语义更清楚。

以后如果接收方只需要死亡位置，也可以把 Signal 改成传 `Vector2`，避免把一个即将销毁的对象引用传出去。本课先传 `self`，是为了把对象引用和 Signal 参数链学清楚。

## PackedScene 到底是什么

```gdscript
@export var enemy_scene: PackedScene
@export var experience_scene: PackedScene
```

`PackedScene` 可以先理解成“已经保存好的 Scene 蓝图 / 模板”。

```text
Enemy.tscn → PackedScene → instantiate() → 一个真正的 Enemy 实例
ExperienceGem.tscn → PackedScene → instantiate() → 一个真正的经验球实例
```

所以 `enemy_scene` 不是一只 Enemy，`experience_scene` 也不是一颗经验球；它们都是以后可以反复 `instantiate()` 的模板。

## 视觉大小和碰撞大小不是一回事

本课把 Projectile 和 ExperienceGem 的 `Sprite2D.scale` 调到 `2.0`，只是为了更容易看清。

Projectile 的 `CollisionShape2D` 保持原来的大小，所以：

```text
Sprite2D.scale → 你看到多大
CollisionShape2D → 物理检测范围多大
```

两者可以独立设计，不要把“看起来更大”自动等同于“碰撞范围也应该更大”。

## 运行检查

按 `F5`，你应该看到：

- Enemy 仍然持续生成并追踪 Player；
- Projectile 命中后正常造成伤害；
- Enemy 生命值归零后消失；
- Enemy 原位置留下绿色 ExperienceGem；
- 经验球暂时不会移动，也不能拾取；
- Projectile 和 ExperienceGem 比之前明显更容易看清。

## 学习检查

能用自己的话回答即可：

1. `signal died(dead_enemy: Node2D)` 做了什么，`died.emit(self)` 又做了什么？
2. `spawned_enemy` 和 callback 里的 `dead_enemy` 分别从哪里来？
3. 为什么 Spawner 能在 callback 里读到刚死亡 Enemy 的 `global_position`？
4. `PackedScene` 和 `instantiate()` 分别可以怎么理解？
5. 为什么经验球要挂到 `Main`，而不是挂到马上要 `queue_free()` 的 Enemy 下面？

## Checkpoint

完成本课后，对应 Git Tag：

```text
lesson-08-xp-drop
```

下一课：**Lesson 09：拾取经验球并让经验值增长。**
