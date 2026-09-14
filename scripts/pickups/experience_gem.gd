extends Area2D

@export var experience_value: int = 1

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("player"):
        return

    body.call("add_experience", experience_value)
    queue_free()