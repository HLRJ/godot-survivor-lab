extends Node

@export var enemy_scene: PackedScene
@export var experience_scene: PackedScene
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
    var spawned_enemy = enemy_scene.instantiate()

    spawned_enemy.position = spawn_positions[
        spawn_index % spawn_positions.size()
    ]

    spawned_enemy.died.connect(_on_enemy_died)

    spawn_index += 1
    get_parent().add_child(spawned_enemy)

func _on_enemy_died(dead_enemy: Node2D) -> void:
    var experience := experience_scene.instantiate() as Node2D
    experience.global_position = dead_enemy.global_position
    get_parent().add_child(experience)