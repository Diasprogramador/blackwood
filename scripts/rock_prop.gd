class_name RockProp
extends Node2D

## Pedra realista: facetas com gradiente, fendas, musgo e grama na base.
## Posição = centro da pedra (pé no chão levemente abaixo).

var variant := 0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var A := ArtUtil
	var v := variant % 3

	A.fill_ellipse(self, 1, 6, 12, 4.5, Color(0, 0, 0, 0.3))
	A.fill_ellipse(self, 0, 5, 10, 3.5, Color(0, 0, 0, 0.18))

	var w := 11.0 if v != 2 else 13.0
	var h := 9.0 if v != 1 else 7.0

	# corpo principal (polígono irregular com gradiente vertical)
	var body := PackedVector2Array([
		Vector2(-w, 4), Vector2(-w * 0.8, -h * 0.5), Vector2(-w * 0.3, -h),
		Vector2(w * 0.35, -h * 0.9), Vector2(w * 0.9, -h * 0.35),
		Vector2(w, 4),
	])
	A.shade_poly(self, body, Color(0.72, 0.73, 0.76), Color(0.38, 0.39, 0.43))
	A.stroke(self, body, Color(0.25, 0.26, 0.3), 1.3)

	# faceta frontal mais escura
	var facet := PackedVector2Array([
		Vector2(-w * 0.4, 4), Vector2(-w * 0.2, -h * 0.4),
		Vector2(w * 0.5, -h * 0.3), Vector2(w * 0.7, 4),
	])
	A.shade_poly(self, facet, Color(0.55, 0.56, 0.6), Color(0.32, 0.33, 0.37))

	# topo iluminado
	var top := PackedVector2Array([
		Vector2(-w * 0.3, -h), Vector2(-w * 0.1, -h - 1.5),
		Vector2(w * 0.3, -h * 0.9 - 1), Vector2(w * 0.35, -h * 0.9),
	])
	A.shade_poly(self, top, Color(0.88, 0.89, 0.92), Color(0.65, 0.66, 0.7))

	# fendas
	var crack := Color(0.2, 0.21, 0.24, 0.8)
	draw_line(Vector2(-w * 0.2, -h * 0.7), Vector2(-w * 0.05, 2), crack, 1.1)
	draw_line(Vector2(-w * 0.05, 0), Vector2(w * 0.15, 3), crack, 1)
	draw_line(Vector2(w * 0.4, -h * 0.5), Vector2(w * 0.5, 2), crack, 1)

	# musmo no topo/sombra
	A.fill_ellipse(self, -w * 0.35, -h * 0.55, 4, 2.5, Color(0.3, 0.55, 0.25, 0.55))
	A.fill_ellipse(self, w * 0.1, -h * 0.8, 3, 2, Color(0.3, 0.55, 0.25, 0.45))
	if v == 1:
		A.fill_ellipse(self, w * 0.5, 1, 3.5, 2, Color(0.35, 0.6, 0.3, 0.5))

	# grama na base
	var grass := Color(0.25, 0.55, 0.22)
	for i in 5:
		var gx := -w + i * (w * 0.5)
		draw_line(Vector2(gx, 5), Vector2(gx + 1, 1), grass, 1.2)
		draw_line(Vector2(gx + 2, 5), Vector2(gx + 1.5, 2), Color(0.35, 0.68, 0.3), 1)

	# brilho especular
	A.fill_ellipse(self, -w * 0.4, -h * 0.7, 2, 1.2, Color(1, 1, 1, 0.35))
