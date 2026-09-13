extends SceneTree

var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    failures += 1
    push_error(message)

func _find_enemies(main: Node) -> Array[Node]:
    var enemies: Array[Node] = []
    for child in main.get_children():
        if child.scene_file_path == "res://scenes/enemies/Enemy.tscn":
            enemies.append(child)
    return enemies

func _run() -> void:
    var scene := load("res://scenes/main/Main.tscn") as PackedScene
    _expect(scene != null, "Main.tscn could not be loaded")
    if scene == null:
        quit(1)
        return

    var main := scene.instantiate()
    root.add_child(main)
    var player := main.get_node_or_null("Player") as CharacterBody2D
    var spawner := main.get_node_or_null("EnemySpawner")
    _expect(player != null, "Main must contain Player")
    _expect(spawner != null, "Main must contain EnemySpawner")

    if spawner != null:
        var timer := spawner.get_node_or_null("Timer") as Timer
        _expect(timer != null, "EnemySpawner must contain Timer")
        _expect(is_equal_approx(float(spawner.get("spawn_interval")), 1.5), "EnemySpawner default spawn_interval must be 1.5")
        if timer != null:
            timer.stop()
            timer.wait_time = 0.1
            timer.start()

    for _i in range(40):
        await physics_frame

    var enemies := _find_enemies(main)
    _expect(enemies.size() >= 3, "Enemy count should grow when Timer repeatedly times out")

    for enemy in enemies:
        _expect(enemy.get_parent() == main, "Spawned Enemy must be a direct child of Main")
        if player != null:
            _expect(enemy.get("player") == player, "Spawned Enemy must resolve ../Player to Main/Player")

    main.queue_free()
    await process_frame

    if failures == 0:
        print("PASS: Lesson 05 enemy spawning")
        quit(0)
    else:
        print("FAIL: Lesson 05 enemy spawning (%d failures)" % failures)
        quit(1)
