# Lesson 11 Upgrade Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Lesson 10's duplicated upgrade labels and magic-number effects with typed `UpgradeData` Resources so editing a `.tres` changes both UI text and real combat values without changing GDScript.

**Architecture:** `UpgradeData : Resource` owns immutable configuration (`id / label / amount`); `LevelUpPanel` displays and emits the selected Resource; `Main` routes by `upgrade.id` and forwards `upgrade.amount`; `Player` and `Weapon` continue to own mutable runtime state and behavior. No random pool, GameManager, Autoload, behavioral Resource, or dynamic button generation is introduced.

**Tech Stack:** Godot 4.7.2 stable, GDScript, text `.tres` Resources, PowerShell, Git/GitHub.

**Spec:** `docs/superpowers/specs/2026-09-21-lesson-11-upgrade-data-design.md`

## Global Constraints

- Windows + Godot 4.7.2 stable + GDScript.
- Chinese-first teaching text; keep official Godot identifiers and code in English.
- Preserve the fixed three-choice gameplay from Lesson 10.
- `UpgradeData` is configuration only; do not store per-run mutable upgrade level/state in Resource.
- Do not introduce random choices, `UpgradePool`, rarity, icons, descriptions, save data, GameManager, Autoload, JSON configuration, Dictionary configuration, or behavioral Resource.
- Keep the attack interval floor at exactly `0.2`.
- Keep `Main` as coordinator; UI must not directly mutate Player/Weapon.
- Every new Godot core concept must use the four-layer explanation: how → why → failure consequence → alternative and why not chosen.
- Learner Gates are hard stops: do not implement the learner's conceptual lines for them before they report completion.
- Use TDD: create/modify the owning test first, verify RED for the intended missing behavior, then implement the minimum GREEN.
- Existing checkpoint tag `lesson-10-level-up-choice` preserves the old Lesson 10 source. Current regression tests may evolve with intentional interfaces while retaining Lesson 10 behavioral assertions.
- Verify GitHub active account is `HLRJ` before push/PR/tag operations.

## Review Focus

1. **Fake data-driven implementation:** changing a Resource amount to a non-default value must change the actual Player/Weapon state, not just the label.
2. **Missing Resource dependency:** all three LevelUpPanel Resource slots must be bound; a missing slot must be caught by tests before normal gameplay.
3. **Shared Resource mutation:** gameplay must not modify `UpgradeData.amount`, `id`, or `label`; repeated selections change Player/Weapon state only.
4. **Invalid upgrade id:** an unknown `UpgradeData.id` must not consume `pending_level_ups` or resume gameplay.
5. **Attack-speed floor:** arbitrary Resource amounts must never drive `attack_interval` or `Timer.wait_time` below `0.2`.

---

## File Structure

### New runtime/data files

- `scripts/upgrades/upgrade_data.gd` — named Resource type; fields only.
- `resources/upgrades/move_speed.tres` — `move_speed / 移动速度 +40 / 40.0`.
- `resources/upgrades/attack_speed.tres` — `attack_speed / 攻击间隔 -0.1 秒 / 0.1`.
- `resources/upgrades/projectile_damage.tres` — `projectile_damage / 子弹伤害 +1 / 1.0`.

### Modified runtime files

- `scripts/player/player.gd` — make movement upgrade accept `amount`.
- `scripts/weapons/weapon.gd` — make attack-speed and projectile-damage upgrades accept `amount`.
- `scripts/ui/level_up_panel.gd` — export three `UpgradeData` references, render labels from data, emit Resource.
- `scenes/ui/LevelUpPanel.tscn` — bind three `.tres` files; remove button labels as source of truth.
- `scripts/main/main.gd` — accept `UpgradeData`, route by `id`, forward `amount`.
- `scenes/main/Main.tscn` — update status copy to Lesson 11 at final documentation task only.

### Tests

- Create `tests/lesson_11_upgrade_data_test.gd`.
- Create `tests/lesson_11_parameterized_upgrades_test.gd`.
- Create `tests/lesson_11_level_up_panel_resource_test.gd`.
- Create `tests/lesson_11_upgrade_flow_test.gd`.
- Modify `tests/lesson_10_weapon_upgrades_test.gd` for intentional method-signature evolution while preserving original assertions.
- Modify `tests/lesson_10_level_up_panel_test.gd` to validate the same three choices via emitted Resource ids.
- Modify `tests/lesson_10_upgrade_flow_test.gd` to emit Resource objects while preserving pause/pending/resume regression coverage.
- `tests/lesson_10_level_progression_test.gd` should remain behaviorally unchanged unless Godot method introspection requires no edit.

### Teaching/docs

