class_name GoldCoin
extends Node2D

## Moeda de gold que cai do inimigo: espalha, espera e magnetiza no jogador.

var value := 10
var _vel := Vector2.ZERO
var _wait := 0.35
var _life := 20.0
var _t := 0.0
var _collected := false
var _player: Player

signal collected(amount: int)

## Cobre (troco) → prata → ouro → gema roxa (elites).
func _tier() -> Array:
	if value <= 15:
		return [Color(0.9, 0.6, 0.32), Color(0.55, 0.32, 0.13), Color(0.45, 0.25, 0.1)]
	if value <= 40:
		return [Color(0.88, 0.91, 0.96), Color(0.52, 0.57, 0.66), Color(0.4, 0.44, 0.52)]
	if value <= 100:
		return [Color(1, 0.85, 0.3), Color(0.75, 0.55, 0.1), Color(0.55, 0.4, 0.05)]
	return [Color(0.82, 0.42, 1), Color(0.46, 0.16, 0.72), Color(0.35, 0.1, 0.55)]

func setup(amount: int, from_pos: Vector2, player: Player) -> void:
	value = maxi(1, amount)
	position = from_pos
	_player = player
	var a := randf() * TAU
	var sp := randf_range(40.0, 110.0)
	_vel = Vector2(cos(a), sin(a)) * sp
	# levemente acima do chão para y-sort
	z_index = 1

func _process(delta: float) -> void:
	if _collected:
		return
	_t += delta
	queue_redraw()

	if _wait > 0.0:
		_wait -= delta
		position += _vel * delta
		_vel = _vel.lerp(Vector2.ZERO, 8.0 * delta)
		return

	_life -= delta
	if _player == null or not _player.is_alive():
		if _life <= 0:
			queue_free()
		return

	var d := position.distance_to(_player.position)
	if d < 90.0:
		var dir := (_player.position - position).normalized()
		var speed := lerpf(120.0, 420.0, clampf(1.0 - d / 90.0, 0.0, 1.0))
		position += dir * speed * delta
	if d < 18.0:
		_collected = true
		collected.emit(value)
		queue_free()
	elif _life <= 0.0:
		queue_free()

func _draw() -> void:
	var bounce := absf(sin(_t * 6.0)) * 2.0 if _wait <= 0.0 else absf(sin(_t * 10.0)) * 3.0
	var y_off := -2.0 - bounce
	var spin := absf(cos(_t * 5.0))
	var rx := maxf(2.0, 6.0 * spin)

	# sombra
	ArtUtil.fill_ellipse(self, 0, 4, 6, 2.5, Color(0, 0, 0, 0.3))
	# metal por valor: cobre → prata → ouro → gema (ver _tier)
	var tier := _tier()
	var light: Color = tier[0]
	var dark: Color = tier[1]
	var edge: Color = tier[2]
	var big := value >= 100
	if big:
		ArtUtil.fill_ellipse(self, 0, y_off, 11, 8,
			Color(light.r, light.g, light.b, 0.25))
	# moeda
	ArtUtil.shade_ellipse(self, 0, y_off, rx, 6, light, dark)
	draw_arc(Vector2(0, y_off), 6, 0, TAU, 16, edge, 1.2)
	# brilho
	ArtUtil.fill_ellipse(self, -rx * 0.3, y_off - 2, rx * 0.3, 1.5, Color(1, 1, 0.9, 0.8))
	# cifrão simples
	if rx > 3.5:
		draw_line(Vector2(0, y_off - 3), Vector2(0, y_off + 3), edge, 1.2)
	# gema grande ganha estrelinha
	if big:
		draw_colored_polygon(ArtUtil.star_pts(0, y_off - 12, 3.5), Color(1, 1, 1, 0.85))

	# valor (pequeno)
	if _t < 1.2:
		var font := ThemeDB.fallback_font
		var label := str(value)
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(font, Vector2(-tw / 2, y_off - 9), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.9, 0.4, clampf(1.4 - _t, 0.0, 1.0)))
