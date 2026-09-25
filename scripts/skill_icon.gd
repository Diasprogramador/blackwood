class_name SkillIcon
extends Object

## Icones procedurais das skills + mapeamento de efeitos por personagem.
## Como o jogo voltou ao visual desenhado via codigo, os icones tambem
## sao desenhados (sem PNG): cada (role, slot) tem um glifo proprio,
## usado na barra do HUD, e um simbolo unicode para os textos da loja.

# ----------------------------------------------------------------------
#  Dados (texto/UI)
# ----------------------------------------------------------------------
static func role_color(role: String) -> Color:
	for c in ChampData.CHAMPS:
		if str(c.get("role", "")) == role:
			var col: Color = c.get("color", Color.WHITE)
			return col
	return Color.WHITE

## Simbolo unicode da skill (loja, mensagens).
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
static func effect_for(role: String, kind: String, _slot: int) -> int:
	if kind == "heal":
		return AttackEffect.Type.HEAL
	return basic_effect_for(role)

static func basic_effect_for(role: String) -> int:
	match role:
		"tank": return AttackEffect.Type.TANK_SLAM
		"assassin": return AttackEffect.Type.SHADOW_CLAWS
		"mage": return AttackEffect.Type.ARCANE_NOVA
		"marksman": return AttackEffect.Type.FROST_VOLLEY
		"support": return AttackEffect.Type.GALE_SWIPE
	return AttackEffect.Type.SLASH

# ----------------------------------------------------------------------
#  Desenho (HUD)
# ----------------------------------------------------------------------
## Desenha o icone da skill centralizado em `c`, com raio ~`r`.
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
				_: _p_eclipse(node, c, r, lite)
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

## Soco basico (slot ATK): punho na cor do personagem.
static func draw_basic(node: CanvasItem, role: String, c: Vector2, r: float,
		ready: bool = true) -> void:
	var main: Color = role_color(role)
	if not ready:
		main = Color(0.4, 0.4, 0.42)
	ArtUtil.fill_rrect(node, c.x - r * 0.75, c.y - r * 0.55, r * 1.5, r * 1.1, 4.0, main)
	ArtUtil.fill_ellipse(node, c.x, c.y - r * 0.55, r * 0.75, r * 0.3, ArtUtil.mix(main, Color.WHITE, 0.3))
	for i in 3:
		var kx := c.x - r * 0.4 + i * r * 0.4
		node.draw_line(Vector2(kx, c.y - r * 0.5), Vector2(kx, c.y - r * 0.1),
			ArtUtil.mix(main, Color.BLACK, 0.4), 1.5)
	node.draw_line(Vector2(c.x - r * 0.75, c.y + r * 0.2), Vector2(c.x + r * 0.75, c.y + r * 0.2),
		Color.WHITE if ready else Color(0.6, 0.6, 0.6), 2.0)

