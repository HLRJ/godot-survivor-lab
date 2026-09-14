extends SceneTree

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _has_property(object: Object, property_name: StringName) -> bool:
    for property in object.get_property_list():
        if property.name == property_name:
            return true
    return false

func _stop_timer(parent: Node, timer_name: StringName) -> void:
    var timer := parent.get_node_or_null(NodePath(timer_name)) as Timer
    if timer != null:
        timer.stop()

func _run() -> void:
    var player_scene := load("res://scenes/player/Player.tscn") as PackedScene
    var gem_scene := load("res://scenes/pickups/ExperienceGem.tscn") as PackedScene
    _expect(player_scene != null, "Player.tscn could not be loaded")
    _expect(gem_scene != null, "ExperienceGem.tscn could not be loaded")
    if player_scene == null or gem_scene == null:
        quit(1)
        return

    var player_preview := player_scene.instantiate()
    var gem_preview := gem_scene.instantiate()

    var player_has_experience := _has_property(player_preview, &"experience")
    var player_has_add_experience := player_preview.has_method("add_experience")
    _expect(player_preview.is_in_group("player"), "Player must belong to the player group")
    _expect(player_has_experience, "Player must expose runtime experience")
    _expect(player_has_add_experience, "Player must implement add_experience(amount)")
    if player_has_experience:
        _expect(int(player_preview.get("experience")) == 0, "Player experience must start at 0")

    _expect(gem_preview is Area2D, "ExperienceGem root must be Area2D")
    _expect(gem_preview.get_node_or_null("CollisionShape2D") is CollisionShape2D, "ExperienceGem must contain CollisionShape2D")
    _expect(gem_preview.get_script() != null, "ExperienceGem must have a pickup script")

    player_preview.free()
    gem_preview.free()

    var world := Node2D.new()
    world.name = "TestWorld"
    root.add_child(world)
    current_scene = world
    var player := player_scene.instantiate() as CharacterBody2D
    var gem := gem_scene.instantiate()
    world.add_child(player)
    var weapon := player.get_node_or_null("Weapon")
    if weapon != null:
        _stop_timer(weapon, "Timer")

    var can_test_pickup := (
        player.is_in_group("player")
        and _has_property(player, &"experience")
        and player.has_method("add_experience")
        and gem is Area2D
        and gem.get_node_or_null("CollisionShape2D") is CollisionShape2D
        and gem.get_script() != null
    )

    if can_test_pickup:
        gem.global_position = player.global_position
        world.add_child(gem)
        await physics_frame
        await physics_frame
        _expect(int(player.get("experience")) == 1, "Picking up one ExperienceGem must add exactly 1 XP")
        _expect(not is_instance_valid(gem) or not gem.is_inside_tree(), "ExperienceGem must leave the Scene Tree after pickup")
    else:
        gem.free()

    world.queue_free()
    await process_frame
    if failures == 0:
        print("PASS: Lesson 09 xp pickup")
        quit(0)
    else:
        print("FAIL: Lesson 09 xp pickup (%d failures)" % failures)
        quit(1)
