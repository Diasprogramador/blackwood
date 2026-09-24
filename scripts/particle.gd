class_name ParticleFx
extends Node2D

## Port de Particle.java — partícula com vida decrescente e amortecimento.

var vx := 0.0
var vy := 0.0
var life := 30
var max_life := 30
var color := Color.WHITE
var _frames := 30

func setup(x: float, y: float, p_vx: float, p_vy: float, p_color: Color) -> void:
	position = Vector2(x, y)
	vx = p_vx
	vy = p_vy
	color = p_color
	life = 30
	max_life = life
	z_index = 16

func _process(_delta: float) -> void:
	# update a 60 fps (como no Java)
	position += Vector2(vx, vy)
	vx *= 0.96
	vy *= 0.96
	life -= 1
	queue_redraw()
	if is_dead():
		queue_free()

func is_dead() -> bool:
	return life <= 0

func _draw() -> void:
	var ratio := life / float(maxi(1, max_life))
	var size := maxi(1, int(5.0 * ratio))
	var alpha := clampf(ratio, 0.0, 1.0)
	var c := Color(color.r, color.g, color.b, alpha)
	draw_circle(Vector2.ZERO, size * 0.5, c)
