# Lesson 00：准备环境——先把项目跑起来

## 本课目标

在 Godot 4.7.2 中打开 Godot Survivor Lab，并成功运行一次。

## 完成效果

你会看到一个约 1280×720 的窗口，标题是 `Godot Survivor Lab`，画面中显示项目基线文字。关闭运行窗口后，会回到 Godot 编辑器。

## 本课只学这些

1. `project.godot` 是 Godot 项目的入口配置文件。
2. Godot 编辑器里的 **Run Project / 运行项目** 会从主场景启动游戏。
3. Git Checkpoint 可以理解成课程里的“存档点”。

## 开始前检查

本课程以以下环境作为第一条学习路线：

- Windows 10/11
- Godot 4.7.2 stable
- GDScript
- Git

如果你正在跟随仓库历史学习，本课完成后的 Checkpoint 是：`lesson-00-environment`。

## 动手做

### 路径 A：你已经有本地项目

1. 打开 Godot 4.7.2。
2. 在 Project Manager 中选择 **Import** 或 **Open**。
3. 选择仓库根目录里的 `project.godot`。
4. 等待 Godot 完成首次导入。

### 路径 B：你是第一次获取这个项目

仓库公开后，可以先克隆：

```bash
git clone https://github.com/HLRJ/godot-survivor-lab.git
cd godot-survivor-lab
```

然后在 Godot Project Manager 中打开这个目录里的 `project.godot`。

### 运行项目

进入编辑器后，点击右上角 **Run Project** 按钮。默认 `F5` 运行整个项目，`F6` 运行当前场景；本课使用 `F5` / Run Project。

当前 `project.godot` 已指定主场景：

```text
res://scenes/main/Main.tscn
```

所以运行项目时不需要你手动选择场景。

## 代码说人话

这节课还不写 GDScript。先只理解两个文件的关系：

```text
project.godot
   ↓ 指定主场景
scenes/main/Main.tscn
```

`project.godot` 更像“这个游戏项目的总配置”；`Main.tscn` 是当前游戏启动后首先加载的 Scene。

## 运行检查

运行成功时，你应该看到：

- 一个约 1280×720 的窗口；
- 标题文字 `Godot Survivor Lab`；
- 状态文字 `Milestone 0 - Project baseline`；
- 关闭运行窗口后，Godot 编辑器仍然保持打开。

如果结果不同，先不要改大量设置。确认你打开的是本仓库根目录的 `project.godot`，并确认 Godot 版本为 4.7.2 stable。

## 如果失败

最常见的情况：

1. **Godot 找不到项目**：确认选择的是 `project.godot`，不是 README 或某个子目录。
2. **素材一直导入**：第一次打开会生成 `.godot/` 缓存，等导入完成再运行。
3. **提示找不到 Main.tscn**：确认仓库文件完整，`scenes/main/Main.tscn` 存在。
4. **版本提示不同**：优先用 Godot 4.7.2 stable 跟随本课程，避免把版本差异误认为自己写错了。

## 小实验

先想一下：如果你关闭正在运行的游戏窗口，然后再次点击 **Run Project**，工程里的文件会不会被删除或重置？

先给出自己的判断，再实际运行一次。

你应该观察到：关闭运行窗口只是停止这次游戏运行，不会删除工程文件，也不会自动撤销编辑器里的项目内容。

## 学习检查

不用背标准答案，能用自己的话说清楚即可：

1. `project.godot` 在项目里负责什么？
2. “打开 Godot 项目”和“运行 Godot 项目”有什么区别？
3. 为什么课程要保留 Git Checkpoint，而不是改坏了就重新下载一份？

## 可选挑战

在 Project Manager 里观察项目名称和项目路径即可，不需要修改任何配置。

## Checkpoint

完成本课后，对应 Git Tag：

```text
lesson-00-environment
```

Checkpoint 不是“必须从这里开发的分支”，而是一个永久存档点。以后如果工程被自己改乱，可以先用它查看本课结束时的正确状态。

下一课：Lesson 01：第一个 Scene（完成 Lesson 01 时再加入可点击链接，避免当前 Checkpoint 出现死链接）。
