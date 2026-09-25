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
	CHANNEL,        # canalização de mana - aura azul
	TANK_SLAM,      # Garen - onda de choque dourada + rachaduras
	SHADOW_CLAWS,   # Zed - garras de sombra violeta
	ARCANE_NOVA,    # Ahri - nova arcana com runa girando
	FROST_VOLLEY,   # Ashe - saraivada de estilhaços de gelo
	GALE_SWIPE,     # Janna - redemoinho de vento teal
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
		Type.TANK_SLAM: max_life = 18
		Type.SHADOW_CLAWS: max_life = 16
		Type.ARCANE_NOVA: max_life = 22
		Type.FROST_VOLLEY: max_life = 16
		Type.GALE_SWIPE: max_life = 16
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
		Type.TANK_SLAM: _draw_tank_slam(t, inv)
		Type.SHADOW_CLAWS: _draw_shadow_claws(t, inv)
		Type.ARCANE_NOVA: _draw_arcane_nova(t, inv)
		Type.FROST_VOLLEY: _draw_frost_volley(t, inv)
		Type.GALE_SWIPE: _draw_gale_swipe(t, inv)
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

## Clarão no chão + anel se expandindo (base de todos os golpes).
func _ground_flash(t: float, inv: float, col: Color, wide: float = 1.0) -> void:
	if GameSettings.quality_cache >= 2:
		# Qualidade Baixa: só o clarão, sem anéis.
		var w0 := 30.0 * fx_scale * wide
		draw_ellipse_poly(Vector2(0, 26), w0, w0 * 0.35, Color(col, 0.3 * t))
		return
	var w := (34.0 + inv * 30.0) * fx_scale * wide
	draw_ellipse_poly(Vector2(0, 26), w, w * 0.35, Color(col, 0.35 * t))
	var r := (10.0 + inv * 46.0) * fx_scale
	draw_arc(Vector2.ZERO, r, 0, TAU, 28, Color(col, 0.7 * t), 3.0)
	draw_arc(Vector2.ZERO, r * 0.65, 0, TAU, 24, Color(1, 1, 1, 0.4 * t), 1.5)

func _draw_tank_slam(t: float, inv: float) -> void:
	var gold := Color(1, 0.8, 0.3)
	_ground_flash(t, inv, gold, 1.2)
	for i in 8:
		var a := TAU * i / 8.0 + angle
		var l0 := 12.0 * fx_scale
		var l1 := (12.0 + inv * 44.0) * fx_scale
		draw_line(Vector2(cos(a), sin(a)) * l0, Vector2(cos(a), sin(a)) * l1, Color(gold, 0.85 * t), 3.0)
	draw_circle(Vector2.ZERO, maxf(3.0, 14.0 * t) * fx_scale, Color(1, 0.95, 0.7, 0.9 * t))
	for i in 6:
		var a := TAU * i / 6.0 + inv * 1.5
		draw_circle(Vector2(cos(a), sin(a)) * 30.0 * fx_scale * inv, 2.5, Color(gold, 0.6 * t))

func _draw_shadow_claws(t: float, inv: float) -> void:
	var vio := Color(0.55, 0.2, 0.9)
	_ground_flash(t, inv, vio, 0.9)
	draw_circle(Vector2.ZERO, 20.0 * fx_scale * inv + 6.0, Color(0.25, 0.05, 0.45, 0.45 * t))
	for i in 3:
		var off := (i - 1) * 12.0
		var p0 := Vector2(off - 26.0 * fx_scale * inv, -20.0 + off * 0.5)
		var p1 := Vector2(off + 26.0 * fx_scale * inv, 20.0 + off * 0.5)
		draw_line(p0, p1, Color(vio, 0.9 * t), 4.0)
		draw_line(p0, p1, Color(0.9, 0.7, 1, 0.5 * t), 1.5)
	draw_circle(Vector2.ZERO, maxf(2.0, 8.0 * t), Color(0.85, 0.6, 1, 0.8 * t))

func _draw_arcane_nova(t: float, inv: float) -> void:
	var arc := Color(0.7, 0.35, 1)
	_ground_flash(t, inv, arc, 1.0)
	var tri := PackedVector2Array()
	for i in 3:
		var a := -PI * 0.5 + inv * 2.5 + TAU * i / 3.0
		tri.append(Vector2(cos(a), sin(a)) * 26.0 * fx_scale)
	draw_polyline_closed(tri, Color(arc, 0.85 * t), 2.5)
	draw_arc(Vector2.ZERO, (14.0 + inv * 34.0) * fx_scale, 0, TAU, 28, Color(0.45, 0.85, 1, 0.7 * t), 2.5)
	draw_circle(Vector2.ZERO, maxf(3.0, 12.0 * t) * fx_scale, Color(1, 1, 1, 0.9 * t))
	for i in 6:
		var a := TAU * i / 6.0 - inv * 3.0
		var rr := (20.0 + inv * 22.0) * fx_scale
		draw_circle(Vector2(cos(a) * rr, sin(a) * rr), 2.5, Color(0.6, 0.95, 1, 0.8 * t))

func _draw_frost_volley(t: float, inv: float) -> void:
	var ice := Color(0.6, 0.88, 1)
	_ground_flash(t, inv, ice, 1.0)
	for i in 5:
		var x := (i - 2) * 14.0 * fx_scale
		var y0 := -44.0 * fx_scale + inv * 40.0 * fx_scale
		var y1 := y0 + 26.0 * fx_scale
		draw_line(Vector2(x, y0), Vector2(x, y1), Color(ice, 0.9 * t), 3.0)
		draw_circle(Vector2(x, y1), 3.0, Color(1, 1, 1, 0.85 * t))
		draw_line(Vector2(x, y1), Vector2(x - 5, y1 - 7), Color(ice, 0.7 * t), 1.5)
		draw_line(Vector2(x, y1), Vector2(x + 5, y1 - 7), Color(ice, 0.7 * t), 1.5)
	draw_arc(Vector2.ZERO, (12.0 + inv * 30.0) * fx_scale, 0, TAU, 24, Color(ice, 0.5 * t), 2.0)

func _draw_gale_swipe(t: float, inv: float) -> void:
	var teal := Color(0.35, 0.95, 0.85)
	_ground_flash(t, inv, teal, 1.0)
	for k in 2:
		var rr := (16.0 + k * 12.0 + inv * 26.0) * fx_scale
		draw_arc(Vector2.ZERO, rr, -0.9 + inv * 1.2 + k * 0.5, 1.6 + inv * 1.2 + k * 0.5,
			22, Color(teal, (0.85 - k * 0.25) * t), 3.5 - k)
	for i in 6:
		var a := TAU * i / 6.0 + inv * 2.0
		var rr := (10.0 + inv * 34.0) * fx_scale
		draw_circle(Vector2(cos(a) * rr, sin(a) * rr * 0.6), 2.0, Color(0.85, 1, 0.95, 0.7 * t))
	draw_line(Vector2(-8, 0), Vector2(8, 0), Color(1, 1, 1, 0.7 * t), 2.0)
	draw_line(Vector2(0, -8), Vector2(0, 8), Color(1, 1, 1, 0.7 * t), 2.0)

func draw_ellipse_poly(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)

func draw_polyline_closed(pts: PackedVector2Array, col: Color, w: float) -> void:
	if pts.size() < 2:
		return
	var closed := PackedVector2Array(pts)
	closed.append(pts[0])
	draw_polyline(closed, col, w, true)

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