- Create `docs/lessons/11-upgrade-data.md`.
- Create `docs/concepts/signal-and-event-flow.md`.
- Create `docs/concepts/deferred-physics-and-lifecycle.md`.
- Create `docs/concepts/scene-tree-pause.md`.
- Create `docs/concepts/resource-and-data-driven-design.md`.
- Modify `README.md` for Lesson 11 navigation/current progress.
- Delete `docs/learning-notes/00-bootstrap.md` after confirming its unique material is already covered by Lesson 00/01 + concepts.
- Keep historical `docs/superpowers/` plans/specs intact even if they mention the old learning-notes era.

---

### Task 1: Add the typed UpgradeData Resource and three data assets

**Files:**
- Create: `scripts/upgrades/upgrade_data.gd`
- Create: `resources/upgrades/move_speed.tres`
- Create: `resources/upgrades/attack_speed.tres`
- Create: `resources/upgrades/projectile_damage.tres`
- Create: `tests/lesson_11_upgrade_data_test.gd`

**Interfaces:**
- Produces: global type `UpgradeData : Resource`.
- Produces fields: `id: StringName`, `label: String`, `amount: float`.
- Produces Resource paths consumed by Tasks 3–4.

- [ ] **Step 1: Write the failing Resource test before creating production files**

Create `tests/lesson_11_upgrade_data_test.gd` with a SceneTree test that avoids static references to `UpgradeData` so the test itself can parse before the class exists:

```gdscript
extends SceneTree

var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _has_property(object: Object, property_name: StringName) -> bool:
    for property in object.get_property_list():
        if property.name == property_name:
            return true
    return false

func _check_resource(path: String, expected_id: StringName, expected_label: String, expected_amount: float) -> void:
    var resource := load(path)
    _expect(resource != null, "%s must load" % path)
    if resource == null:
        return

    _expect(resource is Resource, "%s must be a Resource" % path)
    _expect(_has_property(resource, &"id"), "%s must expose id" % path)
    _expect(_has_property(resource, &"label"), "%s must expose label" % path)
    _expect(_has_property(resource, &"amount"), "%s must expose amount" % path)

    if _has_property(resource, &"id"):
        _expect(StringName(resource.get("id")) == expected_id, "%s id mismatch" % path)
    if _has_property(resource, &"label"):
        _expect(String(resource.get("label")) == expected_label, "%s label mismatch" % path)
    if _has_property(resource, &"amount"):
        _expect(abs(float(resource.get("amount")) - expected_amount) < 0.001, "%s amount mismatch" % path)

func _run() -> void:
    var script := load("res://scripts/upgrades/upgrade_data.gd")
    _expect(script != null, "upgrade_data.gd must exist")
    if script != null:
        var sample := script.new()
        _expect(sample is Resource, "UpgradeData must extend Resource")
        _expect(_has_property(sample, &"id"), "UpgradeData must export id")
        _expect(_has_property(sample, &"label"), "UpgradeData must export label")
        _expect(_has_property(sample, &"amount"), "UpgradeData must export amount")

    _check_resource(
        "res://resources/upgrades/move_speed.tres",
        &"move_speed",
        "移动速度 +40",
        40.0
    )
    _check_resource(
        "res://resources/upgrades/attack_speed.tres",
        &"attack_speed",
        "攻击间隔 -0.1 秒",
        0.1
    )
    _check_resource(
        "res://resources/upgrades/projectile_damage.tres",
        &"projectile_damage",
        "子弹伤害 +1",
        1.0
    )

    if failures == 0:
        print("PASS: Lesson 11 upgrade data")
        quit(0)
    else:
        print("FAIL: Lesson 11 upgrade data (%d failures)" % failures)
        quit(1)
```

- [ ] **Step 2: Run the new test and verify the intended RED**

Run with the existing Godot executable:

```powershell
$godot = 'D:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
$wt = 'G:\AINmg\Codes\.worktrees\godot-survivor-lab-lesson11'
$p = Start-Process -FilePath $godot -ArgumentList @(
  '--headless','--path',$wt,
  '--script','res://tests/lesson_11_upgrade_data_test.gd'
) -Wait -PassThru -NoNewWindow
$p.ExitCode
```

Expected: non-zero test result with missing `upgrade_data.gd` / missing `.tres` assertions. Do not accept a parser error in the test itself as the intended RED.

- [ ] **Step 3 — LEARNER GATE 1: learner writes the UpgradeData type**

Create `scripts/upgrades/upgrade_data.gd`, but stop before filling the conceptual lines. Ask the learner to write exactly:

```gdscript
class_name UpgradeData
extends Resource

@export var id: StringName
@export var label: String
@export var amount: float
```

Before running, ask for predictions:

- Does `UpgradeData` enter the SceneTree? No.
- What makes `UpgradeData` a project-level type? `class_name`.
- What makes its fields editable in Inspector? `@export`.

Wait for learner confirmation before continuing.

- [ ] **Step 4: Import the new global class and verify the script loads**

Run one fresh import after the learner saves:

```powershell
$p = Start-Process -FilePath $godot -ArgumentList @(
  '--headless','--path',$wt,'--import'
) -Wait -PassThru -NoNewWindow
if ($p.ExitCode -ne 0) { exit $p.ExitCode }
```

Restore `project.godot` if the editor/import produces unrelated noise.

- [ ] **Step 5 — LEARNER GATE 2: learner creates the first .tres in Godot**

Open the Lesson 11 worktree in Godot. Learner creates a new `UpgradeData` Resource in Inspector and saves it as:

```text
res://resources/upgrades/move_speed.tres
```

Set:

```text
id     = move_speed
label  = 移动速度 +40
amount = 40.0
```

After save, inspect the actual file and explain:

```text
UpgradeData.gd = type definition
move_speed.tres = one concrete data asset
```

Wait for learner confirmation.

- [ ] **Step 6: Create the two repetitive Resource assets**

Create the two remaining assets using the same registered `UpgradeData` script:

```text
attack_speed.tres:
id     = attack_speed
label  = 攻击间隔 -0.1 秒
amount = 0.1

projectile_damage.tres:
id     = projectile_damage
label  = 子弹伤害 +1
amount = 1.0
```

Prefer using Godot-generated Resource serialization or matching the exact serialization of the learner-created `move_speed.tres`; do not invent UID values manually.

- [ ] **Step 7: Run the Resource test and verify GREEN**

Run `lesson_11_upgrade_data_test.gd`.

Expected:

```text
PASS: Lesson 11 upgrade data
exit=0
```

Then run `git diff --check`.

- [ ] **Step 8: Commit Task 1**

Verify `gh api user --jq .login` returns `HLRJ`.

Commit:

```bash
git add scripts/upgrades resources/upgrades tests/lesson_11_upgrade_data_test.gd*
git commit -m "feat: add upgrade data resources"
```

---

### Task 2: Parameterize Player and Weapon upgrade behavior

**Files:**
- Create: `tests/lesson_11_parameterized_upgrades_test.gd`
- Modify: `scripts/player/player.gd`
- Modify: `scripts/weapons/weapon.gd`
- Modify: `tests/lesson_10_weapon_upgrades_test.gd`

**Interfaces:**
- Consumes: numeric `UpgradeData.amount` values from later Main routing.
- Produces: `Player.upgrade_move_speed(amount: float) -> void`.
- Produces: `Weapon.upgrade_attack_speed(amount: float) -> void`.
- Produces: `Weapon.upgrade_projectile_damage(amount: int) -> void`.

- [ ] **Step 1: Write an anti-hardcoding RED test with non-default numbers**

Create `tests/lesson_11_parameterized_upgrades_test.gd`. Instantiate Player, stop `Weapon/Timer`, and assert:

```gdscript
var starting_speed := float(player.get("speed"))
player.call("upgrade_move_speed", 73.0)
_expect(
    abs(float(player.get("speed")) - (starting_speed + 73.0)) < 0.001,
    "Move speed upgrade must use the provided 73 amount"
)

var starting_interval := float(weapon.get("attack_interval"))
weapon.call("upgrade_attack_speed", 0.23)
_expect(
    abs(float(weapon.get("attack_interval")) - (starting_interval - 0.23)) < 0.001,
    "Attack speed upgrade must use the provided 0.23 amount"
)
_expect(
    abs(timer.wait_time - float(weapon.get("attack_interval"))) < 0.001,
    "Timer.wait_time must follow parameterized attack interval"
)

var starting_damage := int(weapon.get("projectile_damage"))
weapon.call("upgrade_projectile_damage", 4)
_expect(
    int(weapon.get("projectile_damage")) == starting_damage + 4,
    "Projectile damage upgrade must use the provided 4 amount"
)
```

Then repeatedly call:

```gdscript
for _i in range(20):
    weapon.call("upgrade_attack_speed", 0.23)

_expect(
    abs(float(weapon.get("attack_interval")) - 0.2) < 0.001,
    "Parameterized attack speed must keep the 0.2 floor"
)
_expect(
    abs(timer.wait_time - 0.2) < 0.001,
    "Timer floor must remain 0.2"
)
```

Also pin Review Focus #3 with an explicit immutability assertion:

```gdscript
var move_data := load("res://resources/upgrades/move_speed.tres")
var configured_amount := float(move_data.get("amount"))

player.call("upgrade_move_speed", configured_amount)
player.call("upgrade_move_speed", configured_amount)

_expect(
    abs(float(move_data.get("amount")) - configured_amount) < 0.001,
    "Applying upgrades must not mutate UpgradeData.amount"
)
```

The Player state should change twice; the shared Resource definition must not change.

- [ ] **Step 2: Run the new test and verify RED**

Expected: current no-argument methods reject or ignore the supplied arguments; state does not become `+73 / -0.23 / +4`.

The RED must come from missing parameterized behavior, not unrelated scene loading.

