extends CharacterBody2D

@export var speed: float = 110.0
@onready var player: Node2D = get_node("../Player")

func _physics_process(_delta: float) -> void:
    var direction := global_position.direction_to(player.global_position)
    velocity = direction * speed
    move_and_slide()
