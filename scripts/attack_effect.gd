class_name AttackEffect
extends Node2D

## Efeitos de combate 100% procedurais (zero texturas, zero nós extras).
## Cada campeão tem a própria família visual e cada skill tem o próprio
## golpe: `type` codifica família + slot, então o RPC do multiplayer
## continua mandando um inteiro só.
##
## Performance (PC e celular):
##  * o tempo é medido em SEGUNDOS — antes o efeito morria "por frame", o
##    que rodava 2x mais rápido em tela de 120 Hz e 2x mais lento a 30 Hz;
##  * o detalhe (raios, faíscas, elipse de chão, rastro) é cortado pela
##    qualidade em GameSettings.quality_cache (0 Alta / 1 Média / 2 Baixa);
##  * MAX_LIVE limita efeitos simultâneos: em rajada o mais caro é pulado;
##  * tudo é desenhado com draw_line/draw_circle/draw_arc (sem polígonos
##    grandes) e sem alocar arrays por quadro onde dá para evitar.

enum Type {
	SLASH,         # 0  legado (fallback)
	MAGIC_BURST,   # 1  legado
	HEAL,          # 2
	CRIT,          # 3
	ENEMY_HIT,     # 4
	SHADOW_STRIKE, # 5  legado
	FROST_ARROW,   # 6  legado
	CHANNEL,       # 7
}

## Famílias de campeão: 0 Tanque, 1 Assassino, 2 Mago, 3 Atirador, 4 Suporte.
const ROLES := ["tank", "assassin", "mage", "marksman", "support"]
## type = ROLE_FX_BASE + familia * SLOTS + slot  (slot 0 = básico, 1..5 = skill)
const ROLE_FX_BASE := 16
const SLOTS := 6
## type = ROLE_HEAL_BASE + familia  (cura tingida com a cor do campeão)
const ROLE_HEAL_BASE := ROLE_FX_BASE + 5 * SLOTS  # 46..50

## Teto de efeitos vivos ao mesmo tempo.
const MAX_LIVE := 24

## Paleta por campeão: [principal, profundo, claro, destaque].
const PAL := [
	[Color(1.0, 0.78, 0.24), Color(0.34, 0.27, 0.06), Color(1.0, 0.97, 0.82), Color(0.45, 0.68, 1.0)],
	[Color(0.74, 0.30, 1.0), Color(0.13, 0.03, 0.22), Color(0.97, 0.85, 1.0), Color(1.0, 0.26, 0.42)],
	[Color(0.80, 0.44, 1.0), Color(0.22, 0.06, 0.42), Color(0.90, 0.96, 1.0), Color(0.45, 0.90, 1.0)],
	[Color(0.62, 0.88, 1.0), Color(0.13, 0.33, 0.68), Color(1.0, 1.0, 1.0), Color(0.30, 0.62, 1.0)],
	[Color(0.38, 0.95, 0.84), Color(0.05, 0.38, 0.34), Color(0.92, 1.0, 0.98), Color(0.62, 0.92, 1.0)],
]

## Contador de efeitos vivos (ver _exit_tree).
static var live := 0

# ======================================================================
#  Codificação tipo <-> campeão/slot
# ======================================================================
static func role_index(role: String) -> int:
	var i := ROLES.find(role)
	return i if i >= 0 else 0

## Efeito do campeão `role` para o slot (0 = ataque básico, 1..5 = skills).
static func role_fx(role: String, slot: int) -> int:
	return ROLE_FX_BASE + role_index(role) * SLOTS + clampi(slot, 0, SLOTS - 1)

## Cura do campeão (tingida com a paleta dele).
static func role_heal(role: String) -> int:
	return ROLE_HEAL_BASE + role_index(role)

static func is_role_fx(type: int) -> bool:
	return type >= ROLE_FX_BASE

## Familia (-1 se não for efeito de campeão).
static func family_of(type: int) -> int:
	if type >= ROLE_HEAL_BASE:
		return clampi(type - ROLE_HEAL_BASE, 0, 4)
	if type >= ROLE_FX_BASE:
		return int((type - ROLE_FX_BASE) / float(SLOTS))
	return -1

## Slot (-1 se não for ataque de campeão; -2 se for cura de campeão).
static func slot_of(type: int) -> int:
	if type >= ROLE_HEAL_BASE:
		return -2
	if type >= ROLE_FX_BASE:
		return (type - ROLE_FX_BASE) - family_of(type) * SLOTS
	return -1

static func pal_of(fam: int) -> Array:
	return PAL[clampi(fam, 0, 4)]

## Duração em segundos por tipo.
static func time_for(type: int) -> float:
	if type == Type.CHANNEL:
		return INF
	if type == Type.HEAL:
		return 0.55
	if type == Type.CRIT:
		return 0.42
	if type == Type.ENEMY_HIT:
		return 0.2
	if type >= ROLE_HEAL_BASE:
		return 0.55
	if type >= ROLE_FX_BASE:
		var slot := slot_of(type)
		if slot >= 5:
			return 0.55
		if slot >= 1:
			return 0.36
		return 0.28
	return 0.26

# ======================================================================
#  Estado
# ======================================================================
var type: int = Type.SLASH
var age := 0.0
var max_time := 0.3
## Direção do golpe (radianos): do atacante até o alvo.
var angle := 0.0
var fx_scale := 1.0
## Comprimento do rastro (0 = sem rastro).
var trail := 0.0

func _init(type_p: int = Type.SLASH, x: float = 0.0, y: float = 0.0,
		angle_p: float = 0.0, scale_p: float = 1.0) -> void:
	type = type_p
	position = Vector2(x, y)
	angle = angle_p
	fx_scale = scale_p
	z_index = 15
	max_time = time_for(type)
	if type >= ROLE_FX_BASE and type < ROLE_HEAL_BASE:
		trail = 70.0 * fx_scale
	live += 1

func _exit_tree() -> void:
	live -= 1

## Compat com a API antiga (a vida agora é tempo).
func update() -> void:
	pass

func is_dead() -> bool:
	return type != Type.CHANNEL and age >= max_time

func set_position_xy(x: float, y: float) -> void:
	position = Vector2(x, y)

