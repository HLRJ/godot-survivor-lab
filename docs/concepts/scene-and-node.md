# Scene 和 Node：Godot 的最小心智模型

这不是需要背下来的定义页。你只要先建立一个够用的模型，后面做游戏时再逐步修正理解。

## 一句话版本

- `Node`：一个具体的功能单位。
- `Scene`：一棵保存起来、以后还能重复使用的 Node 树。

在 Lesson 01 里，我们的 `Player.tscn` 是一个 Scene：

```text
Player (Node2D)
└── Sprite2D
```

`Player` 和 `Sprite2D` 都是 Node；这棵树保存成 `Player.tscn` 后，就成了可以复用的 Scene。

## 为什么 Godot 要这样组织

假设以后一个玩家不只有图片，还会有：

- 碰撞体；
- 血量；
- 武器；
- 受伤检测；
- 音效。
如果全部直接塞进 `Main`，场景树会越来越乱。

所以我们把“玩家自己负责的东西”组织在 `Player.tscn` 里，然后让 `Main.tscn` 只负责把 Player 放进游戏世界。

可以先把它类比成：

```text
Main.tscn = 舞台
Player.tscn = 一个演员
Sprite2D = 演员身上负责把外观画出来的部件
```

这个类比不是 Godot 的完整定义，但对于现在足够准确。

## Scene 不是“关卡”的同义词

这是新手很容易误会的一点。

Scene 可以是一整个关卡，也可以只是：

- 一个玩家；
- 一个敌人；
- 一颗子弹；
- 一个经验宝石；
- 一个按钮；
- 一整个主菜单。

关键不在大小，而在于：**这棵 Node 树是不是值得作为一个独立对象保存和复用。**

## 实例化是什么意思
`Player.tscn` 保存以后，`Main.tscn` 可以引用它：

```ini
[node name="Player" parent="." instance=ExtResource("1_player")]
position = Vector2(640, 360)
```

这里的 `instance` 可以先理解为：

> 根据保存好的 `Player.tscn`，在当前场景里创建一个 Player。

以后我们生成敌人、子弹、经验宝石时，会反复使用这个思想。

## 你现在只需要记住什么

看到 Godot 的 Scene Tree 时，先问三个问题：

1. 根 Node 代表什么对象？
2. 子 Node 各自在帮它做什么？
3. 这棵树是否值得单独保存成一个 Scene？

如果这三个问题能答出来，你对 Scene / Node 的理解已经足够继续 Lesson 02。

## 下一次会怎么用到

Lesson 02 会把 Player 根节点从 `Node2D` 升级成 `CharacterBody2D`。

原因不是“教程规定必须这样”，而是我们下一步真的需要一个适合角色移动和碰撞的 Node 类型。

这就是本课程的原则：**先遇到问题，再引入解决问题的 Godot 概念。**