- [ ] **Step 3 — LEARNER GATE 3: learner removes the first magic number**

Show the Lesson 10 code:

```gdscript
func upgrade_move_speed() -> void:
    speed += 40.0
```

Ask the learner to change it to:

```gdscript
func upgrade_move_speed(amount: float) -> void:
    speed += amount
```

Before running, ask them to predict the result of:

```text
speed = 220
upgrade_move_speed(73)
```

Expected prediction: `293`.

Wait for save/confirmation.

- [ ] **Step 4: Complete the repetitive Weapon parameterization**

Change:

```gdscript
func upgrade_attack_speed(amount: float) -> void:
    attack_interval = maxf(0.2, attack_interval - amount)
    timer.wait_time = attack_interval

func upgrade_projectile_damage(amount: int) -> void:
    projectile_damage += amount
```

Do not add default values such as `amount = 0.1` or `amount = 1`; that would reintroduce balancing magic numbers into behavior code.

- [ ] **Step 5: Update Lesson 10 weapon regression test for the intentional interface change**

Preserve its original checks but make its calls explicit:

```gdscript
weapon.call("upgrade_attack_speed", 0.1)
...
for _i in range(20):
    weapon.call("upgrade_attack_speed", 0.1)
...
weapon.call("upgrade_projectile_damage", 1)
```

Keep assertions that:

- first attack-speed choice changes `0.8 → 0.7`;
- Timer follows;
- floor remains `0.2`;
- damage `1 → 2`;
- newly spawned Projectile receives the upgraded damage.

This retains Lesson 10 behavioral regression coverage without forcing production code to keep hardcoded default increments.

- [ ] **Step 6: Run Task 2 tests and verify GREEN**

Run:

```text
lesson_11_parameterized_upgrades_test.gd
lesson_10_weapon_upgrades_test.gd
lesson_10_level_progression_test.gd
lesson_06_auto_attack_test.gd
lesson_07_damage_and_death_test.gd
```

Expected: all exit `0`.

- [ ] **Step 7: Commit Task 2**

```bash
git add scripts/player/player.gd scripts/weapons/weapon.gd   tests/lesson_10_weapon_upgrades_test.gd*   tests/lesson_11_parameterized_upgrades_test.gd*
git commit -m "feat: parameterize upgrade effects"
```

---

### Task 3: Make LevelUpPanel display and emit UpgradeData

**Files:**
- Create: `tests/lesson_11_level_up_panel_resource_test.gd`
- Modify: `scripts/ui/level_up_panel.gd`
- Modify: `scenes/ui/LevelUpPanel.tscn`
- Modify: `tests/lesson_10_level_up_panel_test.gd`

**Interfaces:**
- Consumes: the three concrete UpgradeData Resources from Task 1.
- Produces signal: `upgrade_selected(upgrade: UpgradeData)`.
- Produces exported fields: `move_speed_upgrade / attack_speed_upgrade / projectile_damage_upgrade: UpgradeData`.

- [ ] **Step 1: Write the Resource-driven UI RED test**

Create a test that loads `upgrade_data.gd` dynamically and creates three test Resource objects with deliberately non-default labels:

```gdscript
var upgrade_script := load("res://scripts/upgrades/upgrade_data.gd")

func _make_upgrade(id: StringName, label: String, amount: float) -> Resource:
    var upgrade := upgrade_script.new()
    upgrade.set("id", id)
    upgrade.set("label", label)
    upgrade.set("amount", amount)
    return upgrade
```

First instantiate an untouched preview from `LevelUpPanel.tscn` **without adding it to the tree** and verify the real Scene wiring:

```gdscript
var preview := panel_scene.instantiate()
_expect(preview.get("move_speed_upgrade") != null, "Scene must bind move_speed UpgradeData")
_expect(preview.get("attack_speed_upgrade") != null, "Scene must bind attack_speed UpgradeData")
_expect(preview.get("projectile_damage_upgrade") != null, "Scene must bind projectile_damage UpgradeData")
preview.free()
```

This assertion must remain after implementation and directly pins Review Focus #2.

Then instantiate a second panel for data-source testing, set three deliberately non-default Resource objects **before adding it to the tree**:

```gdscript
panel.set("move_speed_upgrade", _make_upgrade(&"move_speed", "测试移动 +73", 73.0))
panel.set("attack_speed_upgrade", _make_upgrade(&"attack_speed", "测试攻速 -0.23", 0.23))
panel.set("projectile_damage_upgrade", _make_upgrade(&"projectile_damage", "测试伤害 +4", 4.0))
root.add_child(panel)
```

Then assert:

```text
MoveSpeedButton.text == "测试移动 +73"
AttackSpeedButton.text == "测试攻速 -0.23"
DamageButton.text == "测试伤害 +4"
```

