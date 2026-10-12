class_name WorldGround
extends Node2D

## Desenha o chão estático: grama variada, trilhas de terra com bordas
## orgânicas e detalhes (brilho, folhas, pedrinhas).

var world: World
var stage_palette: Dictionary = {}
var cached_texture: Texture2D

func _base_grass() -> Color:
	return stage_palette.get("grass", Color(0.16, 0.42, 0.16))

func _base_dirt() -> Color:
	return stage_palette.get("dirt", Color(0.48, 0.36, 0.22))

func _base_water() -> Color:
	return stage_palette.get("water", Color(0.12, 0.35, 0.62))

func _ready() -> void:
	z_index = -10

func _draw() -> void:
	if cached_texture != null:
		draw_texture(cached_texture, Vector2.ZERO)
		return
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
			var g := 0.93 + sin(x * 0.31 + sin(y * 0.17)) * 0.035 + cos(y * 0.28) * 0.025 + posmod(h, 5) * 0.004
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

	_draw_refuge()
	# vinheta suave nas bordas do mapa
	_draw_map_border_shade()

func _grass_detail(px: int, py: int, h: int) -> void:
	var p := BiomeArt.palette(world.stage_idx)
	var x := px + posmod(h * 3, 22) + 5
	var y := py + posmod(h * 7, 22) + 5
	if posmod(h, 3) == 0:
		ArtUtil.fill_ellipse(self, x, y, 10, 5, Color(p[0], 0.18))
	match world.stage_idx:
		0:
			if posmod(h, 4) == 0:
				draw_line(Vector2(x,y+4), Vector2(x,y-5), Color(p[3],0.6), 1)
				for side in [-1,1]:
					for leaf in 3:
						draw_line(Vector2(x,y-leaf*2),Vector2(x+side*(5-leaf),y-3-leaf*2),Color(p[2],0.9),2)
			if posmod(h, 13) == 0:
				for i in 3:
					draw_rect(Rect2(x+i*3,y+i%2*3,2,2),p[4])
		1:
			if posmod(h, 5) == 0:
				draw_polyline(PackedVector2Array([Vector2(x-9,y-9),Vector2(x,y),Vector2(x-3,y+7),Vector2(x+3,y+12)]),p[0],2)
				draw_line(Vector2(x,y),Vector2(x+9,y-3),p[0],2)
				if posmod(h, 10) == 0:
					draw_line(Vector2(x,y+1),Vector2(x-3,y+6),Color(p[4],0.7),1)
			if posmod(h, 7) == 0:
				draw_rect(Rect2(x,y,4,2),p[3])
		2:
			if posmod(h, 5) == 0:
				draw_polyline(PackedVector2Array([Vector2(x-8,y+6),Vector2(x-1,y+2),Vector2(x+6,y+4),Vector2(x+11,y-1)]),Color(p[2],0.7),2)
			if posmod(h, 11) == 0:
				for i in 3:
					draw_line(Vector2(x+i*3,y+4),Vector2(x+i*3-2,y-4-i%2*4),p[2],1)
					draw_rect(Rect2(x+i*3-3,y-6-i%2*4,3,3),Color(p[4],0.6))

func _path_tile(px: int, py: int, x: int, y: int, h: int) -> void:
	var TILE := World.TILE
	# terra com variação (cor muda por fase)
	var dirt := 0.92 + (h % 9) / 90.0
	var bd := _base_dirt()
	var soil := Color(bd.r * dirt, bd.g * dirt, bd.b * dirt)
	draw_rect(Rect2(px, py, TILE, TILE), soil)
	# Regional path materials: scattered flagstones, forge slabs, old causeway.
	if world.stage_idx == 1 and posmod(h, 3) != 0:
		var slab := Rect2(px+4,py+5,24,21)
		draw_rect(slab,soil.darkened(0.15))
		draw_line(slab.position,slab.position+Vector2(24,0),soil.lightened(0.1),1)
		draw_line(slab.position+Vector2(9,0),slab.end-Vector2(6,0),soil.darkened(0.35),1)
	elif world.stage_idx == 2 and posmod(h, 4) == 0:
		for i in 3:
			draw_rect(Rect2(px+5,py+5+i*7,23,5),soil.lightened(0.08))
			draw_rect(Rect2(px+8,py+6+i*7,2,2),soil.darkened(0.3))


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
		Color(bw.darkened(0.3), 0.2))
	# borda de espuma leve p/ vizinhos não-água
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		pass  # espuma animada no WaterFx

func _draw_map_border_shade() -> void:
	var size := Vector2(World.MAP_W * World.TILE, World.MAP_H * World.TILE)
	# Vinheta real (a antiga era só um filete de 6px): emoldura o mundo e
	# dissolve a transição dura para o void sem degraus visíveis.
	ArtUtil.frame_vignette(self, size, 96.0, Color(0, 0, 0), 0.34, 24)

## The refuge is a ground inlay, not a new invisible collision obstacle.
func _draw_refuge() -> void:
	var center := world.center_px() + Vector2(16,16)
	var p := BiomeArt.palette(world.stage_idx)
	ArtUtil.fill_ellipse(self,center.x,center.y,89,66,Color(p[0],0.3))
	for ring in [67.0,79.0]:
		for i in 12:
			var angle := i * TAU / 12
			draw_arc(center,ring,angle+0.035,angle+0.46,5,Color(p[3],0.38),3)
	for i in 8:
		var angle := i * TAU / 8
		var pos := center + Vector2.from_angle(angle) * 73
		draw_line(pos-Vector2(3,4),pos+Vector2(3,4),Color(p[4],0.6),2)
	match world.stage_idx:
		0:
			for i in 5:
				var dir := Vector2.from_angle(i * TAU / 5 - PI/2)
				draw_polyline(PackedVector2Array([center,center+dir*24,center+dir*49+dir.orthogonal()*9]),Color(p[3],0.5),5)
				draw_line(center+dir*24,center+dir*40-dir.orthogonal()*12,Color(p[3],0.5),3)
		1:
			for i in 4:
				var pos := center + Vector2.from_angle(i*PI/2+PI/4)*39
				draw_rect(Rect2(pos-Vector2(15,15),Vector2(30,30)),Color(p[0],0.45))
				draw_line(pos-Vector2(12,12),pos+Vector2(12,-12),Color(p[4],0.5),2)
			draw_arc(center,25,0,TAU,8,Color(p[4],0.4),4)
		2:
			var diamond := PackedVector2Array([center+Vector2(0,-45),center+Vector2(38,0),center+Vector2(0,45),center+Vector2(-38,0),center+Vector2(0,-45)])
			draw_polyline(diamond,Color(p[4],0.35),3)
			draw_arc(center,22,0,TAU,16,Color(p[3],0.5),3)
