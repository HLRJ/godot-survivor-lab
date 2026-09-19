# Lesson 10 Level Up Choice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete playable loop from XP threshold through paused three-choice upgrade selection to a real Player/Weapon stat upgrade.

**Architecture:** Player owns XP, Level and move speed; Weapon owns attack interval and future projectile damage; LevelUpPanel owns only paused UI input; Main coordinates Signals, pending level-ups, pause/resume and upgrade routing. No GameManager or Resource-driven upgrade system is introduced in this lesson.

**Tech Stack:** Godot 4.7.2 stable, GDScript, SceneTree tests, Windows PowerShell, Git/GitHub.

**Spec:** `docs/superpowers/specs/2026-09-20-lesson-10-level-up-choice-design.md`

## Global Constraints

- Work only in `feat/lesson-10-level-up-choice` at `G:\AINmg\Codes\.worktrees\godot-survivor-lab-lesson10`.
- GitHub remote stays `https://github.com/HLRJ/godot-survivor-lab.git`; GitHub CLI active account must remain `HLRJ`.
- Initial level is 1; initial XP is 0; first threshold is 5 XP.
- Each completed level increases the next threshold by exactly 3 XP.
- Move speed upgrade is +40 per choice.
- Attack interval upgrade is -0.1 seconds with a hard floor of 0.2 seconds.
- Projectile damage upgrade is +1 per choice and must affect newly spawned projectiles.
- Fixed upgrade ids are `move_speed`, `attack_speed`, and `projectile_damage`.
- Upgrade UI pauses gameplay but remains interactive while paused.
- Preserve XP overflow and support multiple level-ups from one XP grant.
- Do not add Resource upgrade data, rarity, icons, rerolls, GameManager, save data, or a full HUD.
- Core teaching code is written by the learner at explicit Gate steps; AI handles tests, Scene scaffolding, boilerplate, docs and Git.

## Review Focus

1. **Zero or negative XP input:** `add_experience(0)` and negative amounts must not reduce XP or emit `level_up`; Task 1 pins this.
2. **Large XP burst:** one call must be able to cross multiple thresholds while preserving overflow and emitting once per level; Task 1 pins this.
3. **Attack-speed floor:** repeated upgrades must never move `attack_interval` or `Timer.wait_time` below 0.2; Task 2 pins this.
4. **Paused UI interaction:** the LevelUpPanel must still process button input while `SceneTree.paused == true`; Task 3 pins this.
5. **Queued upgrade choices:** two pending level-ups must require two choices and must not resume gameplay after the first; Task 4 pins this.

## File Map

- Modify `scripts/player/player.gd`: Player XP/Level model, `level_up` Signal, move-speed upgrade.
- Modify `scripts/weapons/weapon.gd`: persistent attack interval/projectile damage upgrades and damage propagation.
- Create `scripts/ui/level_up_panel.gd`: UI Signal and three button callbacks only.
- Create `scenes/ui/LevelUpPanel.tscn`: paused three-choice overlay.
- Create `scripts/main/main.gd`: upgrade flow coordinator only.
- Modify `scenes/main/Main.tscn`: attach Main script, instance LevelUpPanel, update lesson status.
- Create `tests/lesson_10_level_progression_test.gd`: Player leveling RED/GREEN.
- Create `tests/lesson_10_weapon_upgrades_test.gd`: Weapon upgrade RED/GREEN.
- Create `tests/lesson_10_level_up_panel_test.gd`: paused UI RED/GREEN.
- Create `tests/lesson_10_upgrade_flow_test.gd`: end-to-end coordinator RED/GREEN.
- Create `docs/lessons/10-level-up-choice.md`: learner-facing Lesson 10.
- Modify `README.md`: Lesson 10 navigation and progress.

---

### Task 1: Player Level Progression and Level-Up Signal

**Files:**
- Modify: `scripts/player/player.gd`
- Create: `tests/lesson_10_level_progression_test.gd`