Connect `upgrade_selected`, emit each Button's `pressed` while `paused = true`, and assert the three emitted objects are the exact three Resource instances supplied to the panel (`is_same()` or identity `==`).

- [ ] **Step 2: Run the UI Resource test and verify RED**

Expected failures:

- missing exported Resource properties;
- button text still comes from TSCN;
- signal still emits String ids rather than Resource objects.

- [ ] **Step 3: Add exported UpgradeData dependencies and Resource labels**

Update `scripts/ui/level_up_panel.gd`:

```gdscript
extends CanvasLayer

signal upgrade_selected(upgrade: UpgradeData)

@export var move_speed_upgrade: UpgradeData
@export var attack_speed_upgrade: UpgradeData
@export var projectile_damage_upgrade: UpgradeData

@onready var move_speed_button: Button = $Overlay/PanelContainer/VBoxContainer/MoveSpeedButton
@onready var attack_speed_button: Button = $Overlay/PanelContainer/VBoxContainer/AttackSpeedButton
@onready var damage_button: Button = $Overlay/PanelContainer/VBoxContainer/DamageButton

func _ready() -> void:
    move_speed_button.text = move_speed_upgrade.label
    attack_speed_button.text = attack_speed_upgrade.label
    damage_button.text = projectile_damage_upgrade.label

    move_speed_button.pressed.connect(_on_move_speed_pressed)
    attack_speed_button.pressed.connect(_on_attack_speed_pressed)
    damage_button.pressed.connect(_on_damage_pressed)
```

Do not add fallback hardcoded labels. Missing dependencies should be caught by tests/configuration instead of silently masking broken wiring.

- [ ] **Step 4 — LEARNER GATE 4: learner changes one callback to emit a Resource**

Ask the learner to change the move-speed callback from:

```gdscript
upgrade_selected.emit("move_speed")
```

to:

```gdscript
upgrade_selected.emit(move_speed_upgrade)
```

Ask them to explain:

```text
Button.pressed
→ callback
→ emit(Resource object reference)
→ every subscriber receives that object
```

Wait for confirmation, then complete the two repetitive callbacks:

```gdscript
func _on_attack_speed_pressed() -> void:
    upgrade_selected.emit(attack_speed_upgrade)

func _on_damage_pressed() -> void:
    upgrade_selected.emit(projectile_damage_upgrade)
```

- [ ] **Step 5: Bind the three .tres assets in LevelUpPanel.tscn**

Add the three UpgradeData ext_resources and assign on the root `LevelUpPanel`:

```text
move_speed_upgrade = ExtResource(...)
attack_speed_upgrade = ExtResource(...)
projectile_damage_upgrade = ExtResource(...)
```

Do not rely on the Button `text = ...` fields as source of truth. Set all three TSCN Button texts to the neutral editor text `"Upgrade"`; runtime `_ready()` must overwrite them from Resource labels.

- [ ] **Step 6: Update the Lesson 10 paused-panel regression test**

Change `emitted_upgrades: Array[String]` into an untyped or Resource array and have the callback append the emitted Resource.

After pressing all three buttons while paused, assert:

```gdscript
_expect(StringName(emitted_upgrades[0].get("id")) == &"move_speed", ...)
_expect(StringName(emitted_upgrades[1].get("id")) == &"attack_speed", ...)
_expect(StringName(emitted_upgrades[2].get("id")) == &"projectile_damage", ...)
```

Keep the existing assertions that:

- root is `CanvasLayer`;
- process mode is `PROCESS_MODE_WHEN_PAUSED`;
- panel starts hidden;
- buttons exist;
- paused buttons remain interactive.

- [ ] **Step 7: Run UI tests and verify GREEN**

Run:

```text
lesson_11_level_up_panel_resource_test.gd
lesson_10_level_up_panel_test.gd
```

Expected: both pass with `paused` restored to `false` during cleanup.

- [ ] **Step 8: Commit Task 3**

```bash
git add scripts/ui/level_up_panel.gd* scenes/ui/LevelUpPanel.tscn   tests/lesson_10_level_up_panel_test.gd*   tests/lesson_11_level_up_panel_resource_test.gd*
git commit -m "feat: drive level up panel from resources"
```

---

### Task 4: Route UpgradeData through Main without changing pause/queue behavior

**Files:**
- Create: `tests/lesson_11_upgrade_flow_test.gd`
- Modify: `scripts/main/main.gd`
- Modify: `tests/lesson_10_upgrade_flow_test.gd`

**Interfaces:**
- Consumes: `upgrade_selected(upgrade: UpgradeData)`.
- Consumes fields: `upgrade.id: StringName`, `upgrade.amount: float`.
- Produces same Lesson 10 queue semantics: one valid choice consumes exactly one pending upgrade; unknown id consumes none.

- [ ] **Step 1: Write the Main Resource-routing RED test**

Load Main, stop spawner/weapon timers, and create Resource objects through `upgrade_data.gd`:

