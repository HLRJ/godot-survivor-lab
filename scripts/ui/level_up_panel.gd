extends CanvasLayer

signal upgrade_selected(upgrade_id: String)

@onready var move_speed_button: Button = $Overlay/PanelContainer/VBoxContainer/MoveSpeedButton
@onready var attack_speed_button: Button = $Overlay/PanelContainer/VBoxContainer/AttackSpeedButton
@onready var damage_button: Button = $Overlay/PanelContainer/VBoxContainer/DamageButton

func _ready() -> void:
    move_speed_button.pressed.connect(_on_move_speed_pressed)
    attack_speed_button.pressed.connect(_on_attack_speed_pressed)
    damage_button.pressed.connect(_on_damage_pressed)

func _on_move_speed_pressed() -> void:
    upgrade_selected.emit("move_speed")

func _on_attack_speed_pressed() -> void:
    upgrade_selected.emit("attack_speed")

func _on_damage_pressed() -> void:
    upgrade_selected.emit("projectile_damage")

func show_choices() -> void:
    visible = true

func hide_choices() -> void:
    visible = false