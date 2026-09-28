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

func _on_move_speed_pressed() -> void:
    upgrade_selected.emit(move_speed_upgrade)

func _on_attack_speed_pressed() -> void:
    upgrade_selected.emit(attack_speed_upgrade)

func _on_damage_pressed() -> void:
    upgrade_selected.emit(projectile_damage_upgrade)

func show_choices() -> void:
    visible = true

func hide_choices() -> void:
    visible = false