```gdscript
func _make_upgrade(id: StringName, amount: float) -> Resource:
    var script := load("res://scripts/upgrades/upgrade_data.gd")
    var upgrade := script.new()
    upgrade.set("id", id)
    upgrade.set("label", "test")
    upgrade.set("amount", amount)
    return upgrade
```

Queue two choices with:

```gdscript
player.call("add_experience", 13)
```

Assert `pending_level_ups == 2`, `paused == true`, panel visible.

Emit:

```gdscript
panel.emit_signal(
    "upgrade_selected",
    _make_upgrade(&"move_speed", 73.0)
)
```

Assert:

```text
Player.speed increases exactly 73
pending: 2 → 1
paused stays true
panel stays visible
```

Then emit damage `amount = 4.0` and assert:

```text
projectile_damage +4
pending: 1 → 0
paused false
panel hidden
```

Queue one more level, then emit:

```gdscript
_make_upgrade(&"invalid_upgrade", 999.0)
```

Assert pending remains `1`, paused remains true, Player/Weapon relevant states unchanged. This pins Review Focus #4.

Finally emit attack-speed `0.23` and assert valid routing drains the queue and resumes.

- [ ] **Step 2: Run the Main Resource-routing test and verify RED**

Expected: current Main expects String ids and cannot use Resource id/amount.

- [ ] **Step 3: Change Main callback and routing signatures**

Change:

```gdscript
func _apply_upgrade(upgrade: UpgradeData) -> bool:
    match upgrade.id:
        &"move_speed":
            player.call("upgrade_move_speed", upgrade.amount)
        &"attack_speed":
            weapon.call("upgrade_attack_speed", upgrade.amount)
        &"projectile_damage":
            weapon.call("upgrade_projectile_damage", int(upgrade.amount))
        _:
            return false

    return true
```

and:

```gdscript
func _on_upgrade_selected(upgrade: UpgradeData) -> void:
    if not level_up_choice_open:
        return

    if not _apply_upgrade(upgrade):
        return

    pending_level_ups -= 1

    if pending_level_ups > 0:
        return

    level_up_choice_open = false
    level_up_panel.call("hide_choices")
    get_tree().paused = false
```

Do not move upgrade behavior into Main; Main passes data onward.

- [ ] **Step 4 — LEARNER GATE 5: learner writes the move-speed route**

Before completing all branches, present the old Lesson 10 branch:

```gdscript
"move_speed":
    player.call("upgrade_move_speed")
```

Ask the learner to write the new equivalent:

```gdscript
&"move_speed":
    player.call("upgrade_move_speed", upgrade.amount)
```

Ask them to explain which part is routing data (`id`) and which part is effect data (`amount`). Wait for confirmation, then finish the repetitive Weapon branches.

- [ ] **Step 5: Update Lesson 10 flow regression to emit the actual panel Resources**

Instead of emitting bare strings, read the bound Resources from panel properties:

```gdscript
var move_upgrade := panel.get("move_speed_upgrade")
var attack_upgrade := panel.get("attack_speed_upgrade")
var damage_upgrade := panel.get("projectile_damage_upgrade")
```

Emit them while preserving the original Lesson 10 assertions:

```gdscript
panel.emit_signal("upgrade_selected", move_upgrade)
...
panel.emit_signal("upgrade_selected", damage_upgrade)
...
panel.emit_signal("upgrade_selected", attack_upgrade)
```

For the invalid-id branch, create a temporary `UpgradeData` with `id = &"invalid_upgrade"` and assert it does not consume pending state.

- [ ] **Step 6: Run Task 4 tests and full current suite**

First run:

```text
lesson_11_upgrade_flow_test.gd
lesson_10_upgrade_flow_test.gd
```

Then run every `tests/lesson_*_test.gd` in filename order.

Expected after Task 4: all Lesson 02–11 tests pass. At this point expected count is 17 test scripts if exactly four Lesson 11 tests were added.

- [ ] **Step 7: Commit Task 4**

```bash
git add scripts/main/main.gd   tests/lesson_10_upgrade_flow_test.gd*   tests/lesson_11_upgrade_flow_test.gd*
git commit -m "feat: route resource upgrades through main"
```

---

### Task 5: Perform the learner-visible data-driven causality experiment

**Files:**
- Temporarily modify then restore: `resources/upgrades/move_speed.tres`
- No permanent source change required unless the experiment reveals a defect.

**Interfaces:**
- Validates end-to-end: Resource → Panel label + Main amount → Player state.

- [ ] **Step 1: Open the Lesson 11 worktree in Godot**

Open:

```text
G:\AINmg\Codes\.worktrees\godot-survivor-lab-lesson11
```

Run F5 once with normal `+40` data to verify the post-refactor loop still works.

- [ ] **Step 2 — LEARNER GATE: predict and edit only move_speed.tres**

