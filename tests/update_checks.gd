extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var world := World.new()
	root.add_child(world)
	for y in World.MAP_H:
		var row := []
		for x in World.MAP_W:
			row.append(World.T_ROCK if x == 0 or y == 0 or x == 59 or y == 59 else World.T_GRASS)
		world.tiles.append(row)
	# A U-shaped lake traps direct chasing and random sideways movement.
	for y in range(8, 20):
		world.tiles[y][8] = World.T_TREE
		world.tiles[y][18] = World.T_ROCK
	for x in range(8, 19):
		world.tiles[19][x] = World.T_WATER
	world.navigation = ForestNavigation.new(world)
	var player := Player.new()
	root.add_child(player)
	player.controlled = false
	player.position = Vector2(13.5, 23.5) * 32
	player.hp = 100
	var enemy := Enemy.new()
	enemy.world = world
	enemy.setup("MINION", 1)
	root.add_child(enemy)
	enemy.position = Vector2(13.5, 15.5) * 32
	var stayed_free := true
	var max_step := 0.0
	for i in 1800:
		var before := enemy.position
		enemy.ai_update(player, 1.0 / 60)
		max_step = maxf(max_step, before.distance_to(enemy.position))
		stayed_free = stayed_free and MoveHelper.can_enter(world, enemy.position)
	check(enemy.position.distance_to(player.position) < 45, "NPC must leave a U-shaped obstacle and reach player")
	check(stayed_free and max_step < 5, "Navigation must never cross walls or teleport")
	var before := Vector2(13.5, 18.5) * 32
	var after := MoveHelper.slide_step(world, before, Vector2(0, 100))
	check(after.y < 19 * 32 and MoveHelper.can_enter(world, after), "Long dash must not tunnel through water")
	player.world = world
	player.position = Vector2(4.5, 4.5) * 32
	player.controlled = true
	player.use_ext = true
	player.ext_dir = Vector2.UP
	player._physics_process(0.016)
	player.ext_dir = Vector2.ZERO
	player.vel = Vector2.ZERO
	player.dash_enabled = true
	player.try_dash()
	check(player._dash_direction == Vector2.UP, "Idle dodge must retain last vertical movement direction")
	var controls := TouchControls.new()
	controls.editing = true
	root.add_child(controls)
	controls.layout_override = {"primary": {"x": 0.7, "y": 0.6, "scale": 1.4, "alpha": 0.4}}
	var b: Dictionary = controls._buttons()[0]
	check(Vector2(b.c).distance_to(controls.size * Vector2(0.7, 0.6)) < 1, "HUD must use normalized saved positions")
	check(is_equal_approx(b.r, 44 * 1.4) and is_equal_approx(b.alpha, 0.4), "HUD must apply individual size and opacity")
	controls.held["skill1"] = true
	controls.joy_index = 0
	controls.hide()
	check(controls.held.is_empty() and controls.pad_dir() == Vector2.ZERO, "Hiding touch controls must release held input")
	var editor := HudEditor.new()
	editor.data = GameSettings.default_data()
	root.add_child(editor)
	await process_frame
	var original: Vector2 = editor.preview._buttons()[0].c
	var touch := InputEventScreenTouch.new()
	touch.index = 2
	touch.pressed = true
	touch.position = original
	root.push_input(touch, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = original - Vector2(120, 100)
	root.push_input(drag, true)
	check(Vector2(editor.preview._buttons()[0].c).distance_to(drag.position) < 1, "Dragging primary action must move its real hit target")
	check(editor.data.touch_layout.is_empty(), "Editor changes must remain a draft until Save")
	editor._property("scale", 1.5)
	editor._property("alpha", 0.35)
	check(is_equal_approx(editor.preview._buttons()[0].r, 66), "Editor size slider must change the hit radius")
	var config := ConfigFile.new()
	config.set_value("touch", "layout", editor.preview.layout_override)
	var decoded := ConfigFile.new()
	decoded.parse(config.encode_to_text())
	check(decoded.get_value("touch", "layout") == editor.preview.layout_override, "HUD layout must survive settings serialization")
	editor.free()
	# Generated forests: routes from the map's extremes to a fixed refuge.
	for map_seed in [99, 101, 4242]:
		world.generate(map_seed)
		var cells := world.walkable_tiles()
		player.position = world.navigation.center(cells[cells.size() / 2])
		for at in [cells[0], cells[cells.size() / 4], cells[cells.size() - 1]]:
			enemy.position = world.navigation.center(at)
			var safe := true
			for i in 6000:
				enemy.ai_update(player, 1.0 / 60)
				safe = safe and MoveHelper.can_enter(world, enemy.position)
				if enemy.position.distance_to(player.position) < 42:
					break
			check(safe and enemy.position.distance_to(player.position) < 42, "Generated forest route failed: seed %d, cell %s" % [map_seed, at])
	controls.free()
	enemy.free()
	player.free()
	world.free()
	print("UPDATE_CHECKS %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
