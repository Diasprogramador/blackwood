extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var output: String = args[0] if not args.is_empty() else OS.get_user_data_dir()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	seed(4242)
	game.start_game(2, 0, 0, 4242)
	game.settings["show_fps"] = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	game.player.controlled = false
	game.state = game.State.PAUSE
	for i in 30:
		await process_frame
	assert(game.world.ground.cached_texture != null)
	assert(game.world._prop_textures.size() == 18)
	game.state = game.State.PLAY
	game.player.gain_exp(36)
	for i in 18:
		await process_frame
	assert(not paused and game.state == game.State.PLAY)
	await capture(output.path_join("blackwood-combate.png"))
	await process_frame
	game.state = game.State.PAUSE
	game.player.max_hp = 10000
	game.player.hp = 10000
	game.wave_quota = 1000
	# Concentrate a larger encounter in a walkable area, without saving progress.
	for enemy in game.enemies:
		enemy.queue_free()
	game.enemies.clear()
	for i in 48:
		var enemy := Enemy.new()
		enemy.world = game.world
		enemy.setup("MINION" if i % 3 else "CASTER", 1)
		enemy.died.connect(game._on_enemy_killed)
		enemy.shoot.connect(game._on_enemy_shoot)
		var point: Vector2 = game.player.position + Vector2.from_angle(i * TAU / 48.0) * (90 + i * 4)
		var free := MoveHelper.find_free(game.world, point)
		enemy.position = free if free != Vector2.INF else game.player.position
		game.entities.add_child(enemy)
		game.enemies.append(enemy)
	game.state = game.State.PLAY
	var samples: Array[float] = []
	var peak_enemies: int = game.enemies.size()
	for i in 900:
		var before := Time.get_ticks_usec()
		await process_frame
		if i > 60:
			samples.append((Time.get_ticks_usec() - before) / 1000.0)
		peak_enemies = maxi(peak_enemies, game.enemies.size())
		if i == 250:
			await capture(output.path_join("blackwood-teste-estresse.png"))
	samples.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	print("COMBAT_PROBE " + JSON.stringify({"mean_ms": total / samples.size(), "p95_ms": samples[int(samples.size() * 0.95)], "peak_enemies": peak_enemies, "kills": game.kill_count, "level": game.player.level, "game_seconds": game.game_time}))
	game.state = game.State.PAUSE
	game.start_game(0, 1, 0, 99)
	game.state = game.State.PAUSE
	for i in 20:
		await process_frame
	assert(game.world.ground.cached_texture != null)
	assert(game.world._prop_textures.size() == 18)
	game.start_game(4, 2, 0, 101)
	game.state = game.State.PAUSE
	for i in 20:
		await process_frame
	assert(game.world.ground.cached_texture != null)
	assert(game.world._prop_textures.size() == 18)
	game.state = game.State.PLAY
	game.player.take_damage(100000)
	for i in 5:
		await process_frame
	await capture(output.path_join("blackwood-derrota.png"))
	print("RENDER_CHECKS passed: cached maps, uninterrupted level up, combat, stage regeneration, defeat")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	quit()
