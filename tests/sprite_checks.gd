extends SceneTree

class Board extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1366, 850), ForestUI.INK)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(32, 42), "BLACKWOOD / PERSONAGENS DO BOSQUE", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, ForestUI.GOLD)
		for c in 4:
			draw_string(font, Vector2(230 + c * 280, 85), ["REPOUSO", "PASSO A", "PASSO B", "ATAQUE"][c], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ForestUI.PAPER)
		for r in 5:
			draw_string(font, Vector2(32, 160 + r * 128), ["ARLEN", "NYRA", "MIRA", "KAEL", "EIRA"][r], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ForestUI.MINT)
			for c in 4:
				draw_line(Vector2(210 + c * 280, 210 + r * 128), Vector2(365 + c * 280, 210 + r * 128), ForestUI.EDGE, 1)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1366, 850)
	var board := Board.new()
	root.add_child(board)
	board.scale = root.get_visible_rect().size / Vector2(1366, 850)
	for row in 5:
		var role: String = CanvaSprites.ROLES[row]
		for col in 4:
			var sprite := Sprite2D.new()
			sprite.texture = CanvaSprites.frame(role, col)
			sprite.material = CanvaSprites.material()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.offset = Vector2(0, -70)
			sprite.position = Vector2(285 + col * 280, 210 + row * 128)
			board.add_child(sprite)
			assert(sprite.texture.get_size() == Vector2(192, 160))
			assert(sprite.texture == CanvaSprites.frame(role, col))
		var p := Player.new()
		root.add_child(p)
		p.setup(role, role)
		p.set_process(false)
		p.set_physics_process(false)
		p.moving = true
		p._update_body(0.0)
		p._update_body(0.11)
		assert(p.body.texture == CanvaSprites.frame(role, 1))
		p.attack_t = 0.22
		p._update_body(0.0)
		p._update_body(0.08)
		assert(p.body.texture == CanvaSprites.frame(role, 3))
		p.queue_free()
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var output := OS.get_cmdline_user_args()[0]
	root.get_texture().get_image().save_png(output.path_join("blackwood-personagens.png"))
	print("SPRITE_CHECKS passed: 20 atlas frames, shared cache, walking and attack for all five roles")
	board.queue_free()
	await process_frame
	quit()
