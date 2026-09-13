extends Node

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.5
@onready var timer: Timer = $Timer

var spawn_positions: Array[Vector2] = [
    Vector2(160, 220),
    Vector2(160, 520),
    Vector2(420, 120),
    Vector2(420, 600),
]
var spawn_index: int = 0

func _ready() -> void:
    timer.wait_time = spawn_interval
    timer.timeout.connect(_spawn_enemy)
    timer.start()

func _spawn_enemy() -> void:
    var enemy := enemy_scene.instantiate() as CharacterBody2D
    enemy.position = spawn_positions[spawn_index % spawn_positions.size()]
    spawn_index += 1
    get_parent().add_child(enemy)
