class_name World
extends Node2D

## Mapa 60x60 com grama, trilhas serpenteantes, lagos, florestas e pedras.

const TILE := 32
const MAP_W := 60
const MAP_H := 60

const T_GRASS := 0
const T_PATH := 1
const T_WATER := 2
const T_TREE := 3
const T_ROCK := 4

var tiles: Array = []
var _water_tiles: Array[Vector2i] = []
var _rng := RandomNumberGenerator.new()
var _time := 0.0
var stage_idx := 0

var ground: Node2D
var water_fx: Node2D
var props: Node2D
var stage_palette: Dictionary = {}

func _ready() -> void:
	ground = WorldGround.new()
	ground.name = "Ground"
	(ground as WorldGround).world = self
	add_child(ground)

	props = Node2D.new()
	props.name = "Props"
	props.y_sort_enabled = true
	add_child(props)

	water_fx = WaterFx.new()
	water_fx.name = "WaterFx"
	(water_fx as WaterFx).world = self
	add_child(water_fx)

## Aplica o visual da fase (chão + minimapa). Chame após generate().
func apply_stage(stage_idx: int) -> void:
	var st: Dictionary = StageData.STAGES[clampi(stage_idx, 0, StageData.STAGES.size() - 1)]
	stage_palette = st.get("palette", {})
	if ground != null:
		(ground as WorldGround).stage_palette = stage_palette
		ground.queue_redraw()

func generate(seed_value: int = -1) -> void:
	if seed_value < 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value

	tiles = []
	_water_tiles.clear()
	for y in MAP_H:
		var row := []
		row.resize(MAP_W)
		row.fill(T_GRASS)
		tiles.append(row)

	_carve_paths()
	_carve_lakes()
	_scatter_forests()
	_build_border()
	_connect_regions()

	# limpa props anteriores
	for c in props.get_children():
		c.queue_free()

	for y in MAP_H:
		for x in MAP_W:
			var t: int = tiles[y][x]
			var wx := x * TILE + TILE / 2.0
			var wy := y * TILE + TILE / 2.0 + 8.0
			if t == T_TREE:
				var tree := TreeProp.new()
				tree.variant = _rng.randi_range(0, 11)
				tree.position = Vector2(wx, wy)
				props.add_child(tree)
			elif t == T_ROCK:
				var rock := RockProp.new()
				rock.variant = _rng.randi_range(0, 5)
				rock.position = Vector2(wx, wy)
				props.add_child(rock)
			elif t == T_WATER:
				_water_tiles.append(Vector2i(x, y))

	# decoração da fase (só visual, não bloqueia passagem)
	for y in range(2, MAP_H - 2):
		for x in range(2, MAP_W - 2):
			if tiles[y][x] != T_GRASS:
				continue
			var roll := _rng.randf()
			var dx := x * TILE + TILE / 2.0
			var dy := y * TILE + TILE / 2.0 + 6.0
			if stage_idx == 1 and roll < 0.035:
				var emb := EmberProp.new()
				emb.variant = _rng.randi_range(0, 5)
				emb.position = Vector2(dx, dy)
				props.add_child(emb)
			elif stage_idx == 2 and roll < 0.035:
				var cry := CrystalProp.new()
				cry.variant = _rng.randi_range(0, 5)
				cry.position = Vector2(dx, dy)
				props.add_child(cry)

	ground.queue_redraw()
	water_fx.queue_redraw()