func _process(delta: float) -> void:
	if type != Type.CHANNEL:
		age += delta
	queue_redraw()
	if is_dead():
		queue_free()

# ======================================================================
#  Desenho
# ======================================================================
func _draw() -> void:
	var t := 1.0
	if type != Type.CHANNEL:
		t = clampf(1.0 - age / maxf(0.001, max_time), 0.0, 1.0)
	var inv := 1.0 - t
	if type >= ROLE_HEAL_BASE:
		_draw_role_heal(clampi(type - ROLE_HEAL_BASE, 0, 4), t, inv)
		return
	if type >= ROLE_FX_BASE:
		var k := type - ROLE_FX_BASE
		var fam := int(k / float(SLOTS))
		_draw_role(fam, k - fam * SLOTS, t, inv)
		return
	match type:
		Type.SLASH: _draw_slash(t, inv)
		Type.MAGIC_BURST: _draw_magic_burst(t, inv)
		Type.HEAL: _draw_heal(t, inv)
		Type.CRIT: _draw_crit(t, inv)
		Type.ENEMY_HIT: _draw_enemy_hit(t, inv)
		Type.SHADOW_STRIKE: _draw_slash(t, inv)
		Type.FROST_ARROW: _draw_magic_burst(t, inv)
		Type.CHANNEL: _draw_channel_aura()

# ----------------------------------------------------------------------
#  Primitivas (todas leem GameSettings.quality_cache)
# ----------------------------------------------------------------------
func _q() -> int:
	return GameSettings.quality_cache

## Segmentos de arco reduzidos em qualidades mais baixas.
func _segs(n: int) -> int:
	var q := _q()
	if q >= 2:
		return maxi(6, int(n * 0.5))
	if q == 1:
		return maxi(8, int(n * 0.75))
	return n

## Anel de choque expandindo.
func _ring(t: float, inv: float, col: Color, r0: float, r1: float, w: float) -> void:
	var r := lerpf(r0, r1, inv) * fx_scale
	if r <= 1.0:
		return
	draw_arc(Vector2.ZERO, r, 0.0, TAU, _segs(26), Color(col, 0.85 * t), w)
	if _q() == 0:
		draw_arc(Vector2.ZERO, r * 0.82, 0.4, TAU - 0.2, _segs(18),
			Color(1, 1, 1, 0.3 * t), w * 0.4)

## Clarão central (some rápido).
func _core(t: float, inv: float, col: Color, r: float, k: float = 1.0) -> void:
	var rr := lerpf(r, r * 0.25, inv) * fx_scale * k
	if rr <= 0.5:
		return
	draw_circle(Vector2.ZERO, rr, Color(col, 0.85 * t))

## Raios radiais.
func _rays(t: float, inv: float, col: Color, count: int, r0: float, r1: float,
		spin: float = 0.0) -> void:
	var n := count
	var q := _q()
	if q >= 2:
		n = maxi(4, int(count * 0.5))
	elif q == 1:
		n = maxi(5, int(count * 0.75))
	var d0 := r0 * fx_scale
	var d1 := lerpf(r0, r1, inv) * fx_scale
	for i in n:
		var a := TAU * float(i) / float(n) + spin
		var ca := cos(a)
		var sa := sin(a)
		draw_line(Vector2(ca, sa) * d0, Vector2(ca, sa) * d1, Color(col, 0.8 * t), 2.5)

## Faíscas voando (sumidas em Baixa).
func _sparks(t: float, inv: float, col: Color, count: int, phase: float) -> void:
	var q := _q()
	if q >= 2:
		return
	var n := count if q == 0 else maxi(3, int(count * 0.6))
	var rr := lerpf(12.0, 54.0, inv) * fx_scale
	var sz := maxf(1.0, 2.4 * t)
	for i in n:
		var a := TAU * float(i) / float(n) + phase
		var p := Vector2(cos(a), sin(a) * 0.75) * rr
		draw_circle(p, sz, Color(col, 0.85 * t))

## Clarão no chão (elipse achatada embaixo do alvo).
func _pool(t: float, inv: float, col: Color, wide: float = 1.0) -> void:
	var q := _q()
	var w := (24.0 + inv * 30.0) * fx_scale * wide
	if w <= 2.0:
		return
	var n := 18
	if q == 1:
		n = 13
	elif q >= 2:
		n = 8
	var cy := 26.0
	var ry := w * 0.32
	var pts := PackedVector2Array()
	pts.resize(n)
	for i in n:
		var a := TAU * float(i) / float(n)
		pts[i] = Vector2(cos(a) * w, cy + sin(a) * ry)
	draw_colored_polygon(pts, Color(col, (0.3 if q >= 2 else 0.36) * t))
	if q >= 2:
		return
	draw_arc(Vector2(0, cy), w * 0.72, 0, TAU, _segs(20), Color(col, 0.6 * t), 2.5)

## Rastro do golpe vindo do atacante (só em Alta/Média).
func _streak(t: float, col: Color, hi: Color) -> void:
	if trail <= 0.0 or _q() >= 2:
		return
	var inv := 1.0 - t
	var len := trail * maxf(0.0, 1.0 - inv * 0.75)
	if len <= 2.0:
		return
	var dir := Vector2(cos(angle), sin(angle))
	var p0 := -dir * len
	var w := fx_scale
	draw_line(p0, Vector2.ZERO, Color(col, 0.30 * t), 9.0 * w)
	draw_line(p0, Vector2.ZERO, Color(col, 0.75 * t), 4.0 * w)
	draw_line(p0, Vector2.ZERO, Color(hi, 0.95 * t), 1.6 * w)
	if _q() == 0:
		var head := -dir * len * 0.35
		draw_circle(head, 4.0 * w, Color(hi, 0.6 * t))

## Polígono com gradiente vertical + alfa (para pilares/chamas).
func _grad(pts: PackedVector2Array, light: Color, dark: Color, alpha: float) -> void:
	if pts.size() < 3:
		return
	var min_y := INF
	var max_y := -INF
	for p in pts:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var cols := PackedColorArray()
	cols.resize(pts.size())
	for i in pts.size():
		var k := clampf((pts[i].y - min_y) / maxf(0.001, max_y - min_y), 0.0, 1.0)
		var c := light.lerp(dark, k)
		cols[i] = Color(c.r, c.g, c.b, alpha)
	draw_polygon(pts, cols)

