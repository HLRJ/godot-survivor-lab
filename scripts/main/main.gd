extends Node2D

var pending_level_ups: int = 0
var level_up_choice_open: bool = false

@onready var player: CharacterBody2D = $Player
@onready var weapon: Node2D = $Player/Weapon
@onready var level_up_panel: CanvasLayer = $LevelUpPanel

func _ready() -> void:
    player.connect("level_up", _on_player_level_up)
    level_up_panel.connect("upgrade_selected", _on_upgrade_selected)

func _on_player_level_up(_new_level: int) -> void:
    pending_level_ups += 1

    if level_up_choice_open:
        return

    level_up_choice_open = true
    level_up_panel.call("show_choices")
    get_tree().paused = true

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