# Lesson 03：让 Player 真正撞到墙

## 本课目标

给会移动的 Player 加上真正的碰撞体，并放一面不会移动的训练墙。

完成后你按 `D` 向右走，角色会在墙前停下，而不是穿过去。

## 本课只学三个东西

1. `CollisionShape2D`：告诉 Godot 物理身体的形状。
2. `StaticBody2D`：不会主动移动的墙、地面、障碍物。
3. Collision Layer / Mask：决定谁和谁需要发生碰撞。

## Player 现在的结构

```text
Player (CharacterBody2D)
├── Sprite2D
└── CollisionShape2D
```

上一课我们已经知道：Player 管行为，Sprite2D 管外观。

这一课再加一句：

> `CollisionShape2D` 管 Player 在物理世界里的“身体范围”。

## TrainingWall 的结构

主场景新增：

```text
TrainingWall (StaticBody2D)
├── Visual
└── CollisionShape2D
```

`Visual` 只是让你看见墙；真正挡住 Player 的是 `CollisionShape2D`。

这和 Player 的思路完全一样：**显示和物理是两件事。**

## 运行检查

按 `F5` 运行项目。

你应该能看到：

- Player 从屏幕中央开始；
- 右边有一面竖直训练墙；
- 按 `D` 向右移动；
- 接近墙以后 Player 会停下；
- 按上下方向时仍然可以沿着墙滑动。

如果图片碰到墙前还有一点空隙，不一定是 Bug。碰撞体不需要和像素图片百分之百重合，通常会略小一点，让手感更自然。

## Layer / Mask 先这样理解

当前 Player 和 TrainingWall 都使用第 1 层。

先记口诀：

> **Layer：我是谁。Mask：我关心谁。**

所以现在双方都能互相检测并发生碰撞。

## 你的亲手实验

这一步不要交给自动化。

1. 打开 `scenes/player/Player.tscn`；
2. 选中根节点 `Player`；
3. Inspector 中找到 `Collision`；
4. 保持 `Layer` 的第 1 层开启；
5. 临时把 `Mask` 的第 1 层关闭；
6. 按 `F5`，再向右撞训练墙；
7. 先观察结果，再把 `Mask` 第 1 层重新打开并保存。

先预测：**只关闭 Mask、不关闭 Layer，Player 还能被墙挡住吗？**

你应该会发现：关闭 Player 的 Mask 后，它会穿过训练墙。

恢复 Mask 后，碰撞重新生效。

这比直接背“Layer / Mask 定义”更重要，因为你已经亲眼看到它们控制了什么。

## 学习检查

能用自己的话回答即可：

1. 为什么只有 Sprite2D 还不能产生碰撞？
2. Player 为什么用 `CharacterBody2D`，墙为什么用 `StaticBody2D`？
3. `CollisionShape2D` 和图片是什么关系？
4. “Layer：我是谁；Mask：我关心谁”是什么意思？
5. 为什么 Lesson 02 的 `move_and_slide()` 到这一课才真正体现出“碰撞移动”的意义？

## 想再多懂一点

见：

[碰撞、Layer 和 Mask：先建立一个够用的模型](../concepts/collision-layer-mask.md)

## Checkpoint

完成实验并把 Player 的 Mask 第 1 层恢复后，对应 Git Tag：

```text
lesson-03-collision
```

下一课：**Lesson 04：Enemy 追踪 Player。**