Ask the learner to change only the Resource in Inspector:

```text
label  = 移动速度 +80
amount = 80
```

Do not edit any `.gd` file.

Before F5, ask the learner to predict both visible and runtime effects.

- [ ] **Step 3: F5 and verify both sides of the data source**

Learner verifies:

```text
Button text:
移动速度 +80

Actual gameplay:
one selection increases speed by 80
```

If only one side changes, stop and debug the hardcoded path before proceeding.

- [ ] **Step 4: Demonstrate missing exported dependency, then restore it**

In Inspector temporarily clear one LevelUpPanel Resource slot and predict the failure mode. Observe the null/configuration error, explain that `@export` exposes a dependency but does not satisfy it, then restore the correct Resource.

Do not commit the deliberately broken state.

- [ ] **Step 5: Restore canonical teaching data and verify clean diff**

Restore move speed to:

```text
label  = 移动速度 +40
amount = 40
```

Verify no accidental `.tres` experiment diff remains unless Godot serialized harmless canonical metadata that should be reviewed.

- [ ] **Step 6: Run full suite after the manual experiment**

Run every `tests/lesson_*_test.gd`.

Then run Main headless for approximately 360 frames and scan combined output for:

```text
SCRIPT ERROR
ERROR:
flushing queries
```

Expected: exit `0`, zero error matches.

No commit is needed for this task unless a defect is fixed.

---

### Task 6: Finish Lesson 11 teaching docs and concept debt

**Files:**
- Create: `docs/lessons/11-upgrade-data.md`
- Create: `docs/concepts/resource-and-data-driven-design.md`
- Create: `docs/concepts/signal-and-event-flow.md`
- Create: `docs/concepts/deferred-physics-and-lifecycle.md`
- Create: `docs/concepts/scene-tree-pause.md`
- Modify: `README.md`
- Modify: `scenes/main/Main.tscn`
- Delete: `docs/learning-notes/00-bootstrap.md`

**Interfaces:**
- Produces the public learning path for Lesson 11.
- Consolidates reusable mental models learned in Lessons 08–11.
- Retires the duplicate learning-notes structure without deleting historical Git history.

- [ ] **Step 1: Confirm bootstrap note information is already covered before deleting it**

Read `docs/learning-notes/00-bootstrap.md` and verify each topic has a live home:

```text
project.godot       → Lesson 00
Scene / Node        → Lesson 01 + scene-and-node.md
.godot ignore/cache → Lesson 00 / repository setup explanation
learning principle  → README + learning-first-course-design.md
```

Only after all four are confirmed, delete `docs/learning-notes/00-bootstrap.md`. Do not delete the directory if another file unexpectedly exists.

- [ ] **Step 2: Write Lesson 11 using the standard template and four-layer rule**

`docs/lessons/11-upgrade-data.md` must include:

1. 本课目标 / 完成效果.
2. 前置知识：Lesson 10 Signal、Main 协调、Player/Weapon 状态归属.
3. 本课新增：`Resource`, `.tres`, `class_name`, 数据/行为分离.
4. Lesson 10 → 11 key diff:
   ```text
   "移动速度 +40" + speed += 40
   →
   UpgradeData(label, amount) + speed += amount
   ```
5. Resource vs Node / PackedScene runtime model.
6. `class_name` connection to the Lesson 10 static-type question.
7. UI binding and Resource Signal flow.
8. Main routing with `id` vs `amount`.
9. Shared Resource immutability rule.
10. Causality experiment `+40 → +80` without GDScript edits.
11. Missing Resource slot failure experiment.
12. Alternatives table: Dictionary / JSON / Singleton / behavioral Resource.
13. Learning check that asks the learner to explain:
   - why Resource exists now but was not needed in Lesson 10;
   - why current level/count is not stored in UpgradeData;
   - difference between `id` routing and `amount` effect;
   - why changing only `.tres` affects both label and behavior.
14. Checkpoint `lesson-11-upgrade-data`.

- [ ] **Step 3: Write Resource concept page**

`docs/concepts/resource-and-data-driven-design.md` must be reusable outside Lesson 11 and include these exact conceptual sections:

```text
Resource / .tres / Node / Scene 的关系
class_name 与自定义静态类型
@export Resource 引用
配置数据 vs 运行时状态
共享引用与“只读配置”纪律
为什么用 Resource
写错/漏绑会发生什么
Resource vs Dictionary / JSON / Singleton / 行为型 Resource
何时应该升级到行为型 Resource
```

Do not repeat the entire Lesson walkthrough.

- [ ] **Step 4: Backfill Signal concept debt from Lessons 08–10**

Create `docs/concepts/signal-and-event-flow.md` with:

```text
signal definition
connect = persistent subscription
emit = one event occurrence
callback parameters come from emit
one Signal → multiple listeners
repeated emits → repeated callbacks
built-in vs custom Signal
timer.timeout.connect(...) vs player.connect("level_up", ...)
static type limitation and future class_name option
when direct function calls are simpler
what coupling appears if everything becomes Signals
```