**Interfaces:**
- Consumes: existing `add_experience(amount: int) -> void`.
- Produces: `signal level_up(new_level: int)`, `level: int`, `experience_to_next_level: int`, `upgrade_move_speed() -> void`.

- [ ] **Step 1: Write the failing progression test**

Create a SceneTree test following the existing Lesson 09 test style. It must instantiate `Player.tscn`, stop `Player/Weapon/Timer`, and assert:

```gdscript
_expect(_has_property(player, &"level"), "Player must expose level")
_expect(_has_property(player, &"experience_to_next_level"), "Player must expose next-level XP threshold")
_expect(player.has_signal("level_up"), "Player must define level_up signal")
_expect(player.has_method("upgrade_move_speed"), "Player must implement move-speed upgrade")

_expect(int(player.get("level")) == 1, "Player level must start at 1")
_expect(int(player.get("experience")) == 0, "Player XP must start at 0")
_expect(int(player.get("experience_to_next_level")) == 5, "First level threshold must be 5 XP")
```

Connect a local array to the Signal and test exact threshold:

```gdscript
var emitted_levels: Array[int] = []
player.connect("level_up", func(new_level: int) -> void:
    emitted_levels.append(new_level)
)

player.call("add_experience", 5)

_expect(int(player.get("level")) == 2, "5 XP must raise level to 2")
_expect(int(player.get("experience")) == 0, "Exact threshold must leave 0 overflow XP")
_expect(int(player.get("experience_to_next_level")) == 8, "Next threshold must increase from 5 to 8")
_expect(emitted_levels == [2], "Level 2 must emit exactly once")
```

Add overflow, invalid-input and multi-level cases using fresh Player instances:

```gdscript
# Overflow
player.call("add_experience", 7)
_expect(int(player.get("level")) == 2, "7 XP must reach level 2")
_expect(int(player.get("experience")) == 2, "7 XP must preserve 2 overflow XP")

# Zero / negative XP
player.call("add_experience", 0)
player.call("add_experience", -3)
_expect(int(player.get("experience")) == 0, "Non-positive XP must be ignored")
_expect(emitted_levels.is_empty(), "Non-positive XP must not emit level_up")

# Multi-level burst: 5 + 8 = 13
player.call("add_experience", 14)
_expect(int(player.get("level")) == 3, "14 XP must cross two levels")
_expect(int(player.get("experience")) == 1, "14 XP must preserve 1 overflow XP")
_expect(int(player.get("experience_to_next_level")) == 11, "Level 3 threshold must be 11")
_expect(emitted_levels == [2, 3], "Multi-level gain must emit once per level")
```

- [ ] **Step 2: Run the test and verify RED**

Run from the Lesson 10 worktree:

```powershell
$godot = 'D:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
$wt = 'G:\AINmg\Codes\.worktrees\godot-survivor-lab-lesson10'
& $godot --headless --path $wt --script res://tests/lesson_10_level_progression_test.gd
```

Expected: exit 1 with missing `level`, threshold, Signal and upgrade-method failures.

- [ ] **Step 3: Teaching Gate — learner writes Player progression**

Before editing, explain this runtime chain:

```text
ExperienceGem
→ Player.add_experience(amount)
→ experience += amount
→ while enough XP
→ subtract current threshold
→ level += 1
→ grow next threshold
→ level_up.emit(level)
```

Learner personally adds the conceptual core to `player.gd`:

```gdscript
signal level_up(new_level: int)

@export var speed: float = 220.0
var experience: int = 0
var level: int = 1
var experience_to_next_level: int = 5

func add_experience(amount: int) -> void:
    if amount <= 0:
        return

    experience += amount

    while experience >= experience_to_next_level:
        experience -= experience_to_next_level
        level += 1
        experience_to_next_level += 3
        level_up.emit(level)

func upgrade_move_speed() -> void:
    speed += 40.0
```

Do not implement this Gate for the learner. Stop and wait until they report it saved.

- [ ] **Step 4: Run progression test and historical pickup test**

Run:

```powershell
& $godot --headless --path $wt --script res://tests/lesson_10_level_progression_test.gd
& $godot --headless --path $wt --script res://tests/lesson_09_xp_pickup_test.gd
```

Expected: both PASS.

- [ ] **Step 5: Commit Task 1**

```bash
git add scripts/player/player.gd tests/lesson_10_level_progression_test.gd tests/lesson_10_level_progression_test.gd.uid
git commit -m "feat: add player level progression"
```

---

### Task 2: Persistent Weapon Upgrades and Projectile Damage Propagation

**Files:**
- Modify: `scripts/weapons/weapon.gd`
- Create: `tests/lesson_10_weapon_upgrades_test.gd`

**Interfaces:**
- Consumes: existing `projectile_scene`, `attack_interval`, `Timer`, `Projectile.damage`.
- Produces: `projectile_damage: int`, `upgrade_attack_speed() -> void`, `upgrade_projectile_damage() -> void`.

- [ ] **Step 1: Write the failing weapon-upgrade test**

Instantiate `Player.tscn` inside a `TestWorld`, access `Player/Weapon`, and stop its Timer after `_ready()`.

Assert the persistent state and methods:

```gdscript
_expect(_has_property(weapon, &"projectile_damage"), "Weapon must expose projectile_damage")
_expect(weapon.has_method("upgrade_attack_speed"), "Weapon must implement attack-speed upgrade")
_expect(weapon.has_method("upgrade_projectile_damage"), "Weapon must implement projectile-damage upgrade")
_expect(abs(float(weapon.get("attack_interval")) - 0.8) < 0.001, "Attack interval must start at 0.8")
_expect(int(weapon.get("projectile_damage")) == 1, "Projectile damage must start at 1")
```

Test one attack-speed upgrade and Timer synchronization:

```gdscript
weapon.call("upgrade_attack_speed")
_expect(abs(float(weapon.get("attack_interval")) - 0.7) < 0.001, "Attack interval must drop by 0.1")
_expect(abs(timer.wait_time - 0.7) < 0.001, "Timer.wait_time must follow attack_interval")
```

Test the floor:

```gdscript
for _i in range(20):
    weapon.call("upgrade_attack_speed")

_expect(abs(float(weapon.get("attack_interval")) - 0.2) < 0.001, "Attack interval must stop at 0.2")
_expect(abs(timer.wait_time - 0.2) < 0.001, "Timer floor must also be 0.2")
```

Test persistent damage and propagation by adding a real `Enemy.tscn` as a sibling of Player, calling `weapon.call("_attack")`, then finding the spawned Projectile under `current_scene`:

```gdscript
weapon.call("upgrade_projectile_damage")
_expect(int(weapon.get("projectile_damage")) == 2, "Damage upgrade must persist on Weapon")

weapon.call("_attack")
var projectile := _find_projectile(world)
_expect(projectile != null, "Weapon must spawn a projectile")
if projectile != null:
    _expect(int(projectile.get("damage")) == 2, "New projectile must receive upgraded damage")
```

- [ ] **Step 2: Run and verify RED**

Run:

```powershell
& $godot --headless --path $wt --script res://tests/lesson_10_weapon_upgrades_test.gd
```

Expected: exit 1 because persistent damage and upgrade methods do not exist.

- [ ] **Step 3: Teaching explanation before implementation**

Explain the ownership rule:

```text
Weapon survives for the run
→ persistent attack/damage upgrade state belongs here

Projectile is disposable
→ each new instance receives a snapshot of Weapon.projectile_damage
```

- [ ] **Step 4: Learner implements at least the attack-speed method**

Learner personally writes:

```gdscript
func upgrade_attack_speed() -> void:
    attack_interval = maxf(0.2, attack_interval - 0.1)
    timer.wait_time = attack_interval
```

After they explain why `Timer.wait_time` must change too, AI may complete the surrounding repetitive Weapon changes:

```gdscript
var projectile_damage: int = 1

func upgrade_projectile_damage() -> void:
    projectile_damage += 1
```

