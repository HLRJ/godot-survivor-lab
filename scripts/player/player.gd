extends CharacterBody2D

signal level_up(new_level: int)

@export var speed: float = 220.0
var experience: int = 0
var level: int = 1
var experience_to_next_level: int = 5

func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed
    move_and_slide()

func add_experience(amount: int) -> void:
    if amount <= 0:
        return

    experience += amount

    while experience >= experience_to_next_level:
        experience -= experience_to_next_level
        level += 1
        experience_to_next_level += 3
        level_up.emit(level)

func upgrade_move_speed() -> void:
    speed += 40.0