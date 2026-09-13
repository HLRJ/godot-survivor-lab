extends Node2D

const ENEMY_SCENE_PATH := "res://scenes/enemies/Enemy.tscn"

@export var projectile_scene: PackedScene
@export var attack_interval: float = 0.8
@onready var timer: Timer = $Timer

func _ready() -> void:
    timer.wait_time = attack_interval
    timer.timeout.connect(_attack)
    timer.start()

func _attack() -> void:
    var target := _find_nearest_enemy()
    if target == null or projectile_scene == null:
        return
    var projectile := projectile_scene.instantiate() as Node2D
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = global_position
    projectile.set("direction", global_position.direction_to(target.global_position))

func _find_nearest_enemy() -> Node2D:
    var nearest: Node2D = null
    var nearest_distance := INF
    for child in get_tree().current_scene.get_children():
        if not child is Node2D:
            continue
        var candidate := child as Node2D
        if candidate.scene_file_path != ENEMY_SCENE_PATH:
            continue
        var distance := global_position.distance_squared_to(candidate.global_position)
        if distance < nearest_distance:
            nearest = candidate
            nearest_distance = distance
    return nearest