func _polyline_closed(pts: PackedVector2Array, col: Color, w: float) -> void:
	if pts.size() < 2:
		return
	var line := PackedVector2Array(pts)
	line.append(pts[0])
	draw_polyline(line, col, w, true)

func draw_ellipse_poly(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var n := 16 if _q() >= 1 else 20
	var pts := PackedVector2Array()
	pts.resize(n)
	for i in n:
		var a := TAU * float(i) / float(n)
		pts[i] = c + Vector2(cos(a) * rx, sin(a) * ry)
	draw_colored_polygon(pts, col)

func draw_polyline_closed(pts: PackedVector2Array, col: Color, w: float) -> void:
	_polyline_closed(pts, col, w)

# ----------------------------------------------------------------------
#  Efeitos genéricos (legado / utilidades)
# ----------------------------------------------------------------------
func _draw_slash(t: float, inv: float) -> void:
	var r := 32.0 * fx_scale * (0.55 + inv * 0.75)
	var a0 := angle - 0.7
	var a1 := a0 + lerpf(0.7, 2.4, inv)
	draw_arc(Vector2.ZERO, r, a0, a1, _segs(18), Color(1, 0.86, 0.3, 0.9 * t), 5.0)
	draw_arc(Vector2.ZERO, r, a0 + 0.2, a1 - 0.1, _segs(14), Color(1, 1, 1, 0.8 * t), 2.0)
	_core(t, inv, Color(1, 0.95, 0.6), 9.0)

func _draw_magic_burst(t: float, inv: float) -> void:
	var r := 44.0 * fx_scale * inv
	if r > 1.0:
		draw_arc(Vector2.ZERO, r, 0, TAU, _segs(28), Color(0.31, 0.86, 1, 0.85 * t), 3.0)
	draw_arc(Vector2.ZERO, r * 0.6 + 4.0, 0, TAU, _segs(20), Color(0.71, 0.94, 1, 0.7 * t), 1.5)
	_core(t, inv, Color(1, 1, 1), 11.0)
	for i in 6:
		var a := i * PI / 3.0 + inv * 2.0
		draw_circle(Vector2(cos(a) * (r + 6.0), sin(a) * (r + 6.0)) * 1.0,
			2.4 * t, Color(0.39, 0.9, 1, 0.9 * t))

func _draw_heal(t: float, inv: float) -> void:
	_draw_heal_body(t, inv, Color(0.31, 1, 0.47), Color(0.75, 1, 0.8), false)

func _draw_crit(t: float, inv: float) -> void:
	var r := 52.0 * fx_scale * (0.3 + inv * 0.9)
	var alpha := t
	var pts := PackedVector2Array()
	pts.resize(16)
	for i in 16:
		var a := i * PI / 8.0 - PI / 2.0 + inv * 0.6
		var rr := r if i % 2 == 0 else r * 0.45
		pts[i] = Vector2(cos(a) * rr, sin(a) * rr)
	_grad(pts, Color(1, 0.95, 0.6), Color(1, 0.5, 0.08), alpha * 0.95)
	_polyline_closed(pts, Color(0.6, 0.12, 0.02, 0.8 * alpha), 2.0)
	_core(t, inv, Color(1, 1, 1), 15.0)
	if _q() < 2 and t > 0.45:
		var font := ThemeDB.fallback_font
		var txt := "CRÍTICO!"
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var yy := -r - 8.0 - inv * 6.0
		draw_string(font, Vector2(-tw / 2 + 1, yy + 1), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0, 0, 0, 0.7 * alpha))
		draw_string(font, Vector2(-tw / 2, yy), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.31, 0.16, alpha))

func _draw_enemy_hit(t: float, inv: float) -> void:
	var r := (14.0 + inv * 14.0) * fx_scale
	draw_circle(Vector2.ZERO, r, Color(1, 0.24, 0.24, 0.55 * t))
	draw_circle(Vector2.ZERO, r * 0.55, Color(1, 0.72, 0.6, 0.75 * t))
	var l := r * 0.9
	draw_line(Vector2(-l, -l), Vector2(l, l), Color(1, 1, 1, 0.9 * t), 2.5)
	draw_line(Vector2(-l, l), Vector2(l, -l), Color(1, 1, 1, 0.9 * t), 2.5)
	_rays(t, inv, Color(1, 0.5, 0.4), 5, r, r + 18.0, 0.4)

# ----------------------------------------------------------------------
#  Cura tingida pelo campeão
# ----------------------------------------------------------------------
func _draw_role_heal(fam: int, t: float, inv: float) -> void:
	var p := pal_of(fam)
	var acc: Color = p[3]
	var lite: Color = p[2]
	var main := Color(0.31, 1.0, 0.47).lerp(lite, 0.35)
	_draw_heal_body(t, inv, main, acc, true)
	if _q() < 2:
		# toque da família em volta da cura
		draw_arc(Vector2.ZERO, (26.0 + inv * 20.0) * fx_scale, 0.2, 3.4, _segs(16),
			Color(acc, 0.55 * t), 2.5)

## Cruz de cura com gradiente + motes subindo.
func _draw_heal_body(t: float, inv: float, main: Color, accent: Color, fancy: bool) -> void:
	var alpha := t
	var s := 15.0 * fx_scale
	var y := -inv * 30.0 * fx_scale
	var w := 5.0 * fx_scale
	var vert := PackedVector2Array([
		Vector2(-w, y - s), Vector2(w, y - s), Vector2(w, y + s), Vector2(-w, y + s)])
	var hor := PackedVector2Array([
		Vector2(-s, y - w), Vector2(s, y - w), Vector2(s, y + w), Vector2(-s, y + w)])
	_grad(vert, Color(1, 1, 1, alpha), main, alpha)
	_grad(hor, Color(1, 1, 1, alpha), main, alpha)
	_polyline_closed(vert, Color(0.02, 0.04, 0.14, 0.4 * alpha), 1.0)
	_polyline_closed(hor, Color(0.02, 0.04, 0.14, 0.4 * alpha), 1.0)
	_ring(t, inv, accent, 14.0, 46.0, 2.0)
	if fancy and _q() < 2:
		var n := 6 if _q() == 0 else 4
		for i in n:
			var px := sin(i * 2.1) * 22.0 * fx_scale
			var ph := fmod(inv * 1.4 + float(i) * 0.3, 1.0)
			var py := 10.0 - ph * 46.0 * fx_scale
			draw_circle(Vector2(px, py), maxf(1.0, 3.0 * (1.0 - ph)),
				Color(accent, (1.0 - ph) * 0.85 * alpha))
	if _q() < 2:
		var font := ThemeDB.fallback_font
		var tw := font.get_string_size("+", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(font, Vector2(-tw / 2, y - s - 8.0), "+",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.75, 1, 0.8, alpha * 0.85))

# ======================================================================
#  EFEITOS POR CAMPEÃO
# ======================================================================
func _draw_role(fam: int, slot: int, t: float, inv: float) -> void:
	var p := pal_of(fam)
	_streak(t, p[0], p[2])
	match fam:
		0: _fx_tank(slot, t, inv, p)
		1: _fx_shin(slot, t, inv, p)
		2: _fx_mage(slot, t, inv, p)
		3: _fx_marks(slot, t, inv, p)
		_: _fx_support(slot, t, inv, p)

# ---------------------------------------------------------------- Garen
func _fx_tank(slot: int, t: float, inv: float, p: Array) -> void:
	var c0: Color = p[0]
	var c1: Color = p[1]
	var c2: Color = p[2]
	var c3: Color = p[3]
	match slot:
		0: # escudo: dois crescentes que fecham no impacto
			var r := 34.0 * fx_scale
			for k in 2:
				var base := angle + (PI * 0.5 if k == 0 else -PI * 0.5)
				var a0 := base - 1.0 + inv * 0.35
				var a1 := base + 1.0
				draw_arc(Vector2.ZERO, r, a0, a1, _segs(16), Color(c1, 0.85 * t), 7.0)
				draw_arc(Vector2.ZERO, r, a0 + 0.1, a1 - 0.1, _segs(14), Color(c0, 0.95 * t), 4.5)
				draw_arc(Vector2.ZERO, r - 5.0, a0 + 0.3, a1 - 0.2, _segs(10), Color(c2, 0.7 * t), 1.6)
			_core(t, inv, c2, 10.0)
			_ring(t, inv, c3, 16.0, 48.0, 2.5)
		1: # golpe de espada: arco largo com fio brilhante
			var r := 42.0 * fx_scale
			var a0 := angle - 1.2
			var a1 := a0 + lerpf(0.7, 2.4, inv)
			draw_arc(Vector2.ZERO, r, a0, a1, _segs(20), Color(c1, 0.9 * t), 11.0)
			draw_arc(Vector2.ZERO, r, a0, a1, _segs(20), Color(c0, 0.95 * t), 7.0)
			draw_arc(Vector2.ZERO, r, a0 + 0.1, a1 - 0.35, _segs(16), Color(c2, 0.95 * t), 2.0)
			var tip := Vector2(cos(a1), sin(a1)) * r
			draw_circle(tip, maxf(1.5, 5.0 * t), Color(c2, 0.95 * t))
			_sparks(t, inv, c3, 5, a0)
			_core(t, inv, c0, 8.0)
		2: # escudo batendo: disco com rebites
			var r := (16.0 + inv * 30.0) * fx_scale
			draw_circle(Vector2.ZERO, r, Color(c1, 0.6 * t))
			draw_arc(Vector2.ZERO, r, 0, TAU, _segs(22), Color(c0, 0.95 * t), 4.5)
			draw_arc(Vector2.ZERO, r * 0.58, 0, TAU, _segs(16), Color(c2, 0.8 * t), 2.0)
			for i in 4:
				var a := TAU * i / 4.0 + 0.785 + inv * 1.4
				draw_circle(Vector2(cos(a), sin(a)) * r * 0.8, 3.2 * t, Color(c2, 0.9 * t))
			_core(t, inv, c2, 7.0)
			_ring(t, inv, c3, 12.0, 56.0, 3.0)
		3: # impacto sísmico: rachaduras + poeira
			_pool(t, inv, c0, 1.35)
			for i in 6:
				var a := TAU * i / 6.0 + angle
				var dir := Vector2(cos(a), sin(a) * 0.55)
				var r1 := lerpf(14.0, 58.0, inv) * fx_scale
				var mid := dir * r1 * 0.5 + dir.orthogonal() * 7.0 * fx_scale
				draw_polyline(PackedVector2Array([Vector2.ZERO, mid, dir * r1]),
					Color(c1, 0.9 * t), 3.5, true)
				draw_polyline(PackedVector2Array([Vector2.ZERO, mid, dir * r1]),
					Color(c2, 0.5 * t), 1.2, true)
			_ring(t, inv, c0, 14.0, 58.0, 3.5)
			_sparks(t, inv, c2, 6, 0.0)
		4: # cólera do colosso: impacto contundido
			var r := (26.0 - inv * 16.0) * fx_scale
			draw_circle(Vector2.ZERO, r, Color(c1, 0.75 * t))
			draw_circle(Vector2.ZERO, r * 0.68, Color(c0, 0.9 * t))
			draw_circle(Vector2.ZERO, r * 0.3, Color(c2, 0.9 * t))
			_rays(t, inv, c2, 8, r + 3.0, r + 34.0, inv * 0.7)
			_ring(t, inv, c0, 18.0, 66.0, 3.5)
			_ring(t, inv, c3, 10.0, 44.0, 2.0)
			_pool(t, inv, c0, 1.15)
		_: # julgamento: pilar de luz + halo
			var h := 76.0 * fx_scale
			var wt := (14.0 + inv * 18.0) * fx_scale
			var wb := (5.0 + inv * 6.0) * fx_scale
			_grad(PackedVector2Array([
				Vector2(-wb, h * 0.55), Vector2(wb, h * 0.55),
				Vector2(wt, -h), Vector2(-wt, -h)]), c2, c0, 0.85 * t)
			_grad(PackedVector2Array([
				Vector2(-wb * 0.5, h * 0.55), Vector2(wb * 0.5, h * 0.55),
				Vector2(wt * 0.4, -h), Vector2(-wt * 0.4, -h)]), Color(1, 1, 1, 1), c2, 0.7 * t)
			var halo_y := -h * 0.75
			draw_arc(Vector2(0, halo_y), (16.0 + inv * 14.0) * fx_scale, 0, TAU,
				_segs(20), Color(c2, 0.8 * t), 3.0)
			_rays(t, inv, c2, 10, 20.0, 70.0, inv * 0.8)
			_ring(t, inv, c0, 22.0, 74.0, 4.0)
			_pool(t, inv, c0, 1.5)
			_sparks(t, inv, c2, 8, 0.3)