Inside `_attack()`, after instantiation and before/after parenting while the object reference is valid:

```gdscript
projectile.set("damage", projectile_damage)
```

- [ ] **Step 5: Run weapon and historical attack tests**

Run:

```powershell
& $godot --headless --path $wt --script res://tests/lesson_10_weapon_upgrades_test.gd
& $godot --headless --path $wt --script res://tests/lesson_06_auto_attack_test.gd
& $godot --headless --path $wt --script res://tests/lesson_07_damage_and_death_test.gd
```

Expected: all PASS.

- [ ] **Step 6: Commit Task 2**

```bash
git add scripts/weapons/weapon.gd tests/lesson_10_weapon_upgrades_test.gd tests/lesson_10_weapon_upgrades_test.gd.uid
git commit -m "feat: add persistent weapon upgrades"
```

---

### Task 3: Paused LevelUpPanel and Upgrade Selection Signal

**Files:**
- Create: `scenes/ui/LevelUpPanel.tscn`
- Create: `scripts/ui/level_up_panel.gd`
- Create: `tests/lesson_10_level_up_panel_test.gd`

**Interfaces:**
- Consumes: no Player or Weapon API.
- Produces: `signal upgrade_selected(upgrade_id: String)`, `show_choices() -> void`, `hide_choices() -> void`.

- [ ] **Step 1: Write the failing panel test**

The test loads `LevelUpPanel.tscn` and checks:

```gdscript
_expect(panel is CanvasLayer, "LevelUpPanel root must be CanvasLayer")
_expect(panel.process_mode == Node.PROCESS_MODE_WHEN_PAUSED, "LevelUpPanel must process while paused")
_expect(panel.has_signal("upgrade_selected"), "LevelUpPanel must define upgrade_selected")
_expect(panel.has_method("show_choices"), "LevelUpPanel must expose show_choices()")
_expect(panel.has_method("hide_choices"), "LevelUpPanel must expose hide_choices()")
_expect(not panel.visible, "LevelUpPanel must start hidden")
```

Verify all three named Buttons exist under the agreed Scene tree.

Connect `upgrade_selected` to an array, pause the SceneTree, emit each Button's `pressed` Signal, and expect:

```gdscript
["move_speed", "attack_speed", "projectile_damage"]
```

Always restore `paused = false` before test cleanup, even on failures.

- [ ] **Step 2: Run and verify RED**

Run:

```powershell
& $godot --headless --path $wt --script res://tests/lesson_10_level_up_panel_test.gd
```

Expected: fail because the Scene does not exist yet.

- [ ] **Step 3: AI scaffolds the Scene only**

Create this minimal structure without implementing the learner's Signal callbacks:

```text
LevelUpPanel (CanvasLayer)
└── Overlay (Control, full rect)
    ├── DimBackground (ColorRect, full rect, semi-transparent)
    └── PanelContainer (centered)
        └── VBoxContainer
            ├── TitleLabel: "LEVEL UP!"
            ├── MoveSpeedButton: "移动速度 +40"
            ├── AttackSpeedButton: "攻击间隔 -0.1 秒"
            └── DamageButton: "子弹伤害 +1"
```

Attach `scripts/ui/level_up_panel.gd`, start hidden, and set the root to `PROCESS_MODE_WHEN_PAUSED`.

- [ ] **Step 4: Teaching Gate — learner writes the UI Signal and callbacks**

Explain that Buttons know only which choice was clicked; they must not know Player/Weapon internals.

Learner writes the conceptual script:

```gdscript
extends CanvasLayer

signal upgrade_selected(upgrade_id: String)

@onready var move_speed_button: Button = $Overlay/PanelContainer/VBoxContainer/MoveSpeedButton
@onready var attack_speed_button: Button = $Overlay/PanelContainer/VBoxContainer/AttackSpeedButton
@onready var damage_button: Button = $Overlay/PanelContainer/VBoxContainer/DamageButton

func _ready() -> void:
    move_speed_button.pressed.connect(_on_move_speed_pressed)
    attack_speed_button.pressed.connect(_on_attack_speed_pressed)
    damage_button.pressed.connect(_on_damage_pressed)
```

