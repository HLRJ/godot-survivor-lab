# 00 - Bootstrap

## 今天真正需要懂的 4 个概念

### 1. project.godot
Godot 工程的核心配置文件。Godot 看到这个文件，就把所在目录识别为一个项目。

### 2. Scene
Scene 可以理解为“可复用的游戏对象或游戏页面”。现在的 `Main.tscn` 是整个项目的入口场景。

### 3. Node
Scene 由 Node 组成。当前 Main 场景里使用了 Node2D、ColorRect 和 Label。后面玩家、怪物、子弹也会由节点组合出来。

### 4. .godot 目录
Godot 自动生成的导入缓存和编辑器数据，不应该提交到 Git。删掉后 Godot 可以重新生成，所以被 `.gitignore` 排除。

## 邪修原则
先让东西跑起来，再围绕当前功能学习对应概念。不要在做出第一个可玩 Demo 前系统啃完整 API。