# ---------------------------------------------------------------- Zed
func _fx_shin(slot: int, t: float, inv: float, p: Array) -> void:
	var c0: Color = p[0]
	var c1: Color = p[1]
	var c2: Color = p[2]
	var c3: Color = p[3]
	match slot:
		0: # corte em X
			for k in 2:
				var a := angle + (PI * 0.25 if k == 0 else -PI * 0.25)
				var l := (24.0 + inv * 24.0) * fx_scale
				var d := Vector2(cos(a), sin(a)) * l
				var o := d.orthogonal() * 4.0
				draw_line(-d - o, d - o, Color(c1, 0.8 * t), 7.0)
				draw_line(-d, d, Color(c0, 0.95 * t), 4.5)
				draw_line(-d * 0.8, d * 0.8, Color(c2, 0.9 * t), 1.6)
			draw_circle(Vector2.ZERO, maxf(2.0, 11.0 * t), Color(c3, 0.5 * t))
			_sparks(t, inv, c3, 5, 0.5)
		1: # corte relâmpago: crescente rápido
			var r := 44.0 * fx_scale
			var a0 := angle - 1.0
			var a1 := a0 + lerpf(0.5, 2.0, inv)
			for k in 3:
				draw_arc(Vector2.ZERO, r - k * 5.0, a0 + k * 0.15, a1, _segs(16),
					Color([c1, c0, c2][k], (0.5 + k * 0.2) * t), 6.0 - k * 1.5)
			_rays(t, inv, c3, 4, r * 0.4, r + 14.0, angle)
			_core(t, inv, c2, 8.0)
		2: # lâmina dupla + afterimage
			var r := 40.0 * fx_scale
			for k in 2:
				var sg := 1.0 if k == 0 else -1.0
				var a0 := angle + sg * 0.3 - 1.0
				var a1 := a0 + lerpf(0.6, 2.1, inv)
				draw_arc(Vector2(sg * 8.0 * fx_scale, 0), r, a0, a1, _segs(16),
					Color(c0, 0.9 * t), 5.5)
				draw_arc(Vector2(sg * 8.0 * fx_scale, 0), r, a0 + 0.2, a1 - 0.15,
					_segs(12), Color(c2, 0.85 * t), 1.6)
			if _q() < 2:
				draw_ellipse_poly(Vector2(-inv * 18.0 * fx_scale, 0),
					16.0 * fx_scale, 22.0 * fx_scale, Color(c1, 0.4 * t))
			_core(t, inv, c3, 8.0)
		3: # dança das adagas: shurikens girando
			var n := 4 if _q() >= 1 else 5
			for i in n:
				var a := TAU * i / float(n) + inv * 3.0
				var rr := lerpf(10.0, 46.0, inv) * fx_scale
				var pos := Vector2(cos(a), sin(a) * 0.8) * rr
				var s := (9.0 - inv * 3.0) * fx_scale
				var pts := PackedVector2Array()
				pts.resize(8)
				for j in 8:
					var aa := TAU * j / 8.0 + a * 1.5
					var rad := s if j % 2 == 0 else s * 0.34
					pts[j] = pos + Vector2(cos(aa), sin(aa)) * rad
				draw_colored_polygon(pts, Color(c0, 0.9 * t))
				draw_line(pos - Vector2(cos(a), sin(a)) * s, pos + Vector2(cos(a), sin(a)) * s,
					Color(c2, 0.8 * t), 1.4)
			_ring(t, inv, c3, 14.0, 52.0, 2.0)
		4: # marca da morte: selo com cruz
			var r := (20.0 + inv * 26.0) * fx_scale
			draw_circle(Vector2.ZERO, r, Color(c1, 0.5 * t))
			draw_arc(Vector2.ZERO, r, 0, TAU, _segs(24), Color(c0, 0.95 * t), 4.0)
			draw_arc(Vector2.ZERO, r * 0.7, 0, TAU, _segs(18), Color(c3, 0.8 * t), 2.0)
			for i in 4:
				var a := TAU * i / 4.0 + 0.785 + inv * 1.2
				var d := Vector2(cos(a), sin(a))
				draw_line(d * r * 0.9, d * (r + 13.0 * fx_scale), Color(c2, 0.9 * t), 3.0)
			var l := r * 0.55
			draw_line(Vector2(-l, -l), Vector2(l, l), Color(c2, 0.95 * t), 4.0)
			draw_line(Vector2(-l, l), Vector2(l, -l), Color(c2, 0.95 * t), 4.0)
			_core(t, inv, c3, 9.0)
		_: # eclipse sombrio
			var r := (24.0 + inv * 24.0) * fx_scale
			draw_circle(Vector2.ZERO, r, Color(0.03, 0.01, 0.06, 0.9 * t))
			draw_arc(Vector2.ZERO, r, 0, TAU, _segs(26), Color(c0, 0.95 * t), 3.5)
			draw_arc(Vector2.ZERO, r + 5.0 * fx_scale, -1.2 + inv, 1.2 + inv,
				_segs(14), Color(c3, 0.8 * t), 5.0)
			for k in 3:
				var a := angle + (k - 1) * 0.7 + inv * 0.9
				var l := (30.0 + inv * 16.0) * fx_scale
				var d := Vector2(cos(a), sin(a)) * l
				draw_line(-d, d, Color(c0, (0.8 - k * 0.18) * t), 3.5)
				draw_line(-d * 0.7, d * 0.7, Color(c2, (0.7 - k * 0.18) * t), 1.3)
			_rays(t, inv, c3, 8, r, r + 30.0, inv * 0.5)