And the three explicit callbacks:

```gdscript
func _on_move_speed_pressed() -> void:
    upgrade_selected.emit("move_speed")

func _on_attack_speed_pressed() -> void:
    upgrade_selected.emit("attack_speed")

func _on_damage_pressed() -> void:
    upgrade_selected.emit("projectile_damage")
```

AI may then add the boilerplate visibility methods if not already present:

```gdscript
func show_choices() -> void:
    visible = true

func hide_choices() -> void:
    visible = false
```

- [ ] **Step 5: Run paused-panel test**

Run:

```powershell
& $godot --headless --path $wt --script res://tests/lesson_10_level_up_panel_test.gd
```

Expected: PASS while the test actually sets `SceneTree.paused = true`.

- [ ] **Step 6: Commit Task 3**

```bash
git add scenes/ui/LevelUpPanel.tscn scripts/ui/level_up_panel.gd scripts/ui/level_up_panel.gd.uid tests/lesson_10_level_up_panel_test.gd tests/lesson_10_level_up_panel_test.gd.uid
git commit -m "feat: add paused level up panel"
```

---

### Task 4: Main Coordinator and Queued Upgrade Choices

**Files:**
- Create: `scripts/main/main.gd`
- Modify: `scenes/main/Main.tscn`
- Create: `tests/lesson_10_upgrade_flow_test.gd`

**Interfaces:**
- Consumes: `Player.level_up(new_level)`, `Player.upgrade_move_speed()`, `Weapon.upgrade_attack_speed()`, `Weapon.upgrade_projectile_damage()`, `LevelUpPanel.upgrade_selected(id)`, `show_choices()`, `hide_choices()`.
- Produces: `pending_level_ups: int`; complete pause/choice/resume orchestration.

- [ ] **Step 1: Write the failing integration test**

Load `Main.tscn`, set it as `current_scene`, then stop `EnemySpawner/Timer` and `Player/Weapon/Timer` to keep the test deterministic.

Assert:

```gdscript
_expect(main.get_script() != null, "Main must have coordinator script")
_expect(_has_property(main, &"pending_level_ups"), "Main must track pending level-ups")
_expect(main.get_node_or_null("LevelUpPanel") != null, "Main must instance LevelUpPanel")
```

Use Player's real API to cause two level-ups in one call:

```gdscript
player.call("add_experience", 13)
```

Expected immediately after the synchronous Signal chain:

```gdscript
_expect(int(main.get("pending_level_ups")) == 2, "13 XP must queue two upgrade choices")
_expect(get_tree().paused, "First pending upgrade must pause gameplay")
_expect(panel.visible, "Level-up panel must be visible while paused")
```

Select the first upgrade through the Panel Signal itself:

```gdscript
var starting_speed := float(player.get("speed"))
panel.upgrade_selected.emit("move_speed")

_expect(float(player.get("speed")) == starting_speed + 40.0, "Move choice must upgrade Player speed")
_expect(int(main.get("pending_level_ups")) == 1, "First choice must consume exactly one pending upgrade")
_expect(get_tree().paused, "Gameplay must remain paused while one upgrade is still pending")
_expect(panel.visible, "Panel must remain visible for the second pending choice")
```

Select the second:

```gdscript
var starting_damage := int(weapon.get("projectile_damage"))
panel.upgrade_selected.emit("projectile_damage")

_expect(int(weapon.get("projectile_damage")) == starting_damage + 1, "Damage choice must upgrade Weapon")
_expect(int(main.get("pending_level_ups")) == 0, "Second choice must drain pending queue")
_expect(not get_tree().paused, "Gameplay must resume after final choice")
_expect(not panel.visible, "Panel must hide after final choice")
```

Also test an invalid id while one upgrade is pending:

```gdscript
panel.upgrade_selected.emit("invalid_upgrade")
_expect(int(main.get("pending_level_ups")) == 1, "Invalid upgrade must not consume a pending choice")
_expect(get_tree().paused, "Invalid upgrade must not resume gameplay")
```

- [ ] **Step 2: Run and verify RED**

Run:

```powershell
& $godot --headless --path $wt --script res://tests/lesson_10_upgrade_flow_test.gd
```

Expected: fail because Main has no coordinator script or panel instance.

- [ ] **Step 3: AI adds Main Scene wiring scaffold**

Attach `scripts/main/main.gd` to the Main root and instance `LevelUpPanel.tscn` as `Main/LevelUpPanel`.

The script scaffold declares only references and state:

```gdscript
extends Node2D

var pending_level_ups: int = 0
var level_up_choice_open: bool = false

@onready var player: CharacterBody2D = $Player
@onready var weapon: Node2D = $Player/Weapon
@onready var level_up_panel: CanvasLayer = $LevelUpPanel
```

- [ ] **Step 4: Teaching Gate — learner connects the two event directions**

Explain the two opposite Signal directions:

```text
gameplay → UI:
Player.level_up → Main → show panel / pause

UI → gameplay:
LevelUpPanel.upgrade_selected → Main → Player or Weapon
```

Learner writes:

```gdscript
func _ready() -> void:
    player.connect("level_up", _on_player_level_up)
    level_up_panel.connect("upgrade_selected", _on_upgrade_selected)
```

And writes the first callback:

```gdscript
func _on_player_level_up(_new_level: int) -> void:
    pending_level_ups += 1

    if level_up_choice_open:
        return

    level_up_choice_open = true
    level_up_panel.call("show_choices")
    get_tree().paused = true
```

Stop and verify the learner can explain why the second synchronous `level_up` increments the queue but does not open a second Panel.

- [ ] **Step 5: Complete routing and queue drain**

Implement the routing helper:

```gdscript
func _apply_upgrade(upgrade_id: String) -> bool:
    match upgrade_id:
        "move_speed":
            player.call("upgrade_move_speed")
        "attack_speed":
            weapon.call("upgrade_attack_speed")
        "projectile_damage":
            weapon.call("upgrade_projectile_damage")
        _:
            return false

    return true
```

Implement selection handling:

```gdscript
func _on_upgrade_selected(upgrade_id: String) -> void:
    if not level_up_choice_open:
        return

    if not _apply_upgrade(upgrade_id):
        return

    pending_level_ups -= 1

    if pending_level_ups > 0:
        return

    level_up_choice_open = false
    level_up_panel.call("hide_choices")
    get_tree().paused = false
```

Because the same fixed three choices remain valid for every queued level, leaving the visible Panel open is sufficient while `pending_level_ups > 0`.

- [ ] **Step 6: Run integration and component tests**

Run:

```powershell
& $godot --headless --path $wt --script res://tests/lesson_10_upgrade_flow_test.gd
& $godot --headless --path $wt --script res://tests/lesson_10_level_progression_test.gd
& $godot --headless --path $wt --script res://tests/lesson_10_weapon_upgrades_test.gd
& $godot --headless --path $wt --script res://tests/lesson_10_level_up_panel_test.gd
```

Expected: all PASS and the integration test restores `SceneTree.paused = false` before exit.

- [ ] **Step 7: Commit Task 4**

```bash
git add scripts/main/main.gd scripts/main/main.gd.uid scenes/main/Main.tscn tests/lesson_10_upgrade_flow_test.gd tests/lesson_10_upgrade_flow_test.gd.uid
git commit -m "feat: connect level up choice flow"
```

---

### Task 5: Manual Play Gate, Lesson Documentation, Regression and Checkpoint