# ---------------------------------------------------------------------
#  GERAÇÃO
# ---------------------------------------------------------------------
func _carve_paths() -> void:
	var cx := int(MAP_W / 2.0)
	var cy := int(MAP_H / 2.0)

	# praça central
	for y in range(cy - 3, cy + 4):
		for x in range(cx - 3, cx + 4):
			tiles[y][x] = T_PATH

	# anel ao redor da praça
	var ring_r := 9
	for i in 360:
		var a := deg_to_rad(i)
		var x := int(round(cx + cos(a) * ring_r))
		var y := int(round(cy + sin(a) * ring_r))
		if _in_bounds(x, y) and tiles[y][x] != T_WATER:
			tiles[y][x] = T_PATH
			if _in_bounds(x + 1, y) and tiles[y][x + 1] == T_GRASS:
				tiles[y][x + 1] = T_PATH

	# trilhas serpenteantes saindo do centro (mais rotas, mais largas)
	var trail_count := 10
	for i in trail_count:
		var angle := TAU * i / trail_count + _rng.randf_range(-0.3, 0.3)
		var x := cx + int(cos(angle) * 4)
		var y := cy + int(sin(angle) * 4)
		var length := _rng.randi_range(18, 34)
		for step in length:
			# vira suavemente
			angle += _rng.randf_range(-0.5, 0.5)
			# reage um pouco à borda
			if x < 6: angle = angle * 0.3 + 0 * 0.7
			if x > MAP_W - 7: angle = angle * 0.3 + PI * 0.7
			if y < 6: angle = angle * 0.3 + PI * 0.5 * 0.7 + 0.3
			if y > MAP_H - 7: angle = angle * 0.3 - PI * 0.5 * 0.7
			x += int(round(cos(angle)))
			y += int(round(sin(angle)))
			if not _in_bounds(x, y) or x <= 1 or y <= 1 or x >= MAP_W - 2 or y >= MAP_H - 2:
				break
			if tiles[y][x] != T_WATER:
				tiles[y][x] = T_PATH
				# largura 2 quase sempre (sem corredor apertado)
				if _rng.randf() < 0.7:
					var nx := x + (1 if _rng.randf() < 0.5 else -1)
					if _in_bounds(nx, y) and tiles[y][nx] == T_GRASS:
						tiles[y][nx] = T_PATH
				if _rng.randf() < 0.3:
					var ny := y + (1 if _rng.randf() < 0.5 else -1)
					if _in_bounds(x, ny) and tiles[ny][x] == T_GRASS:
						tiles[ny][x] = T_PATH

func _carve_lakes() -> void:
	for i in 4:
		var lx := _rng.randi_range(8, MAP_W - 9)
		var ly := _rng.randi_range(8, MAP_H - 9)
		var size := _rng.randi_range(8, 20)
		var x := lx
		var y := ly
		var angle := _rng.randf() * TAU
		for s in size:
			angle += _rng.randf_range(-0.8, 0.8)
			x += int(round(cos(angle) * 1.2))
			y += int(round(sin(angle) * 1.2))
			if not _in_bounds(x, y):
				break
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx := x + dx
					var ny := y + dy
					if _in_bounds(nx, ny) and tiles[ny][nx] == T_GRASS:
						if absi(nx - int(MAP_W / 2.0)) > 7 or absi(ny - int(MAP_H / 2.0)) > 7:
							tiles[ny][nx] = T_WATER

func _scatter_forests() -> void:
	# aglomerados de árvores (menos e menores fora da floresta)
	var clusters := 14
	var max_radius := 6
	if stage_idx == 1:
		clusters = 6
		max_radius = 4
	elif stage_idx == 2:
		clusters = 8
		max_radius = 4
	for i in clusters:
		var fx := _rng.randi_range(4, MAP_W - 5)
		var fy := _rng.randi_range(4, MAP_H - 5)
		var radius := _rng.randi_range(2, max_radius)
		for y in range(fy - radius, fy + radius + 1):
			for x in range(fx - radius, fx + radius + 1):
				if not _in_bounds(x, y):
					continue
				if tiles[y][x] != T_GRASS:
					continue
				var d := Vector2(x - fx, y - fy).length()
				if d > radius:
					continue
				var chance := lerpf(0.85, 0.1, d / maxf(1.0, radius))
				if _rng.randf() < chance:
					tiles[y][x] = T_TREE

	# pedras esparsas
	for y in range(2, MAP_H - 2):
		for x in range(2, MAP_W - 2):
			if tiles[y][x] == T_GRASS and _rng.randf() < 0.012:
				tiles[y][x] = T_ROCK

	# some com ilhas de árvore/pedra sem grama vizinha (polimento rápido)
	for y in range(1, MAP_H - 1):
		for x in range(1, MAP_W - 1):
			if tiles[y][x] == T_GRASS and _rng.randf() < 0.005:
				tiles[y][x] = T_ROCK

