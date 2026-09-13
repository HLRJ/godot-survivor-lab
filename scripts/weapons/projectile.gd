extends Node2D

@export var speed: float = 520.0
var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
    position += direction * speed * delta
    if position.x < -100.0 or position.x > 1380.0 or position.y < -100.0 or position.y > 820.0:
        queue_free()