# ---------------------------------------------------------------- Ahri
func _fx_mage(slot: int, t: float, inv: float, p: Array) -> void:
	var c0: Color = p[0]
	var c1: Color = p[1]
	var c2: Color = p[2]
	var c3: Color = p[3]
	match slot:
		0: # orbe arcano
			var r := (14.0 + inv * 18.0) * fx_scale
			draw_circle(Vector2.ZERO, r * 1.7, Color(c3, 0.16 * t))
			draw_circle(Vector2.ZERO, r * 1.3, Color(c0, 0.25 * t))
			draw_circle(Vector2.ZERO, r, Color(c1, 0.75 * t))
			draw_circle(Vector2.ZERO, r * 0.62, Color(c0, 0.95 * t))
			draw_circle(Vector2.ZERO, r * 0.3, Color(c2, 0.95 * t))
			draw_arc(Vector2.ZERO, r * 1.55, inv * 3.0, inv * 3.0 + 2.4, _segs(14),
				Color(c2, 0.85 * t), 2.5)
			_sparks(t, inv, c3, 5, inv * 2.0)
		1: # espiral rúnica
			var pts := PackedVector2Array()
			var turns := 12 if _q() >= 1 else 18
			for i in turns:
				var k := float(i) / float(turns)
				var a := k * TAU * 1.7 + inv * 3.0
				var rr := (6.0 + k * 40.0 * inv + 4.0) * fx_scale
				pts.append(Vector2(cos(a), sin(a)) * rr)
			draw_polyline(pts, Color(c0, 0.9 * t), 3.5, true)
			if _q() == 0:
				draw_polyline(pts, Color(c2, 0.7 * t), 1.3, true)
			var tri := PackedVector2Array()
			for i in 3:
				var a := -PI * 0.5 - inv * 2.0 + TAU * i / 3.0
				tri.append(Vector2(cos(a), sin(a)) * 30.0 * fx_scale)
			_polyline_closed(tri, Color(c3, 0.85 * t), 2.5)
			_core(t, inv, c2, 9.0)
		2: # fogo de raposa: chamas crescentes
			for k in 3:
				var a := angle + (k - 1) * 0.65
				var rr := (24.0 + k * 7.0) * fx_scale
				var off := Vector2(cos(a + PI * 0.5), sin(a + PI * 0.5)) * (k - 1) * 12.0 * fx_scale
				draw_arc(off, rr, a - 1.3, a + 0.5, _segs(14), Color(c1, 0.7 * t), 8.0)
				draw_arc(off, rr, a - 1.1, a + 0.3, _segs(12), Color(c0, 0.9 * t), 5.0)
				draw_arc(off, rr * 0.7, a - 0.9, a + 0.1, _segs(10), Color(c2, 0.85 * t), 2.0)
			_ring(t, inv, c3, 14.0, 48.0, 2.0)
			_sparks(t, inv, c2, 5, 0.7)
		3: # explosão rúnica: dois triângulos contrarrotativos
			for k in 2:
				var tri := PackedVector2Array()
				for i in 3:
					var a := -PI * 0.5 + TAU * i / 3.0 + (inv * 2.2 if k == 0 else -inv * 2.2)
					tri.append(Vector2(cos(a), sin(a)) * (24.0 + inv * 14.0) * fx_scale * (1.0 if k == 0 else 0.72))
				_polyline_closed(tri, Color(c0 if k == 0 else c3, 0.9 * t), 3.0)
			draw_arc(Vector2.ZERO, (18.0 + inv * 34.0) * fx_scale, 0, TAU, _segs(26),
				Color(c2, 0.75 * t), 3.0)
			_core(t, inv, c2, 11.0)
			_sparks(t, inv, c0, 6, inv * 1.5)
		4: # tempestade arcana: raio + nuvem
			var bolt := PackedVector2Array([
				Vector2(6.0, -46.0) * fx_scale, Vector2(-14.0, -4.0) * fx_scale,
				Vector2(-2.0, -4.0) * fx_scale, Vector2(-10.0, 42.0) * fx_scale,
				Vector2(16.0, -2.0) * fx_scale, Vector2(3.0, -2.0) * fx_scale])
			_grad(bolt, c2, c0, 0.95 * t)
			_polyline_closed(bolt, Color(c3, 0.8 * t), 2.0)
			for k in 2:
				draw_arc(Vector2((k - 0.5) * 26.0 * fx_scale, -34.0 * fx_scale),
					18.0 * fx_scale, 0.3, 2.9, _segs(14), Color(c1, 0.6 * t), 4.0)
			_ring(t, inv, c3, 16.0, 54.0, 2.5)
			_sparks(t, inv, c2, 6, 0.2)
		_: # supernova
			var r := (26.0 + inv * 34.0) * fx_scale
			var pts := PackedVector2Array()
			pts.resize(16)
			for i in 16:
				var a := i * PI / 8.0 + inv * 0.8
				var rr := r if i % 2 == 0 else r * 0.42
				pts[i] = Vector2(cos(a), sin(a)) * rr
			_grad(pts, Color(1, 1, 1, 1), c0, 0.9 * t)
			_polyline_closed(pts, Color(c3, 0.8 * t), 2.0)
			_rays(t, inv, c2, 12, r * 0.5, r + 30.0, inv * 0.6)
			_ring(t, inv, c0, 20.0, 76.0, 3.5)
			_ring(t, inv, c3, 12.0, 52.0, 2.0)
			_core(t, inv, Color(1, 1, 1), 14.0)

