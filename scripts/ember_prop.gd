class_name EmberProp
extends Node2D

## Brasa da Terra Queimada: pedras de basalto com fendas acesas.
## Decorativo (não bloqueia). Posição = base do prop.

var variant := 0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var A := ArtUtil
	var v := variant % 3
	var w := 9.0 + v * 1.5

	A.fill_ellipse(self, 0, 4, w + 2, 4, Color(0, 0, 0, 0.3))
	var body := PackedVector2Array([
		Vector2(-w, 4), Vector2(-w * 0.7, -4), Vector2(-w * 0.2, -7),
		Vector2(w * 0.4, -6), Vector2(w * 0.9, -2), Vector2(w, 4),
	])
	A.shade_poly(self, body, Color(0.32, 0.26, 0.24), Color(0.12, 0.09, 0.09))
	# fendas acesas
	var glow := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.004 + variant)
	var fire := Color(1, 0.45 + 0.15 * glow, 0.1, 0.75 + 0.25 * glow)
	draw_line(Vector2(-w * 0.4, 2), Vector2(-w * 0.1, -4), fire, 1.6)
	draw_line(Vector2(w * 0.2, 3), Vector2(w * 0.3, -3), fire, 1.3)
	A.fill_ellipse(self, 0, -6, 3, 2, Color(1, 0.6, 0.15, 0.5 * glow))
	# brasinhas ao redor
	for i in 3:
		var a := float(variant * 2 + i) * 2.1
		var d := 10.0 + (i % 2) * 4.0
		draw_circle(Vector2(cos(a) * d, 4 + sin(a) * 2.0), 1.2,
			Color(1, 0.5, 0.15, 0.5))
