# Lesson 04：Enemy 开始追你了

## 本课目标

新增第一个 Enemy，让它持续追踪 Player 当前的位置。

完成后你移动 Player 时，Enemy 会不断调整方向追过来。

## 本课只学三个东西

1. Node 引用：Enemy 怎么找到 Player；
2. `direction_to()`：怎么得到“从我指向目标”的方向；
3. 复用 `CharacterBody2D` 的移动模型。

## Scene 结构

主场景现在是：

```text
Main
├── Player
├── Enemy
├── TrainingWall
└── UI Labels
```

Enemy 自己仍然是独立 Scene：

```text
Enemy (CharacterBody2D)
├── Sprite2D
└── CollisionShape2D
```
## Enemy 的核心代码

```gdscript
extends CharacterBody2D

@export var speed: float = 110.0
@onready var player: Node2D = get_node("../Player")

func _physics_process(_delta: float) -> void:
    var direction := global_position.direction_to(player.global_position)
    velocity = direction * speed
    move_and_slide()
```

先用一句话理解：

> 找到 Player → 算朝向 Player 的方向 → 用这个方向乘速度 → 移动。

其中：

```gdscript
get_node("../Player")
```

表示 Enemy 先回到父节点 Main，再找到同级的 Player。

而：

```gdscript
global_position.direction_to(player.global_position)
```

是在世界坐标里计算 Enemy 指向 Player 的方向。
## 运行检查

按 `F5` 运行。

你应该看到一个和 Player 外观不同的 Enemy，从左下区域开始向 Player 追过来。

然后移动 Player：

- 向左跑，Enemy 会改方向；
- 向上跑，Enemy 也会跟着转向；
- 不操作时，Enemy 会继续缩短和 Player 的距离。

如果 Enemy 被训练墙挡住，这是正常的。它现在只会“朝目标走”，还不会寻路绕障碍。

## 你的亲手实验

这一步不要交给自动化。

1. 先按 `F5`，移动 Player，确认 Enemy 会实时追踪；
2. 停止运行，打开 `scenes/enemies/Enemy.tscn`；
3. 选中根节点 `Enemy`；
4. 在 Inspector 找到导出的 `Speed`，默认是 `110`；
5. **先预测**：改成 `220` 后会发生什么；
6. 改成 `220`，再次运行并移动 Player；
7. 感受追赶速度变化；
8. 最后把 `Speed` 恢复成 `110`，保存。

这和 Lesson 02 修改 Player Speed 是同一种机制，只是现在调整的是敌人的追踪速度。
## 一个你刚刚已经观察到的边界

Enemy 撞到 TrainingWall 后不会自己绕路，这是当前实现的预期行为。

本课的 Enemy 只会做一件事：每个 physics frame 重新计算“Player 在哪个方向”，然后沿直线追过去。

它没有地图，也没有“绕开障碍物”的路径规划能力。真正的绕路属于寻路问题，通常会涉及 `NavigationRegion2D` / `NavigationAgent2D`。我们暂时不引入，避免把“追踪方向”和“寻路”混成一个概念。

## 学习检查

能用自己的话回答即可：

1. Enemy 为什么能找到 Player？
2. `../Player` 里的 `..` 是什么意思？
3. `direction_to()` 解决的是什么问题？
4. Enemy 和 Player 的移动逻辑，真正不同的地方在哪里？
5. 为什么 Player 移动以后 Enemy 会自动重新转向？

## 想再多懂一点

见：

[Node 引用与方向：Enemy 为什么知道 Player 在哪](../concepts/node-reference-and-direction.md)

## Checkpoint

完成实验并把 Enemy Speed 恢复为 `110` 后，对应 Git Tag：

```text
lesson-04-enemy-chase
```

下一课：**Lesson 05：不断刷怪。**