**Files:**
- Modify: `scenes/main/Main.tscn`
- Create: `docs/lessons/10-level-up-choice.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: complete Tasks 1–4.
- Produces: learner-visible Lesson 10 checkpoint and verified branch ready for PR.

- [ ] **Step 1: Update Main status label for live verification**

Change:

```text
Lesson 09 - 拾取经验
```

to:

```text
Lesson 10 - 升级三选一
```

- [ ] **Step 2: Open the Lesson 10 worktree in Godot and perform the learner F5 Gate**

Open:

```powershell
& 'D:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --editor --path 'G:\AINmg\Codes\.worktrees\godot-survivor-lab-lesson10'
```

Learner verifies personally:

```text
1. Enemy dies and drops gems.
2. Collect exactly 5 total XP.
3. Combat freezes immediately.
4. LEVEL UP three-choice panel appears.
5. Choose one upgrade.
6. Panel hides and combat resumes.
7. Chosen upgrade has a visible gameplay effect.
8. Reach another level and choose the same upgrade again to verify stacking.
```

Do not proceed to docs/checkpoint until the learner reports the live loop works.

- [ ] **Step 3: Write learner-facing Lesson 10 documentation**

Create `docs/lessons/10-level-up-choice.md` covering the actual path the learner just executed:

- continuity from Lesson 09;
- Player XP threshold, overflow and `while`;
- `level_up` custom Signal;
- why Main coordinates but does not own XP/Weapon state;
- paused SceneTree and `PROCESS_MODE_WHEN_PAUSED`;
- UI-to-gameplay `upgrade_selected` Signal;
- why persistent projectile damage belongs to Weapon, not Projectile;
- pending multi-level choices;
- the three real upgrades;
- short learning checks;
- checkpoint tag `lesson-10-level-up-choice`.

Do not document random skill pools or Resource-based upgrades as if they exist.

- [ ] **Step 4: Update README navigation/progress**

Add:

```markdown
- 已理解经验拾取：进入 [Lesson 10：升级三选一](docs/lessons/10-level-up-choice.md)。
```

Update current progress to state that the full XP → paused choice → real upgrade → resume loop is complete.

- [ ] **Step 5: Remove editor noise and run the complete historical suite**

If Godot rewrites `project.godot` or adds unrelated `unique_id` noise, restore unrelated changes before committing.

Run import if needed, then every course test:

```text
lesson_02_player_movement_test.gd
lesson_03_collision_test.gd
lesson_04_enemy_chase_test.gd
lesson_05_enemy_spawning_test.gd
lesson_06_auto_attack_test.gd
lesson_07_damage_and_death_test.gd
lesson_08_xp_drop_test.gd
lesson_09_deferred_gem_spawn_test.gd
lesson_09_xp_pickup_test.gd
lesson_10_level_progression_test.gd
lesson_10_weapon_upgrades_test.gd
lesson_10_level_up_panel_test.gd
lesson_10_upgrade_flow_test.gd
```

Each must exit 0.

Then run Main headless long enough for real spawning/attacking and explicitly inspect stderr for `SCRIPT ERROR`, `ERROR:`, and physics flushing errors.

Run:

```bash
git diff --check
git status --short
```

Expected: diffcheck 0 and only intentional Lesson 10 changes before commit.

- [ ] **Step 6: Commit docs/final state**

```bash
git add README.md docs/lessons/10-level-up-choice.md scenes/main/Main.tscn
git commit -m "docs: finalize lesson 10 learning state"
```

- [ ] **Step 7: Fresh verification on committed HEAD**

Re-run all Lesson 02–10 tests, Main headless runtime, stderr scan, `git diff --check`, and verify `git status --short` is empty.

Expected: all tests PASS, Main exit 0, stderr clean, working tree clean.

- [ ] **Step 8: Create checkpoint and prepare integration**

Create annotated tag:

```bash
git tag -a lesson-10-level-up-choice -m "Lesson 10: level up choice"
```

Before push, verify:

```powershell
gh auth status
git remote -v
```

Required state:

```text
Active GitHub account: HLRJ
origin: https://github.com/HLRJ/godot-survivor-lab.git
```

Then use the finishing-development-branch workflow for push, PR, normal merge commit, post-merge verification on `main`, worktree cleanup, feature-branch deletion, and tag retention.
