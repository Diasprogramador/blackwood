class_name TreeProp
extends Node2D

## Árvore realista: tronco com casca em gradiente, raízes, copa em camadas
## com luz/sombra e sombra no chão. Posição = base do tronco.

var variant := 0
var _scale := 1.0

func _ready() -> void:
	_scale = 0.85 + hash(position) % 40 / 100.0
	queue_redraw()

func _draw() -> void:
	var A := ArtUtil
	var s := _scale
	var v := variant % 3

	# --- sombra no chão ---
	A.fill_ellipse(self, 2 * s, 4, 16 * s, 6 * s, Color(0, 0, 0, 0.32))
	A.fill_ellipse(self, 0, 3, 13 * s, 5 * s, Color(0, 0, 0, 0.2))

	# --- raízes ---
	var root_col := Color(0.28, 0.17, 0.08)
	for dir in [-1, 1]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, -2), Vector2(dir * 7 * s, -1),
			Vector2(dir * 10 * s, 4), Vector2(dir * 3 * s, 3),
		]), root_col)

	# --- tronco (gradiente lateral: luz à esquerda) ---
	var trunk_w := 7.0 * s
	var trunk_h := 22.0 * s
	var bark_l := Color(0.45, 0.3, 0.16)
	var bark_d := Color(0.24, 0.14, 0.07)
	draw_polygon(
		PackedVector2Array([
			Vector2(-trunk_w * 0.7, 2), Vector2(-trunk_w * 0.5, -trunk_h),
			Vector2(trunk_w * 0.5, -trunk_h), Vector2(trunk_w * 0.7, 2),
		]),
		PackedColorArray([bark_l, bark_l.lerp(bark_d, 0.3), bark_d, bark_d.lerp(Color.BLACK, 0.2)])
	)
	# sulcos da casca
	var bark_line := Color(0.18, 0.1, 0.05, 0.7)
	draw_line(Vector2(-1.5 * s, 0), Vector2(-2 * s, -trunk_h + 4), bark_line, 1)
	draw_line(Vector2(2 * s, -2), Vector2(2.5 * s, -trunk_h + 6), bark_line, 1)
	# brilho na borda esquerda
	draw_line(Vector2(-trunk_w * 0.6, -2), Vector2(-trunk_w * 0.45, -trunk_h + 3),
		Color(0.6, 0.45, 0.28, 0.7), 1.2)

	# --- copa: 3 camadas de blobs ---
	var base_y := -trunk_h - 4
	match v:
		0:
			_blob(Vector2(0, base_y - 8), 16 * s, 13 * s, 0)
			_blob(Vector2(-9 * s, base_y + 2), 11 * s, 9 * s, 1)
			_blob(Vector2(9 * s, base_y + 1), 11 * s, 9 * s, 1)
			_blob(Vector2(0, base_y - 14), 10 * s, 8 * s, 2)
		1:
			_blob(Vector2(0, base_y - 4), 14 * s, 14 * s, 0)
			_blob(Vector2(-8 * s, base_y - 12), 10 * s, 9 * s, 2)
			_blob(Vector2(8 * s, base_y - 10), 10 * s, 9 * s, 2)
			_blob(Vector2(0, base_y + 4), 12 * s, 8 * s, 1)
		_:
			_blob(Vector2(0, base_y - 10), 15 * s, 15 * s, 0)
			_blob(Vector2(-10 * s, base_y - 4), 9 * s, 8 * s, 1)
			_blob(Vector2(10 * s, base_y - 6), 9 * s, 8 * s, 1)

	# --- frutos/cerejas ocasionais ---
	if variant % 4 == 3:
		for p in [Vector2(-6 * s, base_y - 10), Vector2(5 * s, base_y - 4), Vector2(1 * s, base_y - 16)]:
			A.fill_ellipse(self, p.x, p.y, 2, 2, Color(0.85, 0.25, 0.2))
			A.fill_ellipse(self, p.x - 0.6, p.y - 0.6, 0.7, 0.7, Color(1, 0.55, 0.5, 0.8))

	# --- veados de luz na copa ---
	A.fill_ellipse(self, -5 * s, base_y - 16, 5 * s, 3 * s, Color(0.55, 0.85, 0.4, 0.35))
	A.fill_ellipse(self, 4 * s, base_y - 18, 4 * s, 2.5 * s, Color(0.55, 0.85, 0.4, 0.3))

func _blob(c: Vector2, rx: float, ry: float, tone: int) -> void:
	var lights := [Color(0.28, 0.62, 0.26), Color(0.2, 0.5, 0.2), Color(0.35, 0.7, 0.3)]
	var darks := [Color(0.1, 0.32, 0.12), Color(0.07, 0.24, 0.1), Color(0.14, 0.4, 0.15)]
	ArtUtil.shade_ellipse(self, c.x, c.y, rx, ry, lights[tone], darks[tone])
	# contorno sutil
	draw_arc(c, rx, 0, TAU, 20, Color(0.05, 0.18, 0.08, 0.6), 1.2)
	# brilho superior
	ArtUtil.fill_ellipse(self, c.x - rx * 0.3, c.y - ry * 0.45,
		rx * 0.35, ry * 0.3, Color(0.6, 0.9, 0.45, 0.3))
