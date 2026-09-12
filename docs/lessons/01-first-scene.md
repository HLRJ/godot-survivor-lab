# Lesson 01：第一个 Scene——把玩家放到屏幕上

## 本课目标

理解 Godot 最核心的两个词：`Scene` 和 `Node`，并让一个独立的 `Player.tscn` 出现在主场景中。

## 完成效果

运行项目后，你会在屏幕中央看到一个放大后的像素角色；顶部显示 `Godot Survivor Lab` 和 `Lesson 01 - 第一个 Scene`。

## 本课只学这些

1. `Node`：场景树里的一个功能单位。
2. `Scene`：一棵可以保存、复用、实例化的 Node 树。
3. `Sprite2D`：在 2D 世界中显示纹理图片的 Node。

## 开始前检查

如果你跟着课程 Checkpoint 学习，可以从下面的状态开始：

```text
lesson-00-environment
```

本课完成后的 Checkpoint：

```text
lesson-01-first-scene
```

## 动手做

先在 Godot 的 FileSystem 面板找到并双击：

```text
scenes/player/Player.tscn
```

你会看到一棵很小的 Scene Tree：

```text
Player (Node2D)
└── Sprite2D
```

`Player` 是这棵树的根节点；`Sprite2D` 是它的子节点，负责把角色图片画出来。

然后打开：

```text
scenes/main/Main.tscn
```

你会看到 `Main` 下面已经实例化了 `Player`。这意味着 `Main` 不需要复制 Player 内部结构，只需要引用整个 `Player.tscn`。

## 代码说人话

`Player.tscn` 里最重要的结构是：

```ini
[node name="Player" type="Node2D"]

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = SubResource("AtlasTexture_player")
scale = Vector2(4, 4)
```

可以先把它理解成：

- `Player`：一个“玩家对象”的容器；
- `Sprite2D`：负责显示角色；
- `texture`：告诉 Sprite2D 用哪张图；
- `scale = Vector2(4, 4)`：把原本 16×16 的像素角色沿 X、Y 各放大 4 倍。

这里的 `Scale` 是**相对于这个 Node 原始大小的局部缩放倍数**。`(1, 1)` 表示原始大小，当前 16×16 的角色在 `(4, 4)` 时约显示为 64×64，在 `(6, 6)` 时约为 96×96。`Sprite2D` 默认以中心点绘制，所以放大时中心位置保持不变，边缘向四周扩展。以后如果父 Node 也有缩放，最终视觉缩放会与父级 Scale 相乘。

`Main.tscn` 中这段：

```ini
[node name="Player" parent="." instance=ExtResource("1_player")]
position = Vector2(640, 360)
```

意思是：把已经保存好的 `Player.tscn` 实例化一次，并放到屏幕中心附近。

## 运行检查

点击 **Run Project**（默认 `F5`）。正确结果应该是：

- 窗口正常启动；
- 顶部出现 `Godot Survivor Lab`；
- 顶部第二行显示 `Lesson 01 - 第一个 Scene`；
- 屏幕中央出现一个像素角色；
- 没有 missing resource / parse error。

## 如果失败

1. **屏幕中央没有角色**：确认 `Main.tscn` 里存在 `Player` 实例。
2. **角色是空白或紫色方块**：确认 Kenney 素材文件仍在 `assets/third_party/kenney/roguelike-characters/`。
3. **角色太小**：确认 `Sprite2D` 的 Scale 是 `(4, 4)`。
4. **打不开 Player.tscn**：确认路径是 `scenes/player/Player.tscn`。
5. **提示 Parse Error**：不要继续加功能，先回到 `lesson-00-environment` 对比当前改动。

## 小实验

这一小步请你亲手做。

先不要改，先预测：

> 如果把 `Sprite2D` 的 Scale 从 `(4, 4)` 改成 `(6, 6)`，角色会发生什么？位置会不会一起改变？

然后在 Inspector 中选中 `Sprite2D`，把 Scale 改为：

```text
x = 6
y = 6
```

再次运行项目，观察结果。

实验完成后，把 Scale 改回 `(4, 4)`，这样后续课程保持统一基线。

## 学习检查

不用背定义，能用自己的话解释即可：

1. `Node` 和 `Scene` 的关系是什么？
2. 为什么要把 Player 单独保存成 `Player.tscn`，而不是把所有东西都塞进 `Main.tscn`？
3. `Sprite2D` 在当前 Player 里负责什么？
4. 修改 `Sprite2D.scale` 为什么会改变角色显示大小？

## 可选挑战

在不移动 Player 根节点的前提下，只修改 `Sprite2D` 的 Scale，分别试一下 `(2, 2)` 和 `(8, 8)`。

观察后恢复 `(4, 4)`。

## 想再多懂一点

如果你想把 Scene / Node 的关系理解得更牢，可以看：

[Scene 和 Node：Godot 的最小心智模型](../concepts/scene-and-node.md)

这不是下一课的前置要求，不看也能继续。

## Checkpoint

完成本课并恢复 `Scale = (4, 4)` 后，对应 Git Tag：

```text
lesson-01-first-scene
```

下一课会把 `Player` 从静态的 `Node2D` 升级为适合移动和碰撞的 `CharacterBody2D`，正式让角色动起来。
