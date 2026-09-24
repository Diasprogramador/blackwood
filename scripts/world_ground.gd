class_name WorldGround
extends Node2D

## Desenha o chão estático: grama variada, trilhas de terra com bordas
## orgânicas e detalhes (brilho, folhas, pedrinhas).

var world: World
var stage_palette: Dictionary = {}

func _base_grass() -> Color:
	return stage_palette.get("grass", Color(0.16, 0.42, 0.16))

func _base_dirt() -> Color:
	return stage_palette.get("dirt", Color(0.48, 0.36, 0.22))

func _base_water() -> Color:
	return stage_palette.get("water", Color(0.12, 0.35, 0.62))

func _ready() -> void:
	z_index = -10

func _draw() -> void:
	if world == null or world.tiles.is_empty():
		return
	var TILE := World.TILE

	for y in World.MAP_H:
		for x in World.MAP_W:
			var t: int = world.tiles[y][x]
			var px := x * TILE
			var py := y * TILE
			var h := hash(Vector2i(x, y))

			# base de grama sempre (inclusive sob trilha/água, para blend)
			var g := 0.9 + (h % 13) / 100.0
			var bg := _base_grass()
			var grass := Color(bg.r * g, bg.g * g, bg.b * g)
			draw_rect(Rect2(px, py, TILE, TILE), grass)

			match t:
				World.T_GRASS:
					_grass_detail(px, py, h)
				World.T_PATH:
					_path_tile(px, py, x, y, h)
				World.T_WATER:
					_water_base(px, py, h)
				World.T_TREE, World.T_ROCK:
					# chão sob props: um pouco mais escuro (sombra da copa/mata)
					draw_rect(Rect2(px, py, TILE, TILE), Color(0.08, 0.2, 0.1, 0.25))
					_grass_detail(px, py, h)

	# vinheta suave nas bordas do mapa
	_draw_map_border_shade()

func _grass_detail(px: int, py: int, h: int) -> void:
	var TILE := World.TILE
	# frouxinho
	if h % 7 == 0:
		var gx := px + (h * 3) % (TILE - 6) + 3
		var gy := py + (h * 5) % (TILE - 6) + 3
		draw_line(Vector2(gx, gy + 3), Vector2(gx, gy), Color(0.3, 0.62, 0.26), 1.2)
		draw_line(Vector2(gx + 2, gy + 3), Vector2(gx + 3, gy + 1), Color(0.24, 0.55, 0.22), 1)
	if h % 11 == 0:
		# florezinha
		var fx := px + (h * 7) % (TILE - 8) + 4
		var fy := py + (h * 11) % (TILE - 8) + 4
		draw_circle(Vector2(fx, fy), 1.5, Color(0.9, 0.85, 0.4, 0.8))
	if h % 5 == 0:
		# mancha mais clara
		var mx := px + (h * 13) % TILE
		var my := py + (h * 17) % TILE
		ArtUtil.fill_ellipse(self, mx, my, 6, 4, Color(0.22, 0.5, 0.2, 0.35))

func _path_tile(px: int, py: int, x: int, y: int, h: int) -> void:
	var TILE := World.TILE
	# terra com variação (cor muda por fase)
	var dirt := 0.92 + (h % 9) / 90.0
	var bd := _base_dirt()
	var soil := Color(bd.r * dirt, bd.g * dirt, bd.b * dirt)
	draw_rect(Rect2(px, py, TILE, TILE), soil)

	# bordas orgânicas: se vizinho NÃO é trilha, mistura com grama
	var bg := _base_grass()
	var edge_col := Color(bg.r * 1.05, bg.g * 1.02, bg.b * 1.05, 0.9)
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d: Vector2i in dirs:
		var nx := x + d.x
		var ny := y + d.y
		if world.tile_at(nx, ny) == World.T_PATH:
			continue
		match d:
			Vector2i(1, 0):
				# grama entra pela direita
				for i in 8:
					var yy := py + i * 4
					var wob := 4.0 + sin(h + i * 1.7) * 3.0
					draw_rect(Rect2(px + TILE - wob, yy, wob, 4), edge_col)
			Vector2i(-1, 0):
				for i in 8:
					var yy := py + i * 4
					var wob := 4.0 + sin(h + i * 1.3) * 3.0
					draw_rect(Rect2(px, yy, wob, 4), edge_col)
			Vector2i(0, 1):
				for i in 8:
					var xx := px + i * 4
					var wob := 4.0 + sin(h + i * 1.9) * 3.0
					draw_rect(Rect2(xx, py + TILE - wob, 4, wob), edge_col)
			Vector2i(0, -1):
				for i in 8:
					var xx := px + i * 4
					var wob := 4.0 + sin(h + i * 1.1) * 3.0
					draw_rect(Rect2(xx, py, 4, wob), edge_col)

	# pedrinhas e pegadas na trilha
	if h % 4 == 0:
		var sx := px + (h * 3) % (TILE - 6) + 3
		var sy := py + (h * 7) % (TILE - 6) + 3
		draw_circle(Vector2(sx, sy), 1.6, Color(0.55, 0.48, 0.38))
		draw_circle(Vector2(sx + 0.5, sy - 0.5), 0.8, Color(0.68, 0.6, 0.5))
	if h % 9 == 0:
		# brilho areado
		ArtUtil.fill_ellipse(self, px + TILE * 0.5, py + TILE * 0.5, 7, 4,
			Color(0.6, 0.48, 0.32, 0.35))

func _water_base(px: int, py: int, h: int) -> void:
	var TILE := World.TILE
	var w := 0.94 + (h % 7) / 80.0
	var bw := _base_water()
	draw_rect(Rect2(px, py, TILE, TILE), Color(bw.r * w, bw.g * w, bw.b * w))
	# profundidade central
	ArtUtil.fill_ellipse(self, px + TILE / 2.0, py + TILE / 2.0, 11, 11,
		Color(0.08, 0.25, 0.5, 0.5))
	# borda de espuma leve p/ vizinhos não-água
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		pass  # espuma animada no WaterFx

func _draw_map_border_shade() -> void:
	var wpx := World.MAP_W * World.TILE
	var wpy := World.MAP_H * World.TILE
	# sombra interna grossa nas bordas
	for i in 6:
		var a := 0.22 * (1.0 - i / 6.0)
		var c := Color(0, 0, 0, a)
		draw_rect(Rect2(i, i, wpx - i * 2, 4), c)
		draw_rect(Rect2(i, wpy - i * 2 - 4, wpx - i * 2, 4), c)
		draw_rect(Rect2(i, i, 4, wpy - i * 2), c)
		draw_rect(Rect2(wpx - i * 2 - 4, i, 4, wpy - i * 2), c)
