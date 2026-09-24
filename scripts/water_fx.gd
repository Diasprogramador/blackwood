class_name WaterFx
extends Node2D

## Brilho animado da água — redesenha apenas os tiles de água.

var world: World
var _t := 0.0

func _ready() -> void:
	z_index = -9

func _process(delta: float) -> void:
	_t += delta
	if int(_t * 8.0) % 2 == 0:
		queue_redraw()

func _draw() -> void:
	if world == null:
		return
	var TILE := World.TILE
	for tile in world._water_tiles:
		var px := tile.x * TILE
		var py := tile.y * TILE
		var phase := _t * 2.0 + tile.x * 0.7 + tile.y * 0.45
		# ondulação
		var ox := sin(phase) * 5.0
		draw_rect(Rect2(px + 6 + ox, py + 10, 9, 2), Color(0.4, 0.65, 0.9, 0.5))
		var ox2 := sin(phase + 1.6) * 4.0
		draw_rect(Rect2(px + 16 - ox2, py + 20, 7, 2), Color(0.35, 0.6, 0.85, 0.4))
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
				draw_rect(Rect2(px + TILE - 3, py, 3, TILE), Color(0.8, 0.92, 1, 0.35))
				ArtUtil.fill_ellipse(self, px + TILE - 2, fy, 2, wob, Color(0.9, 0.96, 1, 0.4))
			elif d.x == -1:
				draw_rect(Rect2(px, py, 3, TILE), Color(0.8, 0.92, 1, 0.35))
				ArtUtil.fill_ellipse(self, px + 2, fy, 2, wob, Color(0.9, 0.96, 1, 0.4))
			elif d.y == 1:
				draw_rect(Rect2(px, py + TILE - 3, TILE, 3), Color(0.8, 0.92, 1, 0.35))
				ArtUtil.fill_ellipse(self, fx, py + TILE - 2, wob, 2, Color(0.9, 0.96, 1, 0.4))
			else:
				draw_rect(Rect2(px, py, TILE, 3), Color(0.8, 0.92, 1, 0.35))
				ArtUtil.fill_ellipse(self, fx, py + 2, wob, 2, Color(0.9, 0.96, 1, 0.4))
