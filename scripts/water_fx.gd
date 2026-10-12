class_name WaterFx
extends Node2D

## Brilho animado da água — redesenha apenas os tiles de água.

var world: World
var _t := 0.0
var _acc := 0.0

func _ready() -> void:
	z_index = -9

## O antigo "toggle" redesenhava ~30 frames em rajada. Agora é um throttle de
## verdade, com ritmo por qualidade: a ondulação é lenta, não precisa de 60Hz.
func _process(delta: float) -> void:
	_t += delta
	_acc += delta
	var hz: float = [30.0, 20.0, 12.0][clampi(GameSettings.quality_cache, 0, 2)]
	if _acc < 1.0 / hz:
		return
	_acc = 0.0
	queue_redraw()

func _draw() -> void:
	if world == null:
		return
	var p := BiomeArt.palette(world.stage_idx)
	var surface: Color = p[4] if world.stage_idx == 1 else p[3]
	var TILE := World.TILE
	var visible_rect := (get_canvas_transform().affine_inverse() * get_viewport_rect()).grow(TILE)
	for tile in world._water_tiles:
		var px := tile.x * TILE
		var py := tile.y * TILE
		if not visible_rect.intersects(Rect2(px, py, TILE, TILE)):
			continue
		var phase := _t * 2.0 + tile.x * 0.7 + tile.y * 0.45
		# ondulação
		var ox := sin(phase) * 5.0
		draw_rect(Rect2(px + 6 + ox, py + 10, 9, 2), Color(surface,0.4))
		var ox2 := sin(phase + 1.6) * 4.0
		draw_rect(Rect2(px + 16 - ox2, py + 20, 7, 2), Color(surface,0.25))
		if world.stage_idx == 1:
			var rise := fmod(_t * 8 + tile.x * 7 + tile.y * 3, 22.0)
			draw_rect(Rect2(px+15,py+20-rise,2,3),Color(p[4],0.55*(1-rise/22)))
		elif world.stage_idx == 2 and (tile.x + tile.y) % 3 == 0:
			draw_arc(Vector2(px+15,py+17),4+sin(phase)*2,0,TAU,8,Color(p[4],0.2),1)
		# brilho
		var spark := sin(phase * 1.7)
		if spark > 0.7:
			draw_circle(Vector2(px + 12 + ox, py + 14), 1.5, Color(1, 1, 1, 0.5))
		# espuma nas bordas com terra
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ntx := tile.x + d.x
			var nty := tile.y + d.y
			if world.tile_at(ntx, nty) == World.T_WATER:
				continue
			var fx := px + TILE / 2.0 + d.x * TILE / 2.0
			var fy := py + TILE / 2.0 + d.y * TILE / 2.0
			var wob := 3.0 + sin(phase * 2.0 + tile.x) * 1.5
			if d.x == 1:
				_foam(px + TILE - 2, py, 2, TILE, -1.0, 0.0)
				ArtUtil.fill_ellipse(self, px + TILE - 2, fy, 2, wob, Color(surface,0.3))
			elif d.x == -1:
				_foam(px, py, 2, TILE, 1.0, 0.0)
				ArtUtil.fill_ellipse(self, px + 2, fy, 2, wob, Color(surface,0.3))
			elif d.y == 1:
				_foam(px, py + TILE - 2, TILE, 2, 0.0, -1.0)
				ArtUtil.fill_ellipse(self, fx, py + TILE - 2, wob, 2, Color(surface,0.3))
			else:
				_foam(px, py, TILE, 2, 0.0, 1.0)
				ArtUtil.fill_ellipse(self, fx, py + 2, wob, 2, Color(surface,0.3))

## Espuma numa aresta da margem: 3 faixas com alfa caindo para dentro da
## água. A versão anterior era um corte chapado de 3px — mostrava o degrau.
func _foam(x: float, y: float, w: float, h: float, sx: float, sy: float) -> void:
	for i in 3:
		var a: float = [0.40, 0.21, 0.09][i]
		var t := float(i) * 2.6
		draw_rect(Rect2(x + sx * t, y + sy * t, w, h), Color(BiomeArt.palette(world.stage_idx)[3], a * 0.7))
