extends CharacterBody2D

signal died(dead_enemy: Node2D)

@export var speed: float = 110.0
@export var max_health: int = 3
var health: int

@onready var player: Node2D = get_node("../Player")

func _ready() -> void:
	health = max_health

func _physics_process(_delta: float) -> void:
	var direction := global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		died.emit(self)
		queue_free()
