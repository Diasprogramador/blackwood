class_name SkillIcon
extends Object

## Ícones procedurais das skills + mapeamento de efeitos por personagem.
## Tudo é desenhado por código (sem PNG): cada (role, slot) tem um glifo
## próprio com gradiente, chanfro e brilho, usado na barra do HUD, nos
## botões de toque e como moldura dos slots.
##
## Performance: os brilhos/chanfros são pulados na qualidade Baixa
## (GameSettings.quality_cache >= 2) e o desenho usa no máximo ~3 polígonos
## simples por detalhe — nada de texturas nem de nós extras.

# ----------------------------------------------------------------------
#  Dados (texto/UI)
# ----------------------------------------------------------------------
static func role_color(role: String) -> Color:
	for c in ChampData.CHAMPS:
		if str(c.get("role", "")) == role:
			var col: Color = c.get("color", Color.WHITE)
			return col
	return Color.WHITE

## Símbolo unicode da skill (loja, mensagens).
static func glyph(role: String, kind: String, slot: int) -> String:
	if kind == "heal":
		match slot:
			0: return "💚"
			2: return "💖"
			3: return "👁"
			4: return "🔥"
			_: return "✚"
	match role:
		"tank":
			return ["⚔", "🛡", "💥", "🔨", "⚖"][clampi(slot, 0, 4)]
		"assassin":
			return ["🗡", "🔪", "🌀", "☠", "🌑"][clampi(slot, 0, 4)]
		"mage":
			return ["🔮", "🌙", "◈", "⚡", "🌟"][clampi(slot, 0, 4)]
		"marksman":
			return ["🏹", "🌧", "🎯", "💀", "☄"][clampi(slot, 0, 4)]
		"support":
			return ["🍃", "🌪", "💖", "👁", "🔥"][clampi(slot, 0, 4)]
	return "✦"

static func basic_glyph(role: String) -> String:
	match role:
		"tank": return "👊"
		"assassin": return "🗡"
		"mage": return "✦"
		"marksman": return "🏹"
		"support": return "🍃"
	return "👊"

# ----------------------------------------------------------------------
#  Mapeamento de efeitos (usado pelo main.gd)
# ----------------------------------------------------------------------
## Skill do campeão → golpe próprio do campeão (slot 1..5).
static func effect_for(role: String, kind: String, slot: int) -> int:
	if kind == "heal":
		return heal_effect_for(role)
	return AttackEffect.role_fx(role, clampi(slot, 0, 4) + 1)

## Ataque básico do campeão (slot 0).
static func basic_effect_for(role: String) -> int:
	return AttackEffect.role_fx(role, 0)

## Cura do campeão, tingida com a paleta dele.
static func heal_effect_for(role: String) -> int:
	return AttackEffect.role_heal(role)

# ----------------------------------------------------------------------
#  Molduras de slot (HUD / toque)
# ----------------------------------------------------------------------
## Placa retangular do slot: gradiente, chanfro, borda na cor da raridade.
static func draw_slot_bg(node: CanvasItem, x: float, y: float, w: float, h: float,
		rarity: Color, ready: bool, accent: Color) -> void:
	var top := Color(0.20, 0.21, 0.25) if ready else Color(0.15, 0.14, 0.16)
	var bot := Color(0.07, 0.08, 0.10) if ready else Color(0.06, 0.05, 0.06)
	if ready:
		top = ArtUtil.mix(top, accent, 0.22)
		bot = ArtUtil.mix(bot, accent, 0.10)
	ArtUtil.shade_poly(node, ArtUtil.rrect_pts(x, y, w, h, 7.0), top, bot)
	# brilho interno no topo
	if GameSettings.quality_cache < 2:
		ArtUtil.stroke_rrect(node, x + 1.5, y + 1.5, w - 3.0, h * 0.45, 5.0,
			Color(1, 1, 1, 0.10 if ready else 0.05), 1.2)
	var bcol := rarity if ready else Color(0.42, 0.42, 0.46)
	var bw := 2.0 if ready else 1.4
	if ready and GameSettings.quality_cache < 2:
		ArtUtil.stroke_rrect(node, x - 1.0, y - 1.0, w + 2.0, h + 2.0, 8.0,
			Color(bcol.r, bcol.g, bcol.b, 0.35), 4.0)
	ArtUtil.stroke_rrect(node, x, y, w, h, 7.0, bcol, bw)

## Placa redonda dos botões de toque.
static func draw_round_bg(node: CanvasItem, c: Vector2, r: float, accent: Color,
		ready: bool, down: bool) -> void:
	var top := Color(0.22, 0.23, 0.27) if ready else Color(0.15, 0.14, 0.16)
	var bot := Color(0.06, 0.07, 0.09) if ready else Color(0.06, 0.05, 0.06)
	if ready:
		top = ArtUtil.mix(top, accent, 0.25)
	ArtUtil.shade_ellipse(node, c.x, c.y, r, r, top, bot)
	if ready and GameSettings.quality_cache < 2:
		ArtUtil.fill_ellipse(node, c.x, c.y, r * 1.14, r * 1.14, Color(accent, 0.22))
		ArtUtil.shade_ellipse(node, c.x, c.y, r * 1.0, r * 1.0, top, bot)
	var a := 0.85 if down else 0.55
	node.draw_arc(c, r - 1.0, 0, TAU, 24, Color(accent, a if ready else 0.3), 2.2)
	node.draw_arc(c, r - 1.0, -2.4, -0.7, 10, Color(1, 1, 1, 0.35 if ready else 0.12), 1.6)

# ----------------------------------------------------------------------
#  Desenho (HUD / toque)
# ======================================================================
## Desenha o ícone da skill centralizado em `c`, com raio ~`r`.
## `dim=true` pinta tudo cinza (sem mana / em cooldown).
static func draw_icon(node: CanvasItem, role: String, kind: String, slot: int,
		c: Vector2, r: float, dim: bool = false) -> void:
	var main: Color = role_color(role)
	var lite: Color = Color.WHITE
	if dim:
		main = Color(0.35, 0.35, 0.38)
		lite = Color(0.5, 0.5, 0.53)
	if kind == "heal":
		match slot:
			0, 1: _p_cross(node, c, r, Color(0.35, 1.0, 0.5) if not dim else main, lite)
			2: _p_heart(node, c, r, Color(1.0, 0.45, 0.6) if not dim else main, lite)
			3: _p_eye(node, c, r, Color(0.45, 0.85, 1.0) if not dim else main, lite)
			_: _p_rebirth(node, c, r, Color(1.0, 0.6, 0.25) if not dim else main, lite)
		return
	if not dim:
		_glow(node, c, r * 1.15, main)
	match role:
		"tank":
			match slot:
				0: _p_sword(node, c, r, main, lite)
				1: _p_shield(node, c, r, main, lite)
				2: _p_quake(node, c, r, main, lite)
				3: _p_mace(node, c, r, main, lite)
				_: _p_judgment(node, c, r, main, lite)
		"assassin":
			match slot:
				0: _p_dagger(node, c, r, main, lite)
				1: _p_blades(node, c, r, main, lite)
				2: _p_fan(node, c, r, main, lite)
				3: _p_mark(node, c, r, main, lite)
				_: _p_eclipse(node, c, r, main, lite)
		"mage":
			match slot:
				0: _p_orb(node, c, r, main, lite)
				1: _p_crescent(node, c, r, main, lite)
				2: _p_rune(node, c, r, main, lite)
				3: _p_storm(node, c, r, main, lite)
				_: _p_star(node, c, r, main, lite)
		"marksman":
			match slot:
				0: _p_arrow(node, c, r, main, lite)
				1: _p_rain(node, c, r, main, lite)
				2: _p_pierce(node, c, r, main, lite)
				3: _p_crosshair(node, c, r, main, lite)
				_: _p_comet(node, c, r, main, lite)
		"support":
			match slot:
				0: _p_cross(node, c, r, main, lite)
				1: _p_swirl(node, c, r, main, lite)
				2: _p_heart(node, c, r, main, lite)
				3: _p_eye(node, c, r, main, lite)
				_: _p_rebirth(node, c, r, main, lite)
		_:
			_p_sword(node, c, r, main, lite)

## Soco básico (slot ATK): punho/armadura na cor do personagem.
static func draw_basic(node: CanvasItem, role: String, c: Vector2, r: float,
		ready: bool = true) -> void:
	var main: Color = role_color(role)
	if not ready:
		main = Color(0.4, 0.4, 0.42)
	var dark := ArtUtil.mix(main, Color.BLACK, 0.55)
	var lite := ArtUtil.mix(main, Color.WHITE, 0.55)
	if ready:
		_glow(node, c, r * 1.1, main)
	# punho (parte de baixo)
	var fist := ArtUtil.rrect_pts(c.x - r * 0.62, c.y - r * 0.30, r * 1.24, r * 0.9, 5.0)
	ArtUtil.shade_poly(node, fist, lite, dark)
	ArtUtil.stroke(node, fist, Color(0, 0, 0, 0.5), 1.5)
	# dorso da mão (destaque)
	ArtUtil.shade_ellipse(node, c.x, c.y - r * 0.30, r * 0.62, r * 0.30,
		ArtUtil.mix(lite, Color.WHITE, 0.35), main)
	# dedos
	for i in 3:
		var kx := c.x - r * 0.36 + i * r * 0.36
		node.draw_line(Vector2(kx, c.y - r * 0.24), Vector2(kx, c.y + r * 0.14),
			Color(0, 0, 0, 0.45), 1.6)
		node.draw_line(Vector2(kx - 1, c.y - r * 0.24), Vector2(kx - 1, c.y + r * 0.10),
			Color(1, 1, 1, 0.25), 1.0)
	# pulseira
	var band := ArtUtil.rrect_pts(c.x - r * 0.7, c.y + r * 0.36, r * 1.4, r * 0.28, 3.0)
	ArtUtil.shade_poly(node, band, ArtUtil.mix(main, Color.WHITE, 0.25), dark)
	ArtUtil.stroke(node, band, Color(0, 0, 0, 0.5), 1.2)
	node.draw_line(Vector2(c.x - r * 0.7, c.y + r * 0.5), Vector2(c.x + r * 0.7, c.y + r * 0.5),
		Color(1, 1, 1, 0.5 if ready else 0.15), 1.4)

