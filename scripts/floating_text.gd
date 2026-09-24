class_name FloatingText
extends Node2D

## Texto flutuante (dano, gold, mensagens de combate).

var text := ""
var color := Color.WHITE
var font_size := 12
var life := 1.0
var _max_life := 1.0
var _rise := 40.0

func setup(msg: String, col: Color, pos: Vector2, size: int = 12, duration: float = 1.0) -> void:
	text = msg
	color = col
	position = pos
	font_size = size
	life = duration
	_max_life = duration

func _process(delta: float) -> void:
	life -= delta
	position.y -= _rise * delta / maxf(0.2, _max_life)
	queue_redraw()
	if life <= 0.0:
		queue_free()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var alpha := clampf(life / _max_life, 0.0, 1.0)
	if alpha < 0.5:
		alpha *= 2.0
	var c := Color(color.r, color.g, color.b, minf(1.0, alpha))
	# sombra
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(-tw / 2 + 1, 1), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, c.a * 0.7))
	draw_string(font, Vector2(-tw / 2, 0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, c)