# ---------------------------------------------------------------- Ashe
func _fx_marks(slot: int, t: float, inv: float, p: Array) -> void:
	var c0: Color = p[0]
	var c1: Color = p[1]
	var c2: Color = p[2]
	var c3: Color = p[3]
	match slot:
		0: # impacto de flecha
			var dir := Vector2(cos(angle), sin(angle))
			var l := (26.0 + inv * 14.0) * fx_scale
			var tip := dir * l
			var side := dir.orthogonal() * 7.0 * fx_scale
			draw_colored_polygon(PackedVector2Array([
				tip, tip - dir * 16.0 * fx_scale + side, tip - dir * 16.0 * fx_scale - side]),
				Color(c2, 0.95 * t))
			draw_line(tip - dir * 14.0 * fx_scale, tip - dir * 54.0 * fx_scale,
				Color(c0, 0.85 * t), 3.5)
			for i in 6:
				var a := angle + PI + (i - 2.5) * 0.45
				var rr := lerpf(10.0, 44.0, inv) * fx_scale
				var e := Vector2(cos(a), sin(a)) * rr
				draw_line(e * 0.35, e, Color(c3, 0.85 * t), 2.5)
				draw_circle(e, 2.4 * t, Color(c2, 0.9 * t))
			_ring(t, inv, c0, 14.0, 48.0, 2.5)
		1: # flecha de gelo: projétil com rastro
			var dir := Vector2(cos(angle), sin(angle))
			var back := -dir * lerpf(52.0, 8.0, inv) * fx_scale
			var head := dir * (14.0 + inv * 20.0) * fx_scale
			draw_line(back, head, Color(c1, 0.6 * t), 6.0)
			draw_line(back, head, Color(c0, 0.95 * t), 3.0)
			var side := dir.orthogonal() * 7.0 * fx_scale
			draw_colored_polygon(PackedVector2Array([
				head + dir * 9.0 * fx_scale, head - dir * 6.0 * fx_scale + side,
				head - dir * 6.0 * fx_scale - side]), Color(c2, 0.95 * t))
			for i in 2:
				var f := back + dir * (10.0 + i * 12.0) * fx_scale
				var o := dir.orthogonal() * 6.0 * fx_scale
				draw_line(f, f - dir * 8.0 * fx_scale + o, Color(c0, 0.8 * t), 2.0)
				draw_line(f, f - dir * 8.0 * fx_scale - o, Color(c0, 0.8 * t), 2.0)
			_sparks(t, inv, c3, 4, angle)
		2: # chuva de flechas
			var n := 5 if _q() >= 1 else 7
			for i in n:
				var x := (i - (n - 1) * 0.5) * 15.0 * fx_scale
				var y0 := (-52.0 + inv * 44.0 + float(i) * 4.0) * fx_scale
				var y1 := y0 + 28.0 * fx_scale
				draw_line(Vector2(x, y0), Vector2(x, y1), Color(c0, 0.9 * t), 3.0)
				draw_colored_polygon(PackedVector2Array([
					Vector2(x, y1 + 7.0 * fx_scale), Vector2(x - 5.0, y1),
					Vector2(x + 5.0, y1)]), Color(c2, 0.95 * t))
				if y1 > -4.0:
					draw_circle(Vector2(x, y1 + 3.0), 3.5 * t, Color(c3, 0.7 * t))
			_pool(t, inv, c0, 1.1)
			_ring(t, inv, c3, 12.0, 44.0, 2.0)
		3: # tiro perfurante: linha que atravessa
			var dir := Vector2(cos(angle), sin(angle))
			var side := dir.orthogonal()
			var l := (60.0 + inv * 34.0) * fx_scale
			draw_line(-dir * l, dir * l, Color(c1, 0.55 * t), 10.0)
			draw_line(-dir * l, dir * l, Color(c0, 0.95 * t), 5.0)
			draw_line(-dir * l * 0.8, dir * l * 0.8, Color(c2, 0.95 * t), 1.8)
			for k in 2:
				var off := (1.0 if k == 0 else -1.0) * (10.0 + inv * 26.0) * fx_scale
				var c := side * off
				draw_arc(c, 9.0 * fx_scale, 0, TAU, _segs(14), Color(c3, 0.8 * t), 2.5)
			_core(t, inv, c2, 9.0)
			_sparks(t, inv, c3, 5, angle)
		4: # saraivada mortal: cristais caindo
			var n := 6 if _q() >= 1 else 9
			for i in n:
				var x := (i - (n - 1) * 0.5) * 14.0 * fx_scale
				var y := (-46.0 + inv * 46.0 + float(i % 3) * 7.0) * fx_scale
				var s := (7.0 + float(i % 3) * 2.0) * fx_scale
				draw_colored_polygon(PackedVector2Array([
					Vector2(x, y + s * 2.0), Vector2(x - s * 0.6, y), Vector2(x + s * 0.6, y)]),
					Color(c0, 0.9 * t))
				draw_line(Vector2(x, y + s * 1.6), Vector2(x, y), Color(c2, 0.8 * t), 1.4)
			_pool(t, inv, c0, 1.2)
			_ring(t, inv, c3, 14.0, 52.0, 2.5)
			_sparks(t, inv, c2, 5, 0.4)
		_: # flecha do fim: cometa
			var dir := Vector2(cos(angle), sin(angle))
			var head := dir * (20.0 + inv * 34.0) * fx_scale
			var back := -dir * lerpf(76.0, 22.0, inv) * fx_scale
			draw_line(back, head, Color(c1, 0.5 * t), 16.0)
			draw_line(back, head, Color(c0, 0.8 * t), 9.0)
			draw_line(back, head, Color(c2, 0.95 * t), 3.5)
			var side := dir.orthogonal() * 12.0 * fx_scale
			draw_colored_polygon(PackedVector2Array([
				head + dir * 18.0 * fx_scale, head - dir * 12.0 * fx_scale + side,
				head - dir * 12.0 * fx_scale - side]), Color(c2, 0.98 * t))
			_ring(t, inv, c0, 24.0, 74.0, 4.0)
			_ring(t, inv, c3, 14.0, 52.0, 2.0)
			_rays(t, inv, c3, 8, 20.0, 60.0, angle)
			_pool(t, inv, c0, 1.3)
			_sparks(t, inv, c2, 8, angle)

