extends SceneTree

class Bestiary extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,720),ForestUI.INK)
		var font := ThemeDB.fallback_font
		draw_string(font,Vector2(24,35),"BLACKWOOD / BESTIÁRIO DOS TRÊS REINOS",HORIZONTAL_ALIGNMENT_LEFT,-1,24,ForestUI.GOLD)
		for stage in 3:
			var y := 92+stage*205
			draw_string(font,Vector2(24,y),StageData.stage_name(stage).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,18,BiomeArt.palette(stage)[4])
			for kind in 6:
				var title := BiomeEnemyArt.title(EnemyData.ORDER[kind],stage)
				draw_string(font,Vector2(30+kind*208,y+170),title,HORIZONTAL_ALIGNMENT_LEFT,-1,12,ForestUI.PAPER)

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	var output := OS.get_cmdline_user_args()[0]
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var hashes := []
	for stage in [0,1,2,0]:
		game.start_game(0,stage,0,4242)
		game.state = game.State.PAUSE
		game.player.controlled = false
		game.settings["touch"] = 2
		game.settings["show_fps"] = false
		game.wave_banner_t = 0
		for i in 90:
			await process_frame
		assert(game.world.ground.cached_texture != null)
		assert(game.world._prop_stage == stage, "Prop atlas must match the new biome")
		assert(game.world._prop_textures.size() == 18)
		for prop in game.world.props.get_children():
			if prop is TreeProp or prop is RockProp:
				assert(prop.stage_idx == stage)
		for enemy in game.enemies:
			enemy.queue_free()
		game.enemies.clear()
		for kind in 6:
			var enemy := Enemy.new()
			enemy.world = game.world
			enemy.stage_idx = stage
			enemy.setup(EnemyData.ORDER[kind],1)
			enemy.position = game.player.position + Vector2((kind%3-1)*120,-110+(kind/3)*210)
			game.entities.add_child(enemy)
			game.enemies.append(enemy)
		game._update_depth()
		for i in 5:
			await process_frame
		await capture(output.path_join("biome-%d.png" % stage))
		hashes.append(hash(game.world._prop_textures[0].get_image().get_data()))
	assert(hashes[0] != hashes[1] and hashes[1] != hashes[2] and hashes[0] == hashes[3], "Biome atlas must change and restore deterministically")
	var textures: Dictionary = game.world.enemy_textures.duplicate()
	assert(textures.size() == 18)
	for kind in EnemyData.ORDER:
		assert(hash(textures["%s:0" % kind][0].get_image().get_data()) != hash(textures["%s:1" % kind][0].get_image().get_data()))
		assert(hash(textures["%s:1" % kind][0].get_image().get_data()) != hash(textures["%s:2" % kind][0].get_image().get_data()))
	game.queue_free()
	await process_frame
	var board := Bestiary.new()
	root.add_child(board)
	board.scale = root.get_visible_rect().size / Vector2(1280,720)
	for stage in 3:
		for kind in 6:
			var sprite := Sprite2D.new()
			sprite.texture = textures["%s:%d" % [EnemyData.ORDER[kind],stage]][0]
			sprite.position = Vector2(112+kind*208,stage*205+213)
			sprite.scale = Vector2.ONE * 1.45
			board.add_child(sprite)
	for i in 4:
		await process_frame
	await capture(output.path_join("bestiary.png"))
	print("BIOME_CHECKS passed: 4 transitions, 3 prop atlases, 18 enemy variants, 72 poses")
	quit()