# ----------------------------------------------------------------------
#  Pintores (cada um cabe num quadrado ~2r)
# ----------------------------------------------------------------------
static func _p_sword(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var blade := PackedVector2Array([
		c + Vector2(-r * 0.15, r * 0.7), c + Vector2(r * 0.05, r * 0.55),
		c + Vector2(r * 0.45, -r * 0.55), c + Vector2(r * 0.25, -r * 0.7)])
	ArtUtil.shade_poly(node, blade, lite, main)
	node.draw_line(c + Vector2(-r * 0.45, r * 0.35), c + Vector2(r * 0.35, -r * 0.15), main, 3.0)
	node.draw_line(c + Vector2(-r * 0.35, r * 0.75), c + Vector2(-r * 0.1, r * 0.5),
		ArtUtil.mix(main, Color.BLACK, 0.4), 3.0)

static func _p_shield(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var pts := PackedVector2Array([
		c + Vector2(-r * 0.6, -r * 0.55), c + Vector2(r * 0.6, -r * 0.55),
		c + Vector2(r * 0.6, r * 0.1), c + Vector2(0, r * 0.75), c + Vector2(-r * 0.6, r * 0.1)])
	ArtUtil.shade_poly(node, pts, ArtUtil.mix(main, Color.WHITE, 0.25), ArtUtil.mix(main, Color.BLACK, 0.45))
	ArtUtil.stroke(node, pts, lite, 1.5)
	ArtUtil.fill_ellipse(node, c.x, c.y - r * 0.05, r * 0.2, r * 0.2, lite)

static func _p_quake(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	for i in 3:
		var y := c.y - r * 0.5 + i * r * 0.45
		var w := r * (0.35 + i * 0.2)
		node.draw_line(Vector2(c.x - w, y), Vector2(c.x, y + r * 0.25), main, 3.0)
		node.draw_line(Vector2(c.x + w, y), Vector2(c.x, y + r * 0.25), main, 3.0)
	node.draw_circle(c + Vector2(0, -r * 0.55), 2.0, lite)

static func _p_mace(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	node.draw_line(c + Vector2(0, r * 0.75), c + Vector2(0, -r * 0.1),
		ArtUtil.mix(main, Color.BLACK, 0.4), 3.5)
	ArtUtil.fill_ellipse(node, c.x, c.y - r * 0.35, r * 0.4, r * 0.4, main)
	ArtUtil.fill_ellipse(node, c.x - r * 0.1, c.y - r * 0.45, r * 0.15, r * 0.15, lite)
	for i in 8:
		var a := TAU * i / 8.0
		node.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.4 + Vector2(0, -r * 0.35),
			c + Vector2(cos(a), sin(a)) * r * 0.62 + Vector2(0, -r * 0.35), lite, 2.0)

static func _p_judgment(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	node.draw_arc(c, r * 0.55, 0, TAU, 20, main, 2.5)
	for i in 8:
		var a := TAU * i / 8.0
		node.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.65,
			c + Vector2(cos(a), sin(a)) * r * 0.85, lite, 2.0)
	node.draw_line(c + Vector2(0, -r * 0.4), c + Vector2(0, r * 0.45), lite, 3.0)
	node.draw_line(c + Vector2(-r * 0.18, r * 0.1), c + Vector2(r * 0.18, r * 0.1), lite, 3.0)

static func _p_dagger(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var blade := PackedVector2Array([
		c + Vector2(-r * 0.1, r * 0.4), c + Vector2(r * 0.1, r * 0.3),
		c + Vector2(r * 0.3, -r * 0.6), c + Vector2(r * 0.1, -r * 0.5)])
	ArtUtil.shade_poly(node, blade, lite, ArtUtil.mix(main, Color.BLACK, 0.3))
	node.draw_line(c + Vector2(-r * 0.3, r * 0.35), c + Vector2(r * 0.3, r * 0.2), main, 3.0)
	for i in 2:
		node.draw_line(c + Vector2(-r * 0.8, -r * 0.2 + i * r * 0.25),
			c + Vector2(-r * 0.25, -r * 0.35 + i * r * 0.25), Color(lite, 0.5), 1.5)

static func _p_blades(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	node.draw_line(c + Vector2(-r * 0.6, -r * 0.6), c + Vector2(r * 0.6, r * 0.6), lite, 3.0)
	node.draw_line(c + Vector2(r * 0.6, -r * 0.6), c + Vector2(-r * 0.6, r * 0.6), lite, 3.0)
	node.draw_line(c + Vector2(-r * 0.6, -r * 0.6), c + Vector2(r * 0.6, r * 0.6),
		ArtUtil.mix(main, Color.BLACK, 0.2), 1.2)
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.16, r * 0.16, main)

static func _p_fan(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	for i in 3:
		var a := -PI * 0.75 + i * PI * 0.25
		var tip := c + Vector2(cos(a), sin(a)) * r * 0.8
		node.draw_line(c, tip, lite, 2.5)
		node.draw_circle(tip, 2.2, main)
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.16, r * 0.16, main)

static func _p_mark(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	node.draw_arc(c, r * 0.6, 0, TAU, 20, main, 2.5)
	node.draw_line(c + Vector2(-r * 0.35, -r * 0.35), c + Vector2(r * 0.35, r * 0.35), lite, 3.0)
	node.draw_line(c + Vector2(r * 0.35, -r * 0.35), c + Vector2(-r * 0.35, r * 0.35), lite, 3.0)

static func _p_eclipse(node: CanvasItem, c: Vector2, r: float, lite: Color) -> void:
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.55, r * 0.55, Color(0.05, 0.03, 0.1))
	node.draw_arc(c, r * 0.55, 0, TAU, 20, Color(0.55, 0.25, 0.9), 2.5)
	node.draw_arc(c, r * 0.75, 0.4, 2.4, 14, lite, 2.0)
	node.draw_circle(c + Vector2(-r * 0.5, -r * 0.5), 1.8, lite)

static func _p_orb(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.6, r * 0.6, ArtUtil.with_a(main, 0.35))
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.38, r * 0.38, main)
	node.draw_arc(c, r * 0.38, 0.5, 4.0, 16, lite, 2.0)
	ArtUtil.fill_ellipse(node, c.x - r * 0.12, c.y - r * 0.14, r * 0.12, r * 0.12, Color.WHITE)

static func _p_crescent(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	node.draw_arc(c, r * 0.6, 0.6, 5.2, 20, main, 4.0)
	node.draw_arc(c, r * 0.6, 0.9, 4.9, 18, lite, 1.5)
	node.draw_circle(c + Vector2(r * 0.5, -r * 0.4), 1.8, lite)
	node.draw_circle(c + Vector2(-r * 0.55, r * 0.35), 1.5, lite)

static func _p_rune(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	node.draw_arc(c, r * 0.62, 0, TAU, 20, main, 2.5)
	var tri := PackedVector2Array()
	for i in 3:
		var a := -PI * 0.5 + TAU * i / 3.0
		tri.append(c + Vector2(cos(a), sin(a)) * r * 0.45)
	ArtUtil.stroke(node, tri, lite, 2.0)
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.12, r * 0.12, lite)

static func _p_storm(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var bolt := PackedVector2Array([
		c + Vector2(r * 0.15, -r * 0.7), c + Vector2(-r * 0.25, r * 0.05),
		c + Vector2(-r * 0.02, r * 0.05), c + Vector2(-r * 0.15, r * 0.7),
		c + Vector2(r * 0.28, -r * 0.05), c + Vector2(r * 0.05, -r * 0.05)])
	node.draw_colored_polygon(bolt, lite)
	ArtUtil.fill_ellipse(node, c.x - r * 0.35, c.y - r * 0.55, r * 0.3, r * 0.2, main)
	ArtUtil.fill_ellipse(node, c.x + r * 0.1, c.y - r * 0.62, r * 0.32, r * 0.22, main)

static func _p_star(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0 - PI * 0.5
		var rr := r * 0.75 if i % 2 == 0 else r * 0.32
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	node.draw_colored_polygon(pts, main)
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.2, r * 0.2, lite)

static func _p_arrow(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	node.draw_line(c + Vector2(-r * 0.6, r * 0.6), c + Vector2(r * 0.4, -r * 0.4), lite, 2.5)
	var tip := c + Vector2(r * 0.4, -r * 0.4)
	node.draw_colored_polygon(PackedVector2Array([
		tip, tip + Vector2(-r * 0.35, 0), tip + Vector2(0, r * 0.35)]), main)
	for i in 2:
		var p := c + Vector2(-r * 0.45 + i * r * 0.2, r * 0.45 - i * r * 0.2)
		node.draw_line(p, p + Vector2(-r * 0.2, -r * 0.05), main, 2.0)
	node.draw_circle(c + Vector2(-r * 0.5, -r * 0.45), 1.6, lite)

static func _p_rain(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	for i in 3:
		var x := c.x - r * 0.5 + i * r * 0.5
		node.draw_line(Vector2(x, c.y - r * 0.6), Vector2(x, c.y + r * 0.35), lite, 2.0)
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(x, c.y + r * 0.55), Vector2(x - r * 0.12, c.y + r * 0.3),
			Vector2(x + r * 0.12, c.y + r * 0.3)]), main)

static func _p_pierce(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	node.draw_line(c + Vector2(-r * 0.75, 0), c + Vector2(r * 0.75, 0), lite, 3.0)
	node.draw_colored_polygon(PackedVector2Array([
		c + Vector2(r * 0.75, 0), c + Vector2(r * 0.4, -r * 0.18), c + Vector2(r * 0.4, r * 0.18)]), main)
	node.draw_arc(c + Vector2(-r * 0.25, 0), r * 0.3, 0, TAU, 16, main, 2.0)
	node.draw_arc(c + Vector2(r * 0.25, 0), r * 0.3, 0, TAU, 16, main, 2.0)

static func _p_crosshair(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	node.draw_arc(c, r * 0.6, 0, TAU, 20, main, 2.5)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		node.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.6,
			c + Vector2(cos(a), sin(a)) * r * 0.85, lite, 2.0)
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.14, r * 0.14, lite)

static func _p_comet(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	ArtUtil.fill_ellipse(node, c.x + r * 0.3, c.y - r * 0.3, r * 0.3, r * 0.3, main)
	ArtUtil.fill_ellipse(node, c.x + r * 0.22, c.y - r * 0.38, r * 0.12, r * 0.12, Color.WHITE)
	for i in 3:
		var off := (i - 1) * r * 0.25
		node.draw_line(c + Vector2(r * 0.15, -r * 0.15 + off),
			c + Vector2(-r * 0.7, r * 0.7 + off), Color(lite, 0.7 - i * 0.15), 2.0)

static func _p_cross(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.62, r * 0.62, ArtUtil.with_a(main, 0.3))
	node.draw_line(c + Vector2(-r * 0.4, 0), c + Vector2(r * 0.4, 0), lite, 4.0)
	node.draw_line(c + Vector2(0, -r * 0.4), c + Vector2(0, r * 0.4), lite, 4.0)

static func _p_swirl(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	for i in 3:
		var rr := r * (0.6 - i * 0.16)
		node.draw_arc(c, rr, i * 1.2, i * 1.2 + 3.6, 16, main if i != 1 else lite, 2.5)

static func _p_heart(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	ArtUtil.fill_ellipse(node, c.x - r * 0.25, c.y - r * 0.15, r * 0.3, r * 0.28, main)
	ArtUtil.fill_ellipse(node, c.x + r * 0.25, c.y - r * 0.15, r * 0.3, r * 0.28, main)
	node.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.5, -r * 0.05), c + Vector2(r * 0.5, -r * 0.05),
		c + Vector2(0, r * 0.6)]), main)
	ArtUtil.fill_ellipse(node, c.x - r * 0.25, c.y - r * 0.2, r * 0.1, r * 0.1, Color(lite, 0.8))

static func _p_eye(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	var out := PackedVector2Array([
		c + Vector2(-r * 0.7, 0), c + Vector2(-r * 0.3, -r * 0.4),
		c + Vector2(r * 0.3, -r * 0.4), c + Vector2(r * 0.7, 0),
		c + Vector2(r * 0.3, r * 0.4), c + Vector2(-r * 0.3, r * 0.4)])
	ArtUtil.stroke(node, out, main, 2.5)
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.22, r * 0.26, main)
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.1, r * 0.12, lite)

static func _p_rebirth(node: CanvasItem, c: Vector2, r: float, main: Color, lite: Color) -> void:
	node.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.35, r * 0.6), c + Vector2(0, -r * 0.2),
		c + Vector2(-r * 0.1, r * 0.6)]), main)
	node.draw_colored_polygon(PackedVector2Array([
		c + Vector2(r * 0.35, r * 0.6), c + Vector2(r * 0.05, -r * 0.45),
		c + Vector2(r * 0.15, r * 0.6)]), lite)
	for i in 3:
		node.draw_circle(c + Vector2((i - 1) * r * 0.3, -r * (0.55 + i * 0.12)),
			2.2 - i * 0.5, Color(lite, 0.8 - i * 0.2))