# --------------------------------------------------------------- Janna
func _fx_support(slot: int, t: float, inv: float, p: Array) -> void:
	var c0: Color = p[0]
	var c1: Color = p[1]
	var c2: Color = p[2]
	var c3: Color = p[3]
	match slot:
		0: # golpe de vento
			for k in 2:
				var rr := (22.0 + k * 13.0 + inv * 22.0) * fx_scale
				draw_arc(Vector2.ZERO, rr, angle - 1.1 + inv * 0.6 + k * 0.4,
					angle + 1.1 + inv * 0.6 + k * 0.4, _segs(18),
					Color(c0 if k == 0 else c3, (0.9 - k * 0.3) * t), 5.0 - k)
				draw_arc(Vector2.ZERO, rr, angle - 0.7 + inv * 0.6 + k * 0.4,
					angle + 0.7 + inv * 0.6 + k * 0.4, _segs(12), Color(c2, 0.6 * t), 1.5)
			for i in 3:
				var a := angle + (i - 1) * 0.7 + inv * 1.4
				var rr := lerpf(14.0, 48.0, inv) * fx_scale
				draw_circle(Vector2(cos(a), sin(a) * 0.7) * rr, 3.0 * t, Color(c2, 0.85 * t))
			_core(t, inv, c2, 7.0)
		1: # rajada: três linhas onduladas
			for k in 3:
				var y := (k - 1) * 16.0 * fx_scale
				var l := (26.0 + inv * 28.0) * fx_scale
				var pts := PackedVector2Array()
				var n := 6 if _q() >= 1 else 10
				for i in n + 1:
					var kk := float(i) / float(n)
					pts.append(Vector2(-l + kk * 2.0 * l,
						y + sin(kk * TAU * 1.2 + inv * 5.0 + k) * 7.0 * fx_scale))
				draw_polyline(pts, Color(c0, (0.95 - k * 0.2) * t), 3.5, true)
				if _q() == 0:
					draw_polyline(pts, Color(c2, 0.5 * t), 1.2, true)
			_ring(t, inv, c3, 14.0, 46.0, 2.0)
		2: # lâmina de vento + folhas
			var r := 42.0 * fx_scale
			var a0 := angle - 1.2
			var a1 := a0 + lerpf(0.7, 2.4, inv)
			draw_arc(Vector2.ZERO, r, a0, a1, _segs(20), Color(c1, 0.7 * t), 9.0)
			draw_arc(Vector2.ZERO, r, a0, a1, _segs(20), Color(c0, 0.95 * t), 5.5)
			draw_arc(Vector2.ZERO, r, a0 + 0.15, a1 - 0.3, _segs(14), Color(c2, 0.9 * t), 1.8)
			for i in 3:
				var a := a0 + 0.3 + float(i) * 0.55
				var pos := Vector2(cos(a), sin(a)) * (r + 9.0 * fx_scale)
				_leaf(pos, 6.0 * fx_scale, a, t, c3)
			_sparks(t, inv, c2, 5, a0)
		3: # olho da tempestade
			var r := (20.0 + inv * 24.0) * fx_scale
			draw_circle(Vector2.ZERO, r, Color(c1, 0.55 * t))
			draw_arc(Vector2.ZERO, r, 0, TAU, _segs(24), Color(c0, 0.95 * t), 4.0)
			_grad(ArtUtil.ellipse_pts(0, 0, r * 0.55, r * 0.38, 14), c2, c3, 0.95 * t)
			draw_circle(Vector2.ZERO, r * 0.2, Color(0.05, 0.1, 0.15, 0.9 * t))
			draw_circle(Vector2(-r * 0.07, -r * 0.07), r * 0.07, Color(1, 1, 1, 0.9 * t))
			for i in 5:
				var a := TAU * i / 5.0 + inv * 2.4
				draw_line(Vector2(cos(a), sin(a)) * r * 1.05,
					Vector2(cos(a), sin(a)) * (r + 14.0 * fx_scale), Color(c2, 0.8 * t), 2.5)
			_ring(t, inv, c3, 12.0, 54.0, 2.5)
		4: # monsoon: redemoinho grande
			for k in 3:
				var rr := (14.0 + k * 13.0 + inv * 30.0) * fx_scale
				draw_arc(Vector2.ZERO, rr, inv * 3.5 + k * 1.1, inv * 3.5 + k * 1.1 + 3.4,
					_segs(18), Color(c0 if k != 1 else c3, (0.9 - k * 0.2) * t), 5.0 - k)
			for i in 6:
				var a := TAU * i / 6.0 + inv * 2.0
				var rr := (20.0 + inv * 34.0) * fx_scale
				_leaf(Vector2(cos(a), sin(a) * 0.75) * rr, 5.5 * fx_scale, a, t, c2)
			_core(t, inv, c2, 9.0)
			_pool(t, inv, c0, 1.1)
		_: # renascença da tormenta
			var r := (26.0 + inv * 32.0) * fx_scale
			for k in 3:
				var a := -PI * 0.5 + k * 2.1 + inv * 2.6
				var rr := r * (0.6 + k * 0.2)
				draw_arc(Vector2.ZERO, rr, a, a + 2.4, _segs(16),
					Color([c0, c3, c2][k], 0.9 * t), 5.0 - k * 0.8)
			draw_arc(Vector2.ZERO, r * 1.15, 0, TAU, _segs(26), Color(c2, 0.7 * t), 3.0)
			_rays(t, inv, c2, 9, r * 0.4, r + 26.0, inv * 0.7)
			_core(t, inv, Color(1, 1, 1), 12.0)
			_sparks(t, inv, c3, 7, 0.6)

func _leaf(pos: Vector2, s: float, a: float, t: float, col: Color) -> void:
	var d := Vector2(cos(a), sin(a))
	var o := d.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		pos + d * s, pos + o * s * 0.6, pos - d * s * 0.4, pos - o * s * 0.6]),
		Color(col, 0.9 * t))

# ======================================================================
#  Canalização (aura persistente)
# ======================================================================
func _draw_channel_aura() -> void:
	var pulse := sin(Time.get_ticks_msec() * 0.008) * 0.5 + 0.5
	var r := 35.0 + pulse * 12.0
	draw_circle(Vector2.ZERO, r, Color(0.24, 0.47, 1, 0.16 + pulse * 0.12))
	draw_arc(Vector2.ZERO, r - 6.0, 0, TAU, _segs(32), Color(0.31, 0.63, 1, 0.4), 2.0)
	var r2 := 18.0 + pulse * 8.0
	draw_arc(Vector2.ZERO, r2, 0, TAU, _segs(28), Color(0.59, 0.78, 1, 0.6), 2.0)
	var now := Time.get_ticks_msec()
	var n := 8 if _q() == 0 else 5
	for i in n:
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
