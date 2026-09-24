class_name AttackEffect
extends Node2D

## Port de AttackEffect.java — efeitos visuais animados de combate.

enum Type {
	SLASH,          # soco básico - arco amarelo
	MAGIC_BURST,    # habilidade mágica - explosão ciano
	HEAL,           # cura - partículas verdes subindo
	CRIT,           # crítico - estrela laranja grande
	ENEMY_HIT,      # inimigo acertou - flash vermelho
	SHADOW_STRIKE,  # assassino - lâmina escura
	FROST_ARROW,    # atiradora - flecha gelo
	CHANNEL         # canalização de mana - aura azul
}

var type: int = Type.SLASH
var life := 0
var max_life := 1
var angle := 0.0
var fx_scale := 1.0

func _init(type_p: int = Type.SLASH, x: float = 0.0, y: float = 0.0,
		angle_p: float = 0.0, scale_p: float = 1.0) -> void:
	type = type_p
	position = Vector2(x, y)
	angle = angle_p
	fx_scale = scale_p
	z_index = 15
	match type:
		Type.SLASH: max_life = 14
		Type.MAGIC_BURST: max_life = 20
		Type.HEAL: max_life = 30
		Type.CRIT: max_life = 18
		Type.ENEMY_HIT: max_life = 10
		Type.SHADOW_STRIKE: max_life = 16
		Type.FROST_ARROW: max_life = 14
		Type.CHANNEL: max_life = 9999
	life = max_life

func update() -> void:
	if life > 0 and type != Type.CHANNEL:
		life -= 1
	if type == Type.CHANNEL:
		life = max_life

func is_dead() -> bool:
	return type != Type.CHANNEL and life <= 0

func set_position_xy(x: float, y: float) -> void:
	position = Vector2(x, y)

func _process(_delta: float) -> void:
	update()
	queue_redraw()
	if is_dead():
		queue_free()

func _draw() -> void:
	var t := life / float(maxi(1, max_life))  # 1.0 → 0.0
	var inv := 1.0 - t                        # 0.0 → 1.0
	match type:
		Type.SLASH: _draw_slash(t, inv)
		Type.MAGIC_BURST: _draw_magic_burst(t, inv)
		Type.HEAL: _draw_heal(t, inv)
		Type.CRIT: _draw_crit(t, inv)
		Type.ENEMY_HIT: _draw_enemy_hit(t)
		Type.SHADOW_STRIKE: _draw_shadow_strike(t, inv)
		Type.FROST_ARROW: _draw_frost_arrow(t, inv)
		Type.CHANNEL: _draw_channel_aura()

func _draw_slash(t: float, inv: float) -> void:
	var r := 30.0 * fx_scale * (0.5 + inv * 0.8)
	var alpha := t
	draw_arc(Vector2.ZERO, r, deg_to_rad(-40 + angle * 57.0),
		deg_to_rad(-40 + angle * 57.0 + 90), 16,
		Color(1, 1, 0.47, alpha), 3.0)
	draw_arc(Vector2.ZERO, r - 4.0, deg_to_rad(-40 + angle * 57.0),
		deg_to_rad(-40 + angle * 57.0 + 70), 14,
		Color(1, 1, 1, alpha * 0.5), 1.5)

func _draw_magic_burst(t: float, inv: float) -> void:
	var r := 40.0 * fx_scale * inv
	var alpha := 0.86 * t
	draw_arc(Vector2.ZERO, r, 0, TAU, 28, Color(0.31, 0.86, 1, alpha), 2.5)
	draw_arc(Vector2.ZERO, r * 0.6, 0, TAU, 24, Color(0.71, 0.94, 1, alpha), 1.5)
	var rc := maxf(2.0, 10.0 * t)
	draw_circle(Vector2.ZERO, rc, Color(1, 1, 1, alpha))
	for i in 6:
		var a := i * PI / 3.0 + inv * 2.0
		draw_circle(Vector2(cos(a) * r, sin(a) * r), 2.0, Color(0.39, 0.9, 1, alpha))