# ----------------------------------------------------------------------
#  Utilitários de desenho
# ----------------------------------------------------------------------
## Halo suave atrás do glifo (3 anéis concêntricos). Pulado na Baixa.
static func _glow(node: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	if GameSettings.quality_cache >= 2:
		return
	node.draw_circle(c, r, Color(col, 0.10))
	if GameSettings.quality_cache >= 1:
		return
	node.draw_circle(c, r * 0.72, Color(col, 0.13))
	node.draw_circle(c, r * 0.46, Color(col, 0.16))

## Polígono com gradiente + contorno escuro + fio de luz interno.
static func _bevel(node: CanvasItem, pts: PackedVector2Array, c: Vector2,
		lite: Color, dark: Color) -> void:
	ArtUtil.shade_poly(node, pts, lite, dark)
	ArtUtil.stroke(node, pts, Color(0, 0, 0, 0.55), 1.5)
	if GameSettings.quality_cache >= 2:
		return
	var inner := PackedVector2Array()
	inner.resize(pts.size())
	for i in pts.size():
		var d := pts[i] - c
		if d.length() > 2.0:
			inner[i] = pts[i] - d.normalized() * 1.6
		else:
			inner[i] = pts[i]
	ArtUtil.stroke(node, inner, Color(lite.r, lite.g, lite.b, 0.6), 1.0)

## Elipse "bijou" com brilho especular.
static func _gem(node: CanvasItem, c: Vector2, rx: float, ry: float, main: Color,
		lite: Color) -> void:
	ArtUtil.shade_ellipse(node, c.x, c.y, rx, ry, ArtUtil.mix(lite, Color.WHITE, 0.3),
		ArtUtil.mix(main, Color.BLACK, 0.35))
	ArtUtil.fill_ellipse(node, c.x - rx * 0.28, c.y - ry * 0.34, rx * 0.3, ry * 0.26,
		Color(1, 1, 1, 0.75))

# ----------------------------------------------------------------------
#  Pintores (cada um cabe num quadrado ~2r)
# ----------------------------------------------------------------------
static func _p_sword(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.55)
	var blade := PackedVector2Array([
		c + Vector2(-r * 0.14, r * 0.58), c + Vector2(r * 0.07, r * 0.46),
		c + Vector2(r * 0.44, -r * 0.5), c + Vector2(r * 0.18, -r * 0.72)])
	_bevel(node, blade, c, ArtUtil.mix(lite, Color.WHITE, 0.5), dark)
	node.draw_line(c + Vector2(r * 0.06, r * 0.44), c + Vector2(r * 0.33, -r * 0.56),
		Color(1, 1, 1, 0.85), 1.4)
	# guarda
	var g0 := c + Vector2(-r * 0.52, r * 0.18)
	var g1 := c + Vector2(-r * 0.04, r * 0.54)
	node.draw_line(g0, g1, dark, 4.5)
	node.draw_line(g0, g1, main, 3.0)
	node.draw_line(g0, g1, ArtUtil.mix(lite, Color.WHITE, 0.4), 1.1)
	# cabo + pomo
	node.draw_line(c + Vector2(-r * 0.3, r * 0.5), c + Vector2(-r * 0.58, r * 0.76),
		ArtUtil.mix(main, Color.BLACK, 0.4), 4.0)
	_gem(node, c + Vector2(-r * 0.64, r * 0.82), r * 0.13, r * 0.13, main, lite)

static func _p_shield(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.55)
	var pts := PackedVector2Array([
		c + Vector2(-r * 0.62, -r * 0.58), c + Vector2(r * 0.62, -r * 0.58),
		c + Vector2(r * 0.62, r * 0.08), c + Vector2(0, r * 0.78),
		c + Vector2(-r * 0.62, r * 0.08)])
	_bevel(node, pts, c, ArtUtil.mix(lite, Color.WHITE, 0.3), dark)
	# veio central
	node.draw_line(c + Vector2(0, -r * 0.5), c + Vector2(0, r * 0.62),
		Color(1, 1, 1, 0.4), 1.4)
	# cruz
	node.draw_line(c + Vector2(-r * 0.4, -r * 0.12), c + Vector2(r * 0.4, -r * 0.12),
		ArtUtil.mix(dark, Color.WHITE, 0.25), 2.4)
	node.draw_line(c + Vector2(0, -r * 0.42), c + Vector2(0, r * 0.34),
		ArtUtil.mix(dark, Color.WHITE, 0.25), 2.4)
	# chefe + rebites
	_gem(node, c + Vector2(0, -r * 0.1), r * 0.2, r * 0.2, main, lite)
	for s in [-1.0, 1.0]:
		ArtUtil.fill_ellipse(node, c.x + s * r * 0.4, c.y - r * 0.38, r * 0.07, r * 0.07,
			ArtUtil.mix(lite, Color.WHITE, 0.5))

static func _p_quake(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.5)
	# fenda central (traço em zigzag, sem polígono)
	var crack := PackedVector2Array([
		c + Vector2(-r * 0.16, -r * 0.6), c + Vector2(r * 0.2, -r * 0.1),
		c + Vector2(-r * 0.05, r * 0.1), c + Vector2(r * 0.18, r * 0.62)])
	node.draw_polyline(crack, dark, 6.0, true)
	node.draw_polyline(crack, lite, 3.0, true)
	node.draw_polyline(crack, Color(1, 1, 1, 0.5), 1.2, true)
	# lasca de chão
	for s in [-1.0, 1.0]:
		var shard := PackedVector2Array([
			c + Vector2(s * r * 0.18, r * 0.34), c + Vector2(s * r * 0.74, r * 0.62),
			c + Vector2(s * r * 0.5, r * 0.14)])
		_bevel(node, shard, c, lite, dark)
	# poeira
	for i in 3:
		var a := -PI * 0.75 + i * PI * 0.75
		ArtUtil.fill_ellipse(node, c.x + cos(a) * r * 0.72, c.y - r * 0.42 + sin(a) * r * 0.2,
			r * 0.13, r * 0.11, Color(lite, 0.65))
	# impacto
	_gem(node, c + Vector2(0, -r * 0.5), r * 0.16, r * 0.16, main, lite)

static func _p_mace(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.55)
	# cabo
	var handle := PackedVector2Array([
		c + Vector2(-r * 0.1, r * 0.8), c + Vector2(r * 0.1, r * 0.8),
		c + Vector2(r * 0.09, -r * 0.12), c + Vector2(-r * 0.09, -r * 0.12)])
	_bevel(node, handle, c, dark, ArtUtil.mix(main, Color.BLACK, 0.75))
	# cabeça
	_gem(node, c + Vector2(0, -r * 0.38), r * 0.42, r * 0.4, main, lite)
	ArtUtil.stroke(node, ArtUtil.ellipse_pts(c.x, c.y - r * 0.38, r * 0.42, r * 0.4, 14),
		dark, 1.5)
	# espinhos
	for i in 8:
		var a := TAU * i / 8.0
		var p0 := c + Vector2(cos(a), sin(a) * 0.95) * r * 0.42 + Vector2(0, -r * 0.38)
		var p1 := c + Vector2(cos(a), sin(a) * 0.95) * r * 0.68 + Vector2(0, -r * 0.38)
		node.draw_line(p0, p1, lite, 2.2)
	# pomo
	_gem(node, c + Vector2(0, r * 0.76), r * 0.14, r * 0.14, main, lite)

static func _p_judgment(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.5)
	# arco/alança (traço em 3 camadas, sem polígono)
	for k in 3:
		var rad := r * 0.62 - float(3 - k) * 1.6
		var col := dark if k == 0 else (main if k == 1 else lite)
		var wid := 6.0 if k == 0 else (3.6 if k == 1 else 1.4)
		node.draw_arc(c + Vector2(0, -r * 0.1), rad, PI, TAU, 14, col, wid)
	# pratos
	for s in [-1.0, 1.0]:
		var sx: float = s
		var cx := c.x + sx * r * 0.5
		var cy := c.y + r * 0.3
		node.draw_line(Vector2(c.x + s * r * 0.6, c.y - r * 0.1), Vector2(cx, cy),
			lite, 1.6)
		var pan := PackedVector2Array([
			Vector2(cx - r * 0.26, cy), Vector2(cx + r * 0.26, cy),
			Vector2(cx + r * 0.16, cy + r * 0.16), Vector2(cx - r * 0.16, cy + r * 0.16)])
		_bevel(node, pan, Vector2(cx, cy), ArtUtil.mix(lite, Color.WHITE, 0.3), dark)
	# fogo sagrado
	for i in 3:
		var fl := PackedVector2Array([
			c + Vector2((i - 1) * r * 0.3 - r * 0.11, -r * 0.66),
			c + Vector2((i - 1) * r * 0.3, -r * 0.86 - (i % 2) * r * 0.08),
			c + Vector2((i - 1) * r * 0.3 + r * 0.11, -r * 0.66)])
		node.draw_colored_polygon(fl, Color(lite, 0.9))

static func _p_dagger(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.55)
	var blade := PackedVector2Array([
		c + Vector2(-r * 0.1, r * 0.34), c + Vector2(r * 0.14, r * 0.2),
		c + Vector2(r * 0.34, -r * 0.66), c + Vector2(r * 0.06, -r * 0.48)])
	_bevel(node, blade, c, ArtUtil.mix(lite, Color.WHITE, 0.5), dark)
	node.draw_line(c + Vector2(r * 0.1, r * 0.22), c + Vector2(r * 0.24, -r * 0.56),
		Color(1, 1, 1, 0.8), 1.3)
	# guarda + cabo
	var g0 := c + Vector2(-r * 0.34, r * 0.2)
	var g1 := c + Vector2(r * 0.1, r * 0.52)
	node.draw_line(g0, g1, main, 4.0)
	node.draw_line(g0, g1, ArtUtil.mix(lite, Color.WHITE, 0.4), 1.2)
	node.draw_line(c + Vector2(-r * 0.14, r * 0.44), c + Vector2(-r * 0.46, r * 0.72),
		ArtUtil.mix(main, Color.BLACK, 0.4), 4.0)
	# estilhaços de sombra
	for i in 2:
		node.draw_line(c + Vector2(-r * 0.86, -r * 0.3 + i * r * 0.3),
			c + Vector2(-r * 0.4, -r * 0.44 + i * r * 0.3), Color(lite, 0.55), 1.6)

static func _p_blades(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.55)
	for s in [1.0, -1.0]:
		var blade := PackedVector2Array([
			c + Vector2(-r * 0.08 * s, -r * 0.2), c + Vector2(r * 0.16 * s, -r * 0.02),
			c + Vector2(r * 0.6 * s, r * 0.62), c + Vector2(r * 0.3 * s, r * 0.5)])
		_bevel(node, blade, c, ArtUtil.mix(lite, Color.WHITE, 0.35), dark)
		var g0 := c + Vector2(-r * 0.2 * s, -r * 0.28)
		var g1 := c + Vector2(r * 0.16 * s, -r * 0.08)
		node.draw_line(g0, g1, main, 4.0)
		node.draw_line(g0, g1, Color(1, 1, 1, 0.5), 1.2)
	# centro
	_gem(node, c + Vector2(0, r * 0.06), r * 0.16, r * 0.16, main, lite)

static func _p_fan(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.5)
	for i in 3:
		var a := -PI * 0.78 + i * PI * 0.28
		var d := Vector2(cos(a), sin(a))
		var o := d.orthogonal()
		var pts := PackedVector2Array([
			c + d * r * 0.86, c + d * r * 0.3 + o * r * 0.16,
			c + d * r * 0.22, c + d * r * 0.3 - o * r * 0.16])
		_bevel(node, pts, c, ArtUtil.mix(lite, Color.WHITE, 0.3), dark)
		ArtUtil.fill_ellipse(node, c.x + d.x * r * 0.52, c.y + d.y * r * 0.52,
			r * 0.07, r * 0.07, Color(1, 1, 1, 0.7))
	_gem(node, c, r * 0.17, r * 0.17, main, lite)

static func _p_mark(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.5)
	# selo
	node.draw_arc(c, r * 0.64, 0, TAU, 24, Color(dark, 0.9), 5.0)
	node.draw_arc(c, r * 0.64, 0, TAU, 24, main, 3.0)
	node.draw_arc(c, r * 0.64, -1.4, 1.4, 12, Color(lite, 0.95), 2.0)
	node.draw_arc(c, r * 0.46, 0, TAU, 18, Color(lite, 0.6), 1.6)
	# garras do selo
	for i in 4:
		var a := TAU * i / 4.0 + 0.785
		var d := Vector2(cos(a), sin(a))
		node.draw_line(c + d * r * 0.6, c + d * r * 0.9, lite, 3.0)
	# cruz
	node.draw_line(c + Vector2(-r * 0.3, -r * 0.3), c + Vector2(r * 0.3, r * 0.3),
		ArtUtil.mix(lite, Color.WHITE, 0.4), 3.4)
	node.draw_line(c + Vector2(r * 0.3, -r * 0.3), c + Vector2(-r * 0.3, r * 0.3),
		ArtUtil.mix(lite, Color.WHITE, 0.4), 3.4)
	_gem(node, c, r * 0.13, r * 0.13, main, lite)

static func _p_eclipse(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var corona := ArtUtil.mix(main, lite, 0.4)
	# halo
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.78, r * 0.78, Color(corona, 0.28))
	# disco escuro
	ArtUtil.shade_ellipse(node, c.x, c.y, r * 0.58, r * 0.58,
		Color(0.14, 0.07, 0.24), Color(0.02, 0.01, 0.06))
	node.draw_arc(c, r * 0.58, 0, TAU, 24, main, 2.6)
	# coroa recortada
	node.draw_arc(c, r * 0.7, -2.6, -0.5, 12, corona, 3.0)
	node.draw_arc(c, r * 0.7, 0.6, 2.6, 12, corona, 3.0)
	# estrelas
	for i in 3:
		var a := 1.1 + i * 1.9
		node.draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.86, 1.8, Color(1, 1, 1, 0.9))
	node.draw_colored_polygon(ArtUtil.star_pts(c.x + r * 0.44, c.y - r * 0.5, r * 0.14),
		Color(1, 1, 1, 0.9))

static func _p_orb(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	# aura
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.8, r * 0.8, Color(main, 0.22))
	# corpo
	ArtUtil.shade_ellipse(node, c.x, c.y, r * 0.56, r * 0.56,
		ArtUtil.mix(lite, Color.WHITE, 0.35), ArtUtil.mix(main, Color.BLACK, 0.5))
	# órbita
	node.draw_arc(c, r * 0.72, -1.2, 1.6, 14, Color(1, 1, 1, 0.75), 2.0)
	node.draw_arc(c, r * 0.72, 2.0, 4.4, 14, Color(main, 0.8), 2.0)
	# especular + faísca
	ArtUtil.fill_ellipse(node, c.x - r * 0.18, c.y - r * 0.2, r * 0.16, r * 0.13,
		Color(1, 1, 1, 0.9))
	node.draw_colored_polygon(ArtUtil.star_pts(c.x + r * 0.46, c.y - r * 0.46, r * 0.15),
		Color(1, 1, 1, 0.85))

static func _p_crescent(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	# corpo da lua
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.6, r * 0.6, Color(main, 0.95))
	ArtUtil.fill_ellipse(node, c.x + r * 0.3, c.y - r * 0.1, r * 0.52, r * 0.52,
		Color(0.05, 0.06, 0.12, 1.0))
	# contorno luminoso
	node.draw_arc(c + Vector2(-r * 0.02, 0), r * 0.6, 0.7, 4.9, 20, lite, 3.0)
	node.draw_arc(c + Vector2(-r * 0.02, 0), r * 0.6, 1.0, 4.6, 16, Color(1, 1, 1, 0.7), 1.3)
	# estrelas
	for i in 3:
		var a := -0.9 + i * 1.5
		node.draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.84, 1.9, Color(1, 1, 1, 0.85))
	node.draw_colored_polygon(ArtUtil.star_pts(c.x - r * 0.5, c.y - r * 0.52, r * 0.14),
		Color(1, 1, 1, 0.9))

static func _p_rune(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.5)
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.74, r * 0.74, Color(main, 0.16))
	node.draw_arc(c, r * 0.68, 0, TAU, 26, dark, 4.5)
	node.draw_arc(c, r * 0.68, 0, TAU, 26, main, 2.8)
	node.draw_arc(c, r * 0.68, -1.5, 1.2, 12, Color(lite, 0.95), 2.0)
	# triângulo rúnico
	var tri := PackedVector2Array()
	for i in 3:
		var a := -PI * 0.5 + TAU * i / 3.0
		tri.append(c + Vector2(cos(a), sin(a)) * r * 0.48)
	ArtUtil.stroke(node, tri, lite, 2.6)
	var tri2 := PackedVector2Array()
	for i in 3:
		var a := PI * 0.5 + TAU * i / 3.0
		tri2.append(c + Vector2(cos(a), sin(a)) * r * 0.48)
	ArtUtil.stroke(node, tri2, Color(lite, 0.55), 2.0)
	_gem(node, c, r * 0.15, r * 0.15, main, lite)

static func _p_storm(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.45)
	# nuvem
	for s in [-1.0, 1.0]:
		ArtUtil.shade_ellipse(node, c.x + s * r * 0.34, c.y - r * 0.5, r * 0.34, r * 0.24,
			ArtUtil.mix(lite, Color.WHITE, 0.2), dark)
	ArtUtil.shade_ellipse(node, c.x, c.y - r * 0.58, r * 0.42, r * 0.28,
		ArtUtil.mix(lite, Color.WHITE, 0.35), main)
	# raio
	var bolt := PackedVector2Array([
		c + Vector2(r * 0.18, -r * 0.34), c + Vector2(-r * 0.24, r * 0.16),
		c + Vector2(-r * 0.02, r * 0.16), c + Vector2(-r * 0.16, r * 0.72),
		c + Vector2(r * 0.3, r * 0.12), c + Vector2(r * 0.06, r * 0.12)])
	_bevel(node, bolt, c, Color(1, 1, 1, 1), ArtUtil.mix(lite, Color.BLACK, 0.25))
	# faíscas
	for i in 2:
		node.draw_line(c + Vector2(-r * 0.7 + i * r * 1.4, r * 0.4),
			c + Vector2(-r * 0.5 + i * r * 1.4, r * 0.68), Color(lite, 0.7), 1.8)

static func _p_star(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var pts := PackedVector2Array()
	pts.resize(16)
	for i in 16:
		var a := TAU * i / 16.0 - PI * 0.5
		var rr := r * 0.8 if i % 2 == 0 else r * 0.34
		pts[i] = c + Vector2(cos(a), sin(a)) * rr
	node.draw_colored_polygon(pts, main)
	ArtUtil.stroke(node, pts, ArtUtil.mix(main, Color.BLACK, 0.6), 1.5)
	ArtUtil.stroke(node, PackedVector2Array([
		c + Vector2(0, -r * 0.8), c + Vector2(r * 0.2, -r * 0.4)]),
		Color(1, 1, 1, 0.55), 1.4)
	_gem(node, c, r * 0.24, r * 0.24, main, lite)
	node.draw_colored_polygon(ArtUtil.star_pts(c.x + r * 0.62, c.y - r * 0.56, r * 0.16),
		Color(1, 1, 1, 0.9))

static func _p_arrow(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.5)
	var dir := Vector2(0.72, -0.72)
	var shaft0 := c + Vector2(-r * 0.62, r * 0.62)
	var shaft1 := c + Vector2(r * 0.34, -r * 0.34)
	# sombra + eixo
	node.draw_line(shaft0 + Vector2(1.5, 1.5), shaft1 + Vector2(1.5, 1.5), Color(0, 0, 0, 0.5), 5.0)
	node.draw_line(shaft0, shaft1, dark, 5.0)
	node.draw_line(shaft0, shaft1, main, 3.2)
	node.draw_line(shaft0, shaft1, Color(1, 1, 1, 0.45), 1.1)
	# ponta
	var tip := c + Vector2(r * 0.66, -r * 0.66)
	var side := dir.orthogonal() * r * 0.19
	_bevel(node, PackedVector2Array([tip, shaft1 + side, shaft1 - side]), c,
		ArtUtil.mix(lite, Color.WHITE, 0.5), dark)
	# penas
	for i in 2:
		var base := shaft0.lerp(shaft1, 0.18 + i * 0.2)
		node.draw_line(base, base + Vector2(-r * 0.26, r * 0.06), main, 2.4)
		node.draw_line(base, base + Vector2(-r * 0.06, r * 0.26), main, 2.4)
	# faísca
	node.draw_colored_polygon(ArtUtil.star_pts(c.x - r * 0.6, c.y - r * 0.5, r * 0.13),
		Color(1, 1, 1, 0.85))

static func _p_rain(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.5)
	# arco de disparo
	node.draw_arc(c + Vector2(0, -r * 0.72), r * 0.7, 0.35, 2.8, 14, Color(main, 0.8), 3.0)
	for i in 3:
		var x := c.x - r * 0.46 + i * r * 0.46
		var y0 := c.y - r * 0.5 + float(i % 2) * r * 0.1
		var y1 := c.y + r * 0.34 + float(i % 2) * r * 0.1
		node.draw_line(Vector2(x, y0), Vector2(x, y1), dark, 4.0)
		node.draw_line(Vector2(x, y0), Vector2(x, y1), main, 2.4)
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(x, y1 + r * 0.24), Vector2(x - r * 0.13, y1), Vector2(x + r * 0.13, y1)]),
			ArtUtil.mix(lite, Color.WHITE, 0.4))
		node.draw_line(Vector2(x - r * 0.1, y0 + r * 0.06), Vector2(x, y0 + r * 0.2),
			Color(lite, 0.85), 1.8)
		node.draw_line(Vector2(x + r * 0.1, y0 + r * 0.06), Vector2(x, y0 + r * 0.2),
			Color(lite, 0.85), 1.8)
	# alvo no chão
	ArtUtil.fill_ellipse(node, c.x, c.y + r * 0.66, r * 0.6, r * 0.14, Color(main, 0.35))

static func _p_pierce(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.5)
	# eixo
	node.draw_line(c + Vector2(-r * 0.8, 1.5), c + Vector2(r * 0.62, 1.5), Color(0, 0, 0, 0.5), 5.5)
	node.draw_line(c + Vector2(-r * 0.8, 0), c + Vector2(r * 0.62, 0), dark, 5.0)
	node.draw_line(c + Vector2(-r * 0.8, 0), c + Vector2(r * 0.62, 0), main, 3.0)
	node.draw_line(c + Vector2(-r * 0.8, 0), c + Vector2(r * 0.55, 0),
		Color(1, 1, 1, 0.5), 1.1)
	# ponta
	_bevel(node, PackedVector2Array([
		c + Vector2(r * 0.86, 0), c + Vector2(r * 0.46, -r * 0.22),
		c + Vector2(r * 0.46, r * 0.22)]), c, ArtUtil.mix(lite, Color.WHITE, 0.5), dark)
	# anéis atravessados
	for s in [-1.0, 1.0]:
		var cc := c + Vector2(s * r * 0.24, 0)
		node.draw_arc(cc, r * 0.3, 0, TAU, 16, main, 2.6)
		node.draw_arc(cc, r * 0.3, -0.9, 0.9, 8, Color(lite, 0.95), 2.0)

static func _p_crosshair(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.45)
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.78, r * 0.78, Color(main, 0.16))
	node.draw_arc(c, r * 0.66, 0, TAU, 26, dark, 5.0)
	node.draw_arc(c, r * 0.66, 0, TAU, 26, main, 3.0)
	node.draw_arc(c, r * 0.66, -1.6, 1.4, 12, Color(lite, 0.95), 2.0)
	node.draw_arc(c, r * 0.4, 0, TAU, 18, Color(main, 0.9), 2.2)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		var d := Vector2(cos(a), sin(a))
		node.draw_line(c + d * r * 0.72, c + d * r * 0.94, lite, 2.6)
	_gem(node, c, r * 0.14, r * 0.14, main, lite)

static func _p_comet(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.45)
	# cauda
	for i in 3:
		var off := (i - 1) * r * 0.22
		var a := Color(lite, 0.45 - i * 0.1)
		node.draw_line(c + Vector2(r * 0.16, -r * 0.16 + off),
			c + Vector2(-r * 0.78, r * 0.72 + off), a, 6.0 - i * 1.5)
	# núcleo
	ArtUtil.fill_ellipse(node, c.x + r * 0.3, c.y - r * 0.3, r * 0.34, r * 0.34,
		Color(main, 0.4))
	_gem(node, c + Vector2(r * 0.3, -r * 0.3), r * 0.26, r * 0.26, main, lite)
	# estrela da cauda
	node.draw_colored_polygon(ArtUtil.star_pts(c.x - r * 0.5, c.y + r * 0.42, r * 0.14),
		Color(1, 1, 1, 0.85))

static func _p_cross(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.45)
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.74, r * 0.74, Color(main, 0.2))
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.6, r * 0.6, Color(main, 0.35))
	var w := r * 0.2
	var s := r * 0.62
	var pts := PackedVector2Array([
		c + Vector2(-w, -s), c + Vector2(w, -s), c + Vector2(w, -w),
		c + Vector2(s, -w), c + Vector2(s, w), c + Vector2(w, w),
		c + Vector2(w, s), c + Vector2(-w, s), c + Vector2(-w, w),
		c + Vector2(-s, w), c + Vector2(-s, -w), c + Vector2(-w, -w)])
	_bevel(node, pts, c, ArtUtil.mix(lite, Color.WHITE, 0.4), dark)
	ArtUtil.fill_ellipse(node, c.x - r * 0.16, c.y - r * 0.3, r * 0.1, r * 0.14,
		Color(1, 1, 1, 0.65))

static func _p_swirl(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.4)
	for i in 3:
		var rr := r * (0.72 - i * 0.17)
		var a0 := i * 1.3
		node.draw_arc(c, rr, a0, a0 + 3.9, 18, Color(dark, 0.7), 5.0 - i * 0.8)
		node.draw_arc(c, rr, a0, a0 + 3.9, 18, main if i != 1 else lite, 3.0 - i * 0.5)
	# centro + pontas
	_gem(node, c, r * 0.15, r * 0.15, main, lite)
	for i in 2:
		var a := 3.9 + i * 1.3
		node.draw_circle(c + Vector2(cos(a), sin(a)) * r * (0.72 - i * 0.17), 2.4,
			Color(lite, 0.9))

static func _p_heart(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.45)
	var pts := PackedVector2Array()
	for i in 20:
		var tt := TAU * i / 20.0
		var x := 16.0 * pow(sin(tt), 3.0)
		var y := 13.0 * cos(tt) - 5.0 * cos(2.0 * tt) - 2.0 * cos(3.0 * tt) - cos(4.0 * tt)
		pts.append(c + Vector2(x, -y) * (r * 0.048))
	_bevel(node, pts, c, ArtUtil.mix(lite, Color.WHITE, 0.4), dark)
	ArtUtil.fill_ellipse(node, c.x - r * 0.24, c.y - r * 0.2, r * 0.14, r * 0.11,
		Color(1, 1, 1, 0.7))
	ArtUtil.fill_ellipse(node, c.x + r * 0.3, c.y - r * 0.3, r * 0.08, r * 0.07,
		Color(1, 1, 1, 0.5))

static func _p_eye(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.5)
	var out := PackedVector2Array([
		c + Vector2(-r * 0.76, 0), c + Vector2(-r * 0.32, -r * 0.44),
		c + Vector2(r * 0.32, -r * 0.44), c + Vector2(r * 0.76, 0),
		c + Vector2(r * 0.32, r * 0.44), c + Vector2(-r * 0.32, r * 0.44)])
	ArtUtil.shade_poly(node, out, Color(1, 1, 1, 0.92), ArtUtil.mix(main, Color.WHITE, 0.4))
	ArtUtil.stroke(node, out, dark, 2.6)
	# íris
	ArtUtil.shade_ellipse(node, c.x, c.y, r * 0.3, r * 0.32, lite, dark)
	node.draw_arc(c, r * 0.3, 0, TAU, 18, dark, 2.0)
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.14, r * 0.16, Color(0.04, 0.05, 0.1, 1.0))
	ArtUtil.fill_ellipse(node, c.x - r * 0.1, c.y - r * 0.12, r * 0.08, r * 0.07,
		Color(1, 1, 1, 0.95))
	# pestanelas
	for i in 3:
		var x := c.x - r * 0.34 + i * r * 0.34
		node.draw_line(Vector2(x, c.y - r * 0.44), Vector2(x - r * 0.06, c.y - r * 0.66),
			dark, 2.0)

static func _p_rebirth(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var dark := ArtUtil.mix(main, Color.BLACK, 0.45)
	# chama
	var flame := PackedVector2Array([
		c + Vector2(-r * 0.3, r * 0.5), c + Vector2(-r * 0.34, 0),
		c + Vector2(-r * 0.08, -r * 0.2), c + Vector2(-r * 0.06, -r * 0.66),
		c + Vector2(r * 0.14, -r * 0.2), c + Vector2(r * 0.3, r * 0.06),
		c + Vector2(r * 0.28, r * 0.5)])
	_bevel(node, flame, c, ArtUtil.mix(lite, Color.WHITE, 0.35), dark)
	# núcleo quente
	node.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.12, r * 0.44), c + Vector2(-r * 0.1, r * 0.02),
		c + Vector2(r * 0.02, -r * 0.3), c + Vector2(r * 0.14, r * 0.04),
		c + Vector2(r * 0.14, r * 0.44)]), Color(1, 1, 0.7, 0.9))
	# setas de renascimento
	for i in 2:
		var a0 := -2.5 + i * PI
		node.draw_arc(c, r * 0.82, a0, a0 + 1.7, 14, main, 3.0)
		var tip := c + Vector2(cos(a0 + 1.7), sin(a0 + 1.7)) * r * 0.82
		var tang := Vector2(-sin(a0 + 1.7), cos(a0 + 1.7))
		node.draw_colored_polygon(PackedVector2Array([
			tip + tang * r * 0.18, tip - tang * r * 0.18, tip + tang * r * 0.02 + Vector2(cos(a0 + 1.7), sin(a0 + 1.7)) * r * 0.18]),
			Color(lite, 0.95))