func _build_border() -> void:
	for i in MAP_W:
		for pair in [[i, 0], [i, MAP_H - 1]]:
			var x: int = pair[0]
			var y: int = pair[1]
			tiles[y][x] = T_TREE if _rng.randf() < 0.7 else T_ROCK
	for i in MAP_H:
		for pair in [[0, i], [MAP_W - 1, i]]:
			var x: int = pair[0]
			var y: int = pair[1]
			if tiles[y][x] == T_GRASS:
				tiles[y][x] = T_ROCK if _rng.randf() < 0.5 else T_TREE
	# refraça a borda
	for y in MAP_H:
		for x in MAP_W:
			if x == 0 or y == 0 or x == MAP_W - 1 or y == MAP_H - 1:
				if tiles[y][x] == T_GRASS or tiles[y][x] == T_PATH:
					tiles[y][x] = T_ROCK

## Garante rota de fuga: toda região andável isolada ganha um corredor
## 2x2 até a região principal (adeus becos em "C" sem saída).
func _connect_regions() -> void:
	var guard := 0
	while guard < 12:
		guard += 1
		var main_region := _flood(Vector2i(MAP_W / 2, MAP_H / 2))
		var target := Vector2i(-1, -1)
		for y in range(2, MAP_H - 2):
			for x in range(2, MAP_W - 2):
				if not is_solid_tile(x, y) and not main_region.has(Vector2i(x, y)):
					target = Vector2i(x, y)
					break
			if target.x >= 0:
				break
		if target.x < 0:
			return
		var best := Vector2i(MAP_W / 2, MAP_H / 2)
		var best_d := 1e18
		for c in main_region.keys():
			var dd := Vector2(c - target).length_squared()
			if dd < best_d:
				best_d = dd
				best = c
		_carve_corridor(target, best)

func _flood(start: Vector2i) -> Dictionary:
	if is_solid_tile(start.x, start.y):
		return {}
	var seen := {}
	var stack := [start]
	seen[start] = true
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if n.x < 2 or n.y < 2 or n.x >= MAP_W - 2 or n.y >= MAP_H - 2:
				continue
			if seen.has(n) or is_solid_tile(n.x, n.y):
				continue
			seen[n] = true
			stack.append(n)
	return seen

func _carve_corridor(a: Vector2i, b: Vector2i) -> void:
	var x := a.x
	var y := a.y
	while x != b.x:
		_set_path_area(x, y)
		x += 1 if b.x > x else -1
	while y != b.y:
		_set_path_area(x, y)
		y += 1 if b.y > y else -1
	_set_path_area(x, y)

func _set_path_area(x: int, y: int) -> void:
	for dy in range(0, 2):
		for dx in range(0, 2):
			var nx := x + dx
			var ny := y + dy
			if nx >= 2 and ny >= 2 and nx < MAP_W - 2 and ny < MAP_H - 2:
				tiles[ny][nx] = T_PATH

# ---------------------------------------------------------------------
#  COLISÃO / HELPERS
# ---------------------------------------------------------------------
func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < MAP_W and y < MAP_H

func tile_at(x: int, y: int) -> int:
	if not _in_bounds(x, y):
		return T_ROCK
	return tiles[y][x]

func is_solid_tile(x: int, y: int) -> bool:
	var t := tile_at(x, y)
	return t == T_WATER or t == T_TREE or t == T_ROCK

func is_solid_at(wx: float, wy: float) -> bool:
	return is_solid_tile(int(floor(wx / TILE)), int(floor(wy / TILE)))

func walkable_tiles() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(2, MAP_H - 2):
		for x in range(2, MAP_W - 2):
			if not is_solid_tile(x, y):
				out.append(Vector2i(x, y))
	return out

func center_px() -> Vector2:
	return Vector2(MAP_W * TILE / 2.0, MAP_H * TILE / 2.0)

func world_size() -> Vector2:
	return Vector2(MAP_W * TILE, MAP_H * TILE)

## Textura do minimapa (construída uma vez por geração).
func build_minimap_image() -> ImageTexture:
	var grass: Color = stage_palette.get("grass", Color(0.16, 0.42, 0.16))
	var dirt: Color = stage_palette.get("dirt", Color(0.55, 0.42, 0.25))
	var water: Color = stage_palette.get("water", Color(0.2, 0.4, 0.7))
	var img := Image.create(MAP_W, MAP_H, false, Image.FORMAT_RGBA8)
	for y in MAP_H:
		for x in MAP_W:
			var c: Color
			match tiles[y][x]:
				T_PATH: c = dirt
				T_WATER: c = water
				T_TREE: c = grass.darkened(0.55)
				T_ROCK: c = Color(0.35, 0.36, 0.4)
				_: c = grass
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	_time += delta