func _draw_heal(t: float, inv: float) -> void:
	var alpha := t
	var s := 14.0 * fx_scale
	var y := -inv * 30.0
	var col := Color(0.31, 1, 0.47, alpha)
	draw_line(Vector2(-s, y), Vector2(s, y), col, 3.0)
	draw_line(Vector2(0, y - s), Vector2(0, y + s), col, 3.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(8, y - 10 - inv * 20.0), "+",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.47, 1, 0.55, alpha))

func _draw_crit(t: float, inv: float) -> void:
	var r := 50.0 * fx_scale * (0.3 + inv * 0.9)
	var alpha := t
	var pts := PackedVector2Array()
	for i in 16:
		var a := i * PI / 8.0 - PI / 2.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(Vector2(cos(a) * rr, sin(a) * rr))
	draw_colored_polygon(pts, Color(1, 0.78, 0.2, alpha))
	var fc := maxf(3.0, 16.0 * t)
	draw_circle(Vector2.ZERO, fc, Color(1, 1, 1, alpha * 0.9))
	if t > 0.4:
		var font := ThemeDB.fallback_font
		var txt := "CRÍTICO!"
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(font, Vector2(-tw / 2, -r - 8), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.31, 0.16, alpha))

func _draw_enemy_hit(t: float) -> void:
	var alpha := t
	var r := 18.0 * t + 6.0
	draw_circle(Vector2.ZERO, r, Color(1, 0.24, 0.24, alpha * 0.78))
	draw_line(Vector2(-6, -6), Vector2(6, 6), Color(1, 1, 1, alpha), 2.0)
	draw_line(Vector2(-6, 6), Vector2(6, -6), Color(1, 1, 1, alpha), 2.0)

func _draw_shadow_strike(t: float, inv: float) -> void:
	var alpha := t
	var length := 40.0 * fx_scale * inv
	for i in range(-1, 2):
		var off := i * 10.0
		draw_line(
			Vector2(off - length / 3.0, -length / 2.0 + off),
			Vector2(off + length / 3.0, length / 2.0 + off),
			Color(0.31, 0.08, 0.47, alpha), 3.0)
	draw_circle(Vector2.ZERO, 8.0, Color(0.71, 0.31, 1, alpha * 0.5))

func _draw_frost_arrow(t: float, inv: float) -> void:
	var alpha := t
	var r := 30.0 * fx_scale * inv
	var col := Color(0.59, 0.86, 1, alpha)
	for i in 6:
		var a := i * PI / 3.0
		var e := Vector2(cos(a) * r, sin(a) * r)
		draw_line(Vector2.ZERO, e, col, 2.0)
		var m := e * 0.5
		draw_line(m, m + Vector2(5, -5), col, 1.5)
		draw_line(m, m + Vector2(5, 5), col, 1.5)
	draw_circle(Vector2.ZERO, 5.0, Color(0.86, 0.96, 1, alpha))

func _draw_channel_aura() -> void:
	var pulse := sin(Time.get_ticks_msec() * 0.008) * 0.5 + 0.5
	var r := 35.0 + pulse * 12.0
	draw_circle(Vector2.ZERO, r, Color(0.24, 0.47, 1, 0.16 + pulse * 0.12))
	draw_arc(Vector2.ZERO, r - 6.0, 0, TAU, 32, Color(0.31, 0.63, 1, 0.4), 2.0)
	var r2 := 18.0 + pulse * 8.0
	draw_arc(Vector2.ZERO, r2, 0, TAU, 28, Color(0.59, 0.78, 1, 0.6), 2.0)
	var now := Time.get_ticks_msec()
	for i in 8:
		var phase := fmod(now * 0.003 + i * 0.8, 1.0)
		var px := sin(i * 2.1 + now * 0.002) * 20.0
		var py := -phase * 50.0
		var size := 4.0 * (1.0 - phase) + 1.0
		draw_circle(Vector2(px, py), size * 0.5, Color(0.47, 0.71, 1, (1.0 - phase) * 0.8))
	var font := ThemeDB.fallback_font
	var txt := "✦ canalizando ✦"
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(font, Vector2(-tw / 2, -55), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.71, 0.86, 1, 0.8))