Four-layer comparison must explicitly answer “Signal vs direct call”.

- [ ] **Step 5: Backfill deferred physics/lifecycle concept debt**

Create `docs/concepts/deferred-physics-and-lifecycle.md` around the actual Lesson 09 failure:

```text
physics query callback
Enemy death Signal is synchronous
adding a new Area2D during physics flush can fail
queue_free is deferred removal
call_deferred moves work across the unsafe timing boundary
snapshot stable Vector2 position before the dying object disappears
when NOT to use call_deferred blindly
alternative: queue/event processing layer, and why it was unnecessary here
```

Organize the core explanation explicitly as: 怎么做 → 为什么 → 如果在 physics flush 里直接 add_child 会怎样 → 还能用队列/事件层怎么设计、为什么当前没选。

- [ ] **Step 6: Backfill SceneTree pause concept debt**

Create `docs/concepts/scene-tree-pause.md` covering:

```text
get_tree().paused
Node.process_mode
PROCESS_MODE_WHEN_PAUSED
why gameplay stops but LevelUpPanel remains interactive
paused does not terminate the current synchronous call stack
why multi-level while can keep emitting after paused becomes true
SceneTree pause vs custom game_paused bool
when a custom state machine might become necessary later
```

Organize the core explanation explicitly as: 怎么做 → 为什么 → process_mode 配错会出现什么 → custom game_paused/state machine 还能怎么做、为什么当前用 SceneTree pause。

- [ ] **Step 7: Update README and Main status**

Add:

```markdown
- 已理解升级三选一：进入 [Lesson 11：升级数据化](docs/lessons/11-upgrade-data.md)。
```

Update current progress to summarize Resource-driven upgrade data and the `+40 → +80` experiment.

Update `scenes/main/Main.tscn` status text to:

```text
Lesson 11 - 升级数据化
```

- [ ] **Step 8: Validate docs structurally**

Run:

```powershell
Select-String -Path docs\lessons\11-upgrade-data.md -Pattern '^## '
Select-String -Path docs\concepts\*.md -Pattern 'TBD|TODO|FIXME|PLACEHOLDER'
git grep -n 'docs/learning-notes\|learning-notes/' -- ':!docs/superpowers/plans/*' ':!docs/superpowers/specs/2026-09-12-godot-survivor-lab-design.md'
git diff --check
```

Expected:

- no placeholders;
- no active README/current course dependency on `learning-notes`;
- historical superpowers design/plan references may remain as history;
- diff check clean.

- [ ] **Step 9: Run final automated + runtime verification**

Run every Lesson test. Expected if no extra test files were added:

```text
17 / 17 PASS
```

Then Main headless:

```text
exit=0
SCRIPT ERROR matches=0
ERROR: matches=0
flushing queries matches=0
```

Verify:

```text
git diff --check = 0
gh_active = HLRJ
```

- [ ] **Step 10: Commit final learning state**

```bash
git add README.md scenes/main/Main.tscn docs/lessons docs/concepts
git add -A docs/learning-notes
git commit -m "docs: finalize lesson 11 learning state"
```

Do not create/push the tag until the learner reports final F5 acceptance and the final branch review is clean.

---

### Task 7: Final branch review, checkpoint, and integration handoff

**Files:**
- No production changes expected unless review finds a real issue.

**Interfaces:**
- Final checkpoint tag: `lesson-11-upgrade-data`.

- [ ] **Step 1: Run verification on the exact HEAD to be integrated**

Run:

- all `tests/lesson_*_test.gd`;
- Main headless runtime;
- error scan;
- `git diff --check`;
- `git status --short`.

Expected: all green and clean.

- [ ] **Step 2: Review the full branch against the spec**

Review:

```text
base = e4ccce0
head = current HEAD
```

Focus specifically on the five Review Focus items at the top of this plan.

If no independent reviewer/subagent tool is available, explicitly record that the final review was a self-review and is weaker than independent review.

- [ ] **Step 3: Create the local annotated checkpoint only after learner acceptance**

Create:

```bash
git tag -a lesson-11-upgrade-data -m "Lesson 11: upgrade data"
```

The tag should point to the `docs: finalize lesson 11 learning state` commit, preserving the same checkpoint convention used by Lessons 08–10.

- [ ] **Step 4: Use finishing-development-branch workflow**

Present the standard three integration choices:

```text
1. Merge back to main locally
2. Push and create a Pull Request
3. Keep the branch as-is
```

Do not push, merge, delete the branch, remove the worktree, or push the tag before the learner chooses.

If PR flow is chosen, verify `HLRJ` first, push the branch, create PR against `main`, keep worktree for feedback, and only merge/cleanup/tag-push after explicit later approval.
