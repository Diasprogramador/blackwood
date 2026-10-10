extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(path: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	var output := OS.get_cmdline_user_args()[0]
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await shot(output.path_join("menu.png"))
	game._enter_settings()
	var editor := HudEditor.new()
	editor.data = game.settings
	game.settings_ui.add_child(editor)
	await shot(output.path_join("hud-editor.png"))
	editor.queue_free()
	game.start_game(2, 0, 0, 4242)
	game.player.controlled = false
	game.player.max_hp = 100000
	game.player.hp = 100000
	game.settings["touch"] = 1
	for i in 90:
		await process_frame
	await shot(output.path_join("game.png"))
	game.state = game.State.PAUSE
	for i in 5:
		var pos: Vector2 = game.player.position + Vector2((i - 2) * 80, -50)
		game._spawn_strike(pos, pos + Vector2(60, 40), AttackEffect.ROLES[i])
	await shot(output.path_join("attacks.png"))
	game._enter_menu()
	assert(not game.touch_ui.visible, "Touch HUD must disappear on returning to menu")
	root.size = Vector2i(960, 540)
	await shot(output.path_join("menu-mobile.png"))
	game._enter_settings()
	var mobile_editor := HudEditor.new()
	mobile_editor.data = game.settings
	game.settings_ui.add_child(mobile_editor)
	await shot(output.path_join("hud-mobile.png"))
	game.queue_free()
	await process_frame
	var canvas := Node2D.new()
	root.add_child(canvas)
	for family in 5:
		for slot in 6:
			var effect := AttackEffect.new(AttackEffect.role_fx(AttackEffect.ROLES[family], slot), 110 + slot * 145, 65 + family * 100, -0.4, 0.7)
			effect.age = effect.max_time * 0.3
			canvas.add_child(effect)
			effect.set_process(false)
	await shot(output.path_join("all-attacks.png"))
	quit()

