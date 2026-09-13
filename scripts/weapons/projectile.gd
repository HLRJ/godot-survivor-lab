extends Area2D

const ENEMY_SCENE_PATH := "res://scenes/enemies/Enemy.tscn"

@export var speed: float = 520.0
@export var damage: int = 1
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    position += direction * speed * delta
    if position.x < -100.0 or position.x > 1380.0 or position.y < -100.0 or position.y > 820.0:
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body.scene_file_path != ENEMY_SCENE_PATH:
        return
    if body.has_method("take_damage"):
        body.call("take_damage", damage)
    queue_free()
