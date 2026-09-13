# Projectile 与自动攻击：谁负责发射，谁负责飞

Lesson 06 第一次让 Player 不按攻击键，也会自动向 Enemy 发射东西。

这一课只建立三个够用的心智模型：Weapon、Projectile、方向驱动飞行。

## 1. Weapon 和 Projectile 是两个职责

现在 Player 下面多了一个 Weapon：

```text
Player
└── Weapon
    └── Timer
```

Weapon 负责回答两个问题：

- 什么时候攻击？
- 朝哪个 Enemy 攻击？

Projectile 则负责另一个问题：

- 我出生以后，往哪个方向、以多快的速度飞？

把两者分开后，Weapon 不需要每帧亲自移动子弹。

## 2. direction_to() 其实已经见过

Lesson 04 的 Enemy 追 Player 时写过：

```gdscript
var direction := global_position.direction_to(player.global_position)
```

现在 Weapon 只是把同一个思路换了一个使用者：

```gdscript
var direction := global_position.direction_to(target.global_position)
```

区别不是数学变了，而是谁在问“目标在哪边”。

- Enemy 用这个方向决定自己怎么追；
- Projectile 用这个方向决定自己怎么飞。

`direction_to()` 返回的方向向量长度接近 1，所以它很适合再乘一个速度。

## 3. Projectile 的移动

```gdscript
position += direction * speed * delta
```

可以拆成：

```text
direction -> 往哪边
speed     -> 每秒多快
delta     -> 这一帧经过了多少秒
```

所以修改 Projectile 的 `Speed`，改变的是子弹飞行速度，不会改变 Weapon 多久开一次火。为了让学习实验更容易感知，Lesson 06 会临时对比 `200` 与 `1000`，最后恢复默认 `520`。

## 4. 为什么 Projectile 是独立 Scene

每次攻击都会执行一次：

```gdscript
var projectile := projectile_scene.instantiate()
```

因此每一发 Projectile 都是一个独立实例，各自保存自己的位置和方向。

```text
Projectile.tscn 模板
├── Projectile A
├── Projectile B
└── Projectile C
```

这和 Lesson 05 用同一个 Enemy Scene 不断刷出多个 Enemy 是同一个模式。

## 5. `.tscn` 和 Script 到底是什么关系

这两个东西不是二选一，而是配合使用。

可以先把它们理解成：

```text
Projectile.tscn -> 这个对象由哪些 Node 组成、贴什么图、初始参数是什么
projectile.gd   -> 这个对象运行起来以后会做什么
```

在 `Projectile.tscn` 里，根节点会通过 `script = ExtResource(...)` 把 `projectile.gd` 挂上去。

而脚本里的：

```gdscript
@export var speed: float = 520.0
```

又会把 `Speed` 暴露到 Godot Inspector。于是你可以在 Scene 中配置脚本参数，而不用每次都修改代码。

所以更完整地记：

> `.tscn` 负责结构与配置，`.gd` 负责行为；`script` 把两者连接，`@export` 又把脚本参数暴露回 Inspector。

## 6. 本课还不能真正“打中” Enemy

当前 Projectile 只是 `Node2D`：

```text
Projectile
└── Sprite2D
```

它没有 `Area2D`，没有命中检测，也没有伤害。

这是刻意的课程边界。Lesson 07 再加入碰撞检测、生命值与死亡，把“会飞的子弹”升级成“真的能打敌人的子弹”。
