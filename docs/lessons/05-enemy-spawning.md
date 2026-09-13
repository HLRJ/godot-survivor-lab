# Lesson 05：让 Enemy 不断出现

## 本课目标

把 Lesson 04 的“场景里固定放一个 Enemy”，升级成“游戏运行后按时间不断生成 Enemy”。

完成后你会看到：Enemy 数量随着时间持续增加，而且每一只都会继续追踪 Player。

## 本课只学三个东西

1. `PackedScene`：可以反复实例化的 Scene 模板；
2. `instantiate()`：从模板创建一个新的 Node 实例；
3. `Timer`：按固定时间间隔触发刷怪。

## Main 现在的结构

```text
Main
├── Player
├── TrainingWall
├── EnemySpawner
└── UI Labels
```

注意：Main 里已经不再手工摆一个固定 Enemy。

真正运行以后，Spawner 会把生成出来的 Enemy 动态加到 Main 下面。

## EnemySpawner 自己的结构

```text
EnemySpawner (Node)
└── Timer
```

Spawner 的核心代码是：

```gdscript
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.5
@onready var timer: Timer = $Timer
```

先用一句话理解：

> 我手里有一个 Enemy 模板，每隔一段时间从模板做出一个新的 Enemy。

## 刷怪真正发生在哪里

```gdscript
func _spawn_enemy() -> void:
    var enemy := enemy_scene.instantiate() as CharacterBody2D
    enemy.position = spawn_positions[spawn_index % spawn_positions.size()]
    spawn_index += 1
    get_parent().add_child(enemy)
```

这里最关键的是两步：

```text
instantiate() -> 创建
add_child()   -> 放进正在运行的 Scene Tree
```

只 `instantiate()` 不 `add_child()`，你仍然看不到这个 Enemy 在游戏世界里运行。

## 为什么不写 `add_child(enemy)`

如果直接写：

```gdscript
add_child(enemy)
```

Enemy 就会变成 EnemySpawner 的子节点。
那会变成：

```text
Main
├── Player
└── EnemySpawner
    └── Enemy
```

此时 Enemy 的 `../Player` 会去找 `EnemySpawner/Player`，当然找不到。

所以本课故意使用：

```gdscript
get_parent().add_child(enemy)
```

Spawner 先拿到自己的父节点 Main，再让 Main 接收这个 Enemy。

最终运行时是：

```text
Main
├── Player
├── EnemySpawner
├── Enemy
├── Enemy
└── Enemy
```

这样 Lesson 04 的 `../Player` 仍然成立。

这也是第一次看到：**Scene Tree 的层级不仅影响整理方式，也会影响代码路径。**

## Timer 做了什么

默认：

```text
Spawn Interval = 1.5 秒
```

运行后要稍等大约 1.5 秒，第一只 Enemy 才会出现；之后按同样间隔继续生成。

## 运行检查

按 `F5` 运行项目。

你应该看到：

- 一开始只有 Player 和训练墙；
- 大约 1.5 秒后出现第一只 Enemy；
- 后面 Enemy 会继续增加；
- 新出现的 Enemy 仍然会追踪 Player；
- 多只 Enemy 之间可能互相挤住，这是目前都在同一碰撞层上的正常现象。

本课暂时不处理“Enemy 太多以后性能怎么办”，也不处理对象池。

## 你的亲手实验

这一步不要交给自动化。

1. 先运行，感受默认 `1.5` 秒的刷怪节奏；
2. 停止运行，打开 `scenes/enemies/EnemySpawner.tscn`；
3. 选中根节点 `EnemySpawner`；
4. Inspector 找到 `Spawn Interval = 1.5`；
5. **先预测**：改成 `0.5` 后会发生什么；
6. 改成 `0.5`，再运行一会；
7. 观察 Enemy 数量增长速度；
8. 最后恢复成 `1.5`，保存。

这里改变的不是 Enemy 移动速度，而是“多久制造一个新 Enemy”。

## 学习检查

能用自己的话回答即可：

1. `PackedScene` 和已经运行中的 Enemy 有什么区别？
2. `instantiate()` 做了什么？
3. 为什么新实例还需要 `add_child()`？
4. Timer 和 EnemySpawner 各自负责什么？
5. 为什么生成的 Enemy 要加到 Main，而不是直接加到 EnemySpawner？

## 想再多懂一点

见：

[PackedScene、instantiate 和 Timer：为什么能不断刷怪](../concepts/packedscene-instantiate-timer.md)

## Checkpoint

完成实验并把 Spawn Interval 恢复为 `1.5` 后，对应 Git Tag：

```text
lesson-05-enemy-spawning
```

下一课：**Lesson 06：自动攻击。**
