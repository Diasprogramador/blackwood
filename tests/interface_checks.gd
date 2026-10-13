extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(path: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func click(control: Control) -> void:
	var point := control.get_global_transform_with_canvas()* (control.size/2)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = down
		root.push_input(event,true)
		await process_frame

func run() -> void:
	var output := OS.get_cmdline_user_args()[0]
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280,720))
	game._enter_stage()
	game.progress = StageData.default_progress()
	game.stage_ui.build(game.progress,0,0)
	await shot(output.path_join("regions-locked.png"))
	assert(game.stage_ui._stage_btns[1].disabled)
	game.stage_ui.handle_key(KEY_RIGHT)
	assert(game.stage_ui.selected_stage == 0)
	game.stage_ui.handle_key(KEY_ENTER)
	await process_frame
	assert(game.stage_ui.step == 1 and game.stage_ui._diff_btns[1].disabled)
	game.stage_ui.handle_key(KEY_ESCAPE)
	assert(game.stage_ui.step == 0 and game.stage_ui.get_child_count() == 1)
	game.progress["unlocked"] = 3
	game.progress["cleared"] = [[true,true,true,true],[true,true,true,true],[true,true,true,true]]
	game.stage_ui.build(game.progress,1,2)
	await shot(output.path_join("regions.png"))
	await click(game.stage_ui._stage_btns[2])
	assert(game.stage_ui.selected_stage == 2,"Region card click must change selection")
	game.stage_ui._to_step_1()
	await shot(output.path_join("difficulty.png"))
	await click(game.stage_ui._diff_btns[3])
	assert(game.stage_ui.selected_diff == 3,"Difficulty click must change selection")
	DisplayServer.window_set_size(Vector2i(960,540))
	await shot(output.path_join("difficulty-mobile.png"))
	for button in game.stage_ui._diff_btns:
		assert(button.get_global_rect().end.x <= game.stage_ui.size.x and button.get_global_rect().end.y <= game.stage_ui.size.y,"Difficulty cards must fit mobile landscape")
	game.start_game(0,0,0,4242)
	game.player.controlled = false
	game.settings["touch"] = 2
	game.settings["show_fps"] = false
	game.wave_banner_t = 0
	game.hud.clear_messages()
	for i in 80: await process_frame
	game.player.skills = [{"cfg":ChampData.ROLES.tank.skills[0],"cd_left":0.0},{"cfg":ChampData.ROLES.tank.skills[1],"cd_left":4.2}]
	game.player.hp = 93
	game.player.mana = 60
	game.hud._hp_trail = 126
	await shot(output.path_join("hud-desktop.png"))
	await click(game.hud._actions.pause)
	assert(paused and game.state == game.State.PAUSE,"HUD pause button must pause actual gameplay")
	game._set_pause(false)
	await process_frame
	await click(game.hud._actions.shop)
	assert(game.shop.visible,"HUD shop button must open the shop")
	game._close_shop()
	await process_frame
	await click(game.hud._actions.channel)
	assert(game.player.channeling,"HUD mana button must toggle channeling")
	game.player.channeling = false
	game.mp = 2
	game.hud_action("skill1")
	assert(game._edge("skill1") and not game._edge("skill1"),"Client HUD click must send exactly one network edge")
	game.mp = 0
	game.settings["touch"] = 1
	game._update_touch()
	await shot(output.path_join("hud-mobile.png"))
	assert(not game.hud._actions.attack.visible and game.touch_ui.visible,"Desktop hit targets must not intercept the customized touch HUD")
	game.player.channeling = false
	game.player.gain_exp(game.player.exp_to_next())
	await create_timer(0.25).timeout
	assert(paused and game.state == game.State.UPGRADE)
	assert(not game.touch_ui.visible)
	await shot(output.path_join("level-choices-mobile.png"))
	for button in game.upgrade_menu._buttons:
		assert(button.get_global_rect().end.x <= game.upgrade_menu.size.x)
		assert(button.get_global_rect().end.y <= game.upgrade_menu.size.y)
	var picked: String = game._current_offers[1].id
	await click(game.upgrade_menu._buttons[1])
	assert(not paused and game.player.run_upgrade_counts.get(picked,0) == 1)
	game._open_shop()
	await shot(output.path_join("provisions-mobile.png"))
	assert(game.shop._rows.is_empty())
	var gold: int = game.player.gold
	game.shop.handle_key(KEY_1)
	game.try_buy_upgrade(0)
	assert(game.player.gold == gold and game.player.upgrade_counts[0] == 0)
	game._close_shop()
	DisplayServer.window_set_size(Vector2i(1280,720))
	game.player.gain_exp(game.player.exp_to_next())
	await create_timer(0.25).timeout
	await shot(output.path_join("level-choices-desktop.png"))
	var key := InputEventKey.new()
	key.physical_keycode = KEY_1
	key.pressed = true
	root.push_input(key,true)
	await process_frame
	assert(not paused and game.state == game.State.PLAY)
	game.queue_free()
	await process_frame
	var canvas := Node2D.new()
	root.add_child(canvas)
	for quality in [0,2]:
		GameSettings.quality_cache = quality
		for phase in [0.06,0.35,0.8]:
			for family in 5:
				for slot in 6:
					var effect := AttackEffect.new(AttackEffect.role_fx(AttackEffect.ROLES[family],slot),90+slot*150,65+family*100,-0.5,0.75)
					effect.age = effect.max_time*phase
					canvas.add_child(effect)
					effect.set_process(false)
			await shot(output.path_join("effects-%d-%.2f.png" % [quality,phase]))
			for child in canvas.get_children(): child.queue_free()
			await process_frame
	canvas.queue_free()
	await process_frame
	assert(AttackEffect.live == 0,"Effects must release their live count")
	print("INTERFACE_CHECKS passed: locked/unlocked selection, mouse actions, desktop/mobile bounds, 180 effect samples")
	quit()
