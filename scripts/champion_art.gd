class_name ChampionArt
extends Object

## Port do ChampionDesigner.java para Godot _draw().
## Desenha voltado para a direita; o flip é aplicado pelo chamador (scale.x).

static var A = ArtUtil

static func draw_champion(node: CanvasItem, role: String, bob: int, flash: bool,
		walk_phase: float, moving: bool, punch_t: float) -> void:
	var has_flash := flash
	match role:
		"tank": _garen(node, bob, has_flash, walk_phase, moving)
		"assassin": _zed(node, bob, has_flash, walk_phase, moving)
		"mage": _ahri(node, bob, has_flash, walk_phase, moving)
		"marksman": _ashe(node, bob, has_flash, walk_phase, moving)
		"support": _janna(node, bob, has_flash, walk_phase, moving)
	if punch_t > 0.0:
		_draw_punch(node, punch_t)

static func _f(has_flash: bool, base: Color) -> Color:
	return Color.WHITE if has_flash else base

static func _grad(_y1: float, _y2: float, light: Color, dark: Color) -> Array:
	return [light, dark]

static func _draw_punch(node: CanvasItem, t: float) -> void:
	# t: 1.0 → 0.0
	var reach := 22.0 * sin(t * PI)
	var arm := PackedVector2Array([
		Vector2(8, -4), Vector2(18 + reach, -6),
		Vector2(18 + reach, 2), Vector2(8, 2),
	])
	A.shade_poly(node, arm, Color(0.98, 0.85, 0.7), Color(0.85, 0.68, 0.52))
	var col := Color(1, 1, 0.4, 180.0 / 255.0 * t)
	node.draw_arc(Vector2(14, -2), 14 + reach * 0.4, -1.1, 0.6, 16, col, 2.5, true)
	# linhas de velocidade do soco
	node.draw_line(Vector2(2, -10), Vector2(10 + reach, -12), Color(1, 1, 1, 0.4 * t), 1.2)
	node.draw_line(Vector2(2, 4), Vector2(10 + reach, 6), Color(1, 1, 1, 0.4 * t), 1.2)

# =====================================================================
#  GAREN — armadura pesada, escudo, crista
# =====================================================================
static func _garen(node: CanvasItem, _bob: int, flash: bool, t: float, moving: bool) -> void:
	var swing := int(sin(t) * 5.0) if moving else 0
	var armor := _f(flash, Color(0.275, 0.392, 0.706))
	var dark := A.mix(armor, Color.BLACK, 0.45)
	var edge := A.mix(armor, Color.BLACK, 0.65)

	A.shadow(node, 0, 13, 15, 5)

	# pernas + grevas
	for s in [1, -1]:
		var ox := 1 if s > 0 else -9
		var sw := swing if s > 0 else -swing
		A.shade_poly(node, PackedVector2Array([
			Vector2(ox, 2 + sw / 2.0), Vector2(ox + 8, 2 + sw / 2.0),
			Vector2(ox + 8, 16 + sw / 2.0), Vector2(ox, 16 + sw / 2.0),
		]), A.mix(armor, Color.WHITE, 0.1), dark)
		A.stroke(node, PackedVector2Array([
			Vector2(ox, 2 + sw / 2.0), Vector2(ox + 8, 2 + sw / 2.0),
			Vector2(ox + 8, 16 + sw / 2.0), Vector2(ox, 16 + sw / 2.0),
		]), edge, 1.3)
		node.draw_rect(Rect2(ox, 7 + sw / 2.0, 8, 3), A.mix(armor, Color.WHITE, 0.25))
		# botas
		A.shade_poly(node, PackedVector2Array([
			Vector2(ox - 2, 13 + sw / 2.0), Vector2(ox + 9, 13 + sw / 2.0),
			Vector2(ox + 9, 18 + sw / 2.0), Vector2(ox - 2, 18 + sw / 2.0),
		]), Color(0.27, 0.27, 0.33), Color(0.12, 0.12, 0.16))

	# fauldas
	A.shade_poly(node, PackedVector2Array([
		Vector2(-11, 4), Vector2(11, 4), Vector2(13, 12), Vector2(-13, 12),
	]), A.mix(armor, Color.BLACK, 0.15), A.mix(armor, Color.BLACK, 0.6))
	for lx in [-5, 0, 5]:
		node.draw_line(Vector2(lx, 5), Vector2(lx + (1 if lx > 0 else -1), 11),
			Color(0, 0, 0, 0.35), 1)

	# tronco
	var torso := PackedVector2Array([
		Vector2(-13, -13), Vector2(13, -13), Vector2(11, 7), Vector2(-11, 7),
	])
	A.shade_poly(node, torso, A.mix(armor, Color.WHITE, 0.35), dark)
	A.stroke(node, torso, edge, 1.5)
	node.draw_line(Vector2(0, -13), Vector2(0, 6), A.mix(armor, Color.BLACK, 0.5), 1)
	node.draw_arc(Vector2(0, 2), 7, 0, PI, 12, A.mix(armor, Color.BLACK, 0.3), 1)

	# peitoral dourado
	A.shade_ellipse(node, 0, -6, 5, 5, Color(1, 0.9, 0.47), Color(0.75, 0.59, 0.16))
	node.draw_arc(Vector2(0, -6), 5, 0, TAU, 16, Color(0.55, 0.43, 0.12), 1)

	# ombreiras
	for s in [1, -1]:
		var pts := PackedVector2Array([
			Vector2(s * 7, -16), Vector2(s * 17, -16),
			Vector2(s * 20, -7), Vector2(s * 10, -8),
		]) if s > 0 else PackedVector2Array([
			Vector2(-16, -16), Vector2(-6, -16), Vector2(-9, -8), Vector2(-19, -7),
		])
		A.shade_poly(node, pts, A.mix(armor, Color.WHITE, 0.4), dark)
		A.stroke(node, pts, edge, 1.4)

	# escudo (esquerda = x negativo)
	A.shade_poly(node, PackedVector2Array([
		Vector2(-22, -9), Vector2(-10, -9), Vector2(-10, 15), Vector2(-22, 15),
	]), Color(0.82, 0.27, 0.27), Color(0.47, 0.12, 0.12))
	A.stroke_rrect(node, -22, -9, 12, 24, 5, Color(0.86, 0.75, 0.24), 1.6)
	node.draw_rect(Rect2(-18, -9, 3, 24), Color(0.86, 0.75, 0.24))
	A.fill_ellipse(node, -16.5, 1.5, 3.5, 3.5, Color(0.86, 0.75, 0.24))

	# punho direito
	var fist := swing / 3.0
	A.shade_ellipse(node, 16, -1 + fist, 5.5, 5.5, A.mix(armor, Color.WHITE, 0.2), dark)
	node.draw_arc(Vector2(16, -1 + fist), 5.5, 0, TAU, 16, edge, 1.3)
	A.fill_ellipse(node, 16.5, -0.5 + fist, 2.5, 2.5, Color(0.86, 0.75, 0.24))

	# capacete + crista
	A.shade_ellipse(node, 0, -17, 10, 9, A.mix(armor, Color.WHITE, 0.45), dark)
	node.draw_arc(Vector2(0, -17), 10, PI, TAU, 16, edge, 1.5)
	A.shade_poly(node, PackedVector2Array([
		Vector2(-3, -24), Vector2(3, -24), Vector2(5, -34),
		Vector2(0, -37), Vector2(-5, -32),
	]), Color(0.9, 0.35, 0.35), Color(0.59, 0.16, 0.16))
	# chama da crista ao vento + reflexo varrendo o escudo
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(0, -37), Vector2(5, -34), Vector2(2 + sin(t * 3.0) * 2.0, -42),
	]), Color(0.95, 0.5, 0.4))
	var sweep := sin(t * 1.7) * 0.5 + 0.5
	node.draw_line(Vector2(-21, -6 + sweep * 18), Vector2(-12, -8 + sweep * 18),
		Color(1, 1, 1, 0.35), 1.5)
	# visor
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -17), Vector2(9, -17), Vector2(9, -11), Vector2(-8, -11),
	]), Color(0.06, 0.06, 0.1))
	node.draw_rect(Rect2(-5, -16, 4, 3), Color(0.47, 0.86, 1))
	node.draw_rect(Rect2(3, -16, 4, 3), Color(0.47, 0.86, 1))
	node.draw_rect(Rect2(-9, -12, 4, 6), A.mix(armor, Color.BLACK, 0.35))
	node.draw_rect(Rect2(5, -12, 4, 6), A.mix(armor, Color.BLACK, 0.35))

# =====================================================================
#  ZED — esguio, máscara, lâminas
# =====================================================================
static func _zed(node: CanvasItem, _bob: int, flash: bool, t: float, moving: bool) -> void:
	var swing := int(sin(t) * 5.0) if moving else 0
	var cloth := _f(flash, Color(0.196, 0.196, 0.255))
	var dark := A.mix(cloth, Color.BLACK, 0.55)
	var edge := A.mix(cloth, Color.BLACK, 0.75)

	A.shadow(node, 0, 13, 12, 4)

	# pernas
	for s in [1, -1]:
		var ox := 1 if s > 0 else -7
		var sw := swing if s > 0 else -swing
		A.shade_poly(node, PackedVector2Array([
			Vector2(ox, 2 + sw / 2.0), Vector2(ox + 6, 2 + sw / 2.0),
			Vector2(ox + 6, 15 + sw / 2.0), Vector2(ox, 15 + sw / 2.0),
		]), A.mix(cloth, Color.WHITE, 0.1), dark)
		A.stroke(node, PackedVector2Array([
			Vector2(ox, 2 + sw / 2.0), Vector2(ox + 6, 2 + sw / 2.0),
			Vector2(ox + 6, 15 + sw / 2.0), Vector2(ox, 15 + sw / 2.0),
		]), edge, 1.2)
		A.shade_poly(node, PackedVector2Array([
			Vector2(ox - 2, 12 + sw / 2.0), Vector2(ox + 7, 12 + sw / 2.0),
			Vector2(ox + 7, 17 + sw / 2.0), Vector2(ox - 2, 17 + sw / 2.0),
		]), Color(0.22, 0.22, 0.27), Color(0.08, 0.08, 0.11))

	# lâminas cruzadas nas costas
	node.draw_line(Vector2(-13, -17), Vector2(5, 5), Color(0.67, 0.69, 0.78), 2.4)
	node.draw_line(Vector2(13, -17), Vector2(-5, 5), Color(0.67, 0.69, 0.78), 2.4)
	node.draw_line(Vector2(-12, -16), Vector2(4, 3), Color(0.94, 0.96, 1, 0.7), 1)
	node.draw_line(Vector2(12, -16), Vector2(-4, 3), Color(0.94, 0.96, 1, 0.7), 1)

	# torso
	var torso := PackedVector2Array([
		Vector2(-9, -12), Vector2(9, -12), Vector2(7, 9), Vector2(-7, 9),
	])
	A.shade_poly(node, torso, A.mix(cloth, Color.WHITE, 0.22), A.mix(cloth, Color.BLACK, 0.5))
	A.stroke(node, torso, edge, 1.4)
	node.draw_rect(Rect2(-5, -8, 10, 3), Color(0.78, 0.16, 0.16))
	node.draw_rect(Rect2(-2, -3, 4, 9), Color(0.78, 0.16, 0.16))
	node.draw_rect(Rect2(-7, 5, 14, 4), Color(0.12, 0.12, 0.16))
	node.draw_rect(Rect2(-1, 6, 4, 3), Color(0.78, 0.16, 0.16))

	# ombreiras
	for pts in [
		PackedVector2Array([Vector2(-14, -14), Vector2(-5, -14), Vector2(-8, -7), Vector2(-17, -6)]),
		PackedVector2Array([Vector2(6, -14), Vector2(15, -14), Vector2(18, -6), Vector2(9, -7)]),
	]:
		A.shade_poly(node, pts, A.mix(cloth, Color.WHITE, 0.3), A.mix(cloth, Color.BLACK, 0.4))
		A.stroke(node, pts, edge, 1.2)

	# braços
	A.shade_ellipse(node, -11, 0, 4.5, 5, A.mix(cloth, Color.WHITE, 0.15), A.mix(cloth, Color.BLACK, 0.45))
	A.shade_ellipse(node, 11, 0, 4.5, 5, A.mix(cloth, Color.WHITE, 0.15), A.mix(cloth, Color.BLACK, 0.45))

	# lâmina na mão
	A.shade_poly(node, PackedVector2Array([
		Vector2(14, -6), Vector2(26, -12), Vector2(27, -9), Vector2(15, -2),
	]), Color(0.92, 0.94, 1), Color(0.55, 0.59, 0.69))
	A.stroke(node, PackedVector2Array([
		Vector2(14, -6), Vector2(26, -12), Vector2(27, -9), Vector2(15, -2),
	]), Color(0.35, 0.37, 0.47), 1)

	# máscara
	A.shade_ellipse(node, 0, -16, 8, 8, A.mix(cloth, Color.WHITE, 0.3), A.mix(cloth, Color.BLACK, 0.4))
	node.draw_arc(Vector2(0, -16), 8, 0, TAU, 20, Color(0.06, 0.06, 0.09), 1.4)
	node.draw_rect(Rect2(-2, -22, 4, 14), Color(0.75, 0.14, 0.14))
	# olhos
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -17), Vector2(-1, -16), Vector2(-1, -13), Vector2(-6, -14),
	]), Color(1, 0.24, 0.24))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(2, -16), Vector2(7, -17), Vector2(7, -15), Vector2(2, -13),
	]), Color(1, 0.24, 0.24))
	node.draw_rect(Rect2(-5, -16, 2, 2), Color(1, 0.71, 0.71))
	node.draw_rect(Rect2(3, -16, 2, 2), Color(1, 0.71, 0.71))
	# bico
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-3, -10), Vector2(3, -10), Vector2(0, -5),
	]), A.mix(cloth, Color.BLACK, 0.55))
	# rastro sombrio ao se mover
	if moving:
		node.draw_arc(Vector2(-14, 2), 12, -0.6, 0.8, 12, Color(0.4, 0.1, 0.6, 0.35), 3.0)
		node.draw_arc(Vector2(-20, 2), 16, -0.6, 0.8, 12, Color(0.4, 0.1, 0.6, 0.2), 2.0)

# =====================================================================
#  AHRI — caudas, manto, orbe
# =====================================================================
static func _ahri(node: CanvasItem, bob: int, flash: bool, t: float, moving: bool) -> void:
	var swing := int(sin(t) * 4.0) if moving else 0
	var robe := _f(flash, Color(0.55, 0.27, 0.75))
	var dark := A.mix(robe, Color.BLACK, 0.55)
	var edge := A.mix(robe, Color.BLACK, 0.7)

	A.shadow(node, 0, 13, 12, 4)

	# caudas
	for i in 4:
		var sway := sin(t * 0.7 + i * 1.3) * 7.0
		var tx := -14.0 - i * 5.0
		var ty := -6.0 + i * 5.0 + bob
		var lift := sway * 0.4
		A.shade_poly(node, PackedVector2Array([
			Vector2(tx, ty), Vector2(tx + 10, ty - 5 + lift),
			Vector2(tx + 18 + sway, ty + 2 + lift), Vector2(tx + 9, ty + 7),
		]), A.mix(Color(0.94, 0.75, 0.43), Color.WHITE, 0.15),
			A.mix(Color(0.78, 0.51, 0.24), Color.BLACK, 0.25))
		A.fill_ellipse(node, tx + 16 + sway, ty - 1 + lift, 4, 3.5, Color(1, 0.98, 0.94, 0.9))
		if i % 2 == 0:
			node.draw_colored_polygon(A.star_pts(tx + 16 + sway, ty - 6 + lift, 2.5),
				Color(1, 1, 1, 0.7))

	# pernas
	for s in [1, -1]:
		var ox := 1 if s > 0 else -6
		var sw := swing if s > 0 else -swing
		A.shade_poly(node, PackedVector2Array([
			Vector2(ox, 2 + sw / 2.0), Vector2(ox + 5, 2 + sw / 2.0),
			Vector2(ox + 5, 15 + sw / 2.0), Vector2(ox, 15 + sw / 2.0),
		]), A.mix(robe, Color.WHITE, 0.1), dark)
		A.fill_ellipse(node, ox + 2.5, 14 + sw / 2.0, 3.5, 2.5, Color(0.24, 0.1, 0.35))

	# manto
	var dress := PackedVector2Array([
		Vector2(-10, -12), Vector2(10, -12), Vector2(13, 15), Vector2(-13, 15),
	])
	A.shade_poly(node, dress, A.mix(robe, Color.WHITE, 0.35), dark)
	A.stroke(node, dress, edge, 1.4)
	node.draw_line(Vector2(-5, -4), Vector2(-8 + swing / 3.0, 13), Color(0, 0, 0, 0.35), 1)
	node.draw_line(Vector2(5, -4), Vector2(9 - swing / 3.0, 13), Color(0, 0, 0, 0.35), 1)
	node.draw_rect(Rect2(-9, 3, 18, 3), Color(0.9, 0.78, 0.35))
	A.fill_ellipse(node, 0, 5.5, 2.5, 2.5, Color(0.9, 0.78, 0.35))

	# ombreiras
	for pts in [
		PackedVector2Array([Vector2(-14, -13), Vector2(-5, -13), Vector2(-8, -7), Vector2(-16, -6)]),
		PackedVector2Array([Vector2(6, -13), Vector2(15, -13), Vector2(17, -6), Vector2(9, -7)]),
	]:
		A.shade_poly(node, pts, A.mix(robe, Color.WHITE, 0.4), A.mix(robe, Color.BLACK, 0.35))

	# braços
	A.shade_ellipse(node, -11, -2, 4, 4.5, A.mix(robe, Color.WHITE, 0.2), A.mix(robe, Color.BLACK, 0.45))
	A.shade_ellipse(node, 12, -2, 4, 4.5, A.mix(robe, Color.WHITE, 0.2), A.mix(robe, Color.BLACK, 0.45))

	# orbe
	var pulse := sin(t * 2.0) * 0.5 + 0.5
	var oy := -10.0 - swing / 4.0
	A.fill_ellipse(node, 23, oy + 4, 7.5, 7.5, Color(0.31, 0.78, 1, 0.35 + 0.3 * pulse))
	A.fill_ellipse(node, 23, oy + 4, 4.5, 4.5, Color(0.9, 0.98, 1, 0.85))
	A.fill_ellipse(node, 22, oy + 3, 2, 2, Color.WHITE)

	# cabelo atrás
	A.shade_poly(node, PackedVector2Array([
		Vector2(-9, -26), Vector2(9, -26), Vector2(10, -8), Vector2(-10, -8),
	]), Color(0.35, 0.18, 0.1), Color(0.18, 0.08, 0.05))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-9, -16), Vector2(-15, -8 + bob), Vector2(-12, 4 + bob), Vector2(-8, -6),
	]), Color(0.3, 0.14, 0.08))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(9, -16), Vector2(14, -10 - bob), Vector2(12, 2 - bob), Vector2(8, -6),
	]), Color(0.3, 0.14, 0.08))

	# rosto
	A.shade_ellipse(node, 0, -15.5, 7, 7.5, Color(0.98, 0.85, 0.7), Color(0.88, 0.71, 0.55))
	node.draw_arc(Vector2(0, -15.5), 7, 0, TAU, 20, Color(0.71, 0.51, 0.37), 1)

	# orelhas de raposa
	for s in [1, -1]:
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(s * 7, -18), Vector2(s * 12, -34), Vector2(s * 3, -22),
		]), A.mix(Color(0.82, 0.55, 0.27), Color.WHITE, 0.2))
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(s * 6, -21), Vector2(s * 9, -30), Vector2(s * 4, -23),
		]), Color(1, 0.75, 0.63))

	# franja
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -20), Vector2(8, -20), Vector2(6, -14),
		Vector2(2, -17), Vector2(-3, -14), Vector2(-6, -16),
	]), Color(0.4, 0.2, 0.11))

	# olhos
	for ex in [-3.5, 3.5]:
		A.fill_ellipse(node, ex, -14, 2, 2, Color(0.16, 0.78, 0.47))
		node.draw_rect(Rect2(ex - 1, -16, 1.5, 4), Color(0.08, 0.24, 0.16))
	node.draw_line(Vector2(-6, -18), Vector2(-1, -18), Color(0.27, 0.14, 0.08), 1.1)
	node.draw_line(Vector2(2, -18), Vector2(7, -18), Color(0.27, 0.14, 0.08), 1.1)
	node.draw_line(Vector2(-1, -11), Vector2(3, -11), Color(0.75, 0.43, 0.43), 1)

	# chapéu
	var hat := PackedVector2Array([
		Vector2(-9, -20), Vector2(9, -20), Vector2(7, -26),
		Vector2(2, -38), Vector2(-4, -34), Vector2(-8, -24),
	])
	A.shade_poly(node, hat, Color(0.43, 0.2, 0.69), Color(0.22, 0.08, 0.37))
	A.stroke(node, hat, Color(0.16, 0.06, 0.27), 1.3)
	A.fill_ellipse(node, 0, -21.5, 11, 3.5, Color(0.35, 0.16, 0.59))
	node.draw_colored_polygon(A.star_pts(1, -31, 4), Color(1, 0.9, 0.35))

# =====================================================================
#  ASHE — capuz, arco, aljava
# =====================================================================
static func _ashe(node: CanvasItem, _bob: int, flash: bool, t: float, moving: bool) -> void:
	var swing := int(sin(t) * 5.0) if moving else 0
	var leather := _f(flash, Color(0.196, 0.588, 0.314))
	var dark := A.mix(leather, Color.BLACK, 0.5)
	var edge := A.mix(leather, Color.BLACK, 0.7)

	A.shadow(node, 0, 13, 12, 4)

	# pernas + botas
	for s in [1, -1]:
		var ox := 1 if s > 0 else -6
		var sw := swing if s > 0 else -swing
		A.shade_poly(node, PackedVector2Array([
			Vector2(ox, 2 + sw / 2.0), Vector2(ox + 5, 2 + sw / 2.0),
			Vector2(ox + 5, 14 + sw / 2.0), Vector2(ox, 14 + sw / 2.0),
		]), A.mix(leather, Color.WHITE, 0.1), dark)
		A.shade_poly(node, PackedVector2Array([
			Vector2(ox - 2, 11 + sw / 2.0), Vector2(ox + 6, 11 + sw / 2.0),
			Vector2(ox + 6, 17 + sw / 2.0), Vector2(ox - 2, 17 + sw / 2.0),
		]), Color(0.35, 0.24, 0.14), Color(0.18, 0.11, 0.06))
		node.draw_rect(Rect2(ox - 1, 12 + sw / 2.0, 6, 2), Color(0.82, 0.75, 0.35))

	# aljava
	A.shade_poly(node, PackedVector2Array([
		Vector2(-15, -16), Vector2(-8, -16), Vector2(-8, 4), Vector2(-15, 4),
	]), Color(0.47, 0.33, 0.18), Color(0.27, 0.18, 0.08))
	A.stroke_rrect(node, -15, -16, 7, 20, 3, Color(0.2, 0.12, 0.05), 1.2)
	for i in 3:
		var ax := -13.0 + i * 2
		node.draw_line(Vector2(ax, -16), Vector2(ax + 2, -25), Color(0.75, 0.75, 0.77), 1.4)
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -25), Vector2(-10, -25), Vector2(-11, -29),
	]), Color(0.86, 0.31, 0.31))

	# torso
	var torso := PackedVector2Array([
		Vector2(-9, -13), Vector2(9, -13), Vector2(7, 7), Vector2(-7, 7),
	])
	A.shade_poly(node, torso, A.mix(leather, Color.WHITE, 0.3), dark)
	A.stroke(node, torso, edge, 1.4)
	for lx in [-5, 0, 5]:
		node.draw_line(Vector2(lx, -11), Vector2(lx, 5), A.mix(leather, Color.BLACK, 0.4), 1)
	A.shade_poly(node, PackedVector2Array([
		Vector2(-8, 3), Vector2(8, 3), Vector2(8, 8), Vector2(-8, 8),
	]), Color(0.55, 0.37, 0.2), Color(0.33, 0.22, 0.1))
	node.draw_rect(Rect2(-2, 4, 5, 4), Color(0.82, 0.75, 0.39))

	# peliço
	A.shade_poly(node, PackedVector2Array([
		Vector2(-11, -14), Vector2(11, -14), Vector2(9, -4), Vector2(-9, -4),
	]), A.mix(leather, Color.WHITE, 0.2), A.mix(leather, Color.BLACK, 0.45))

	# ombreiras
	for pts in [
		PackedVector2Array([Vector2(-14, -14), Vector2(-5, -14), Vector2(-8, -7), Vector2(-16, -6)]),
		PackedVector2Array([Vector2(6, -14), Vector2(15, -14), Vector2(17, -6), Vector2(9, -7)]),
	]:
		A.shade_poly(node, pts, A.mix(leather, Color.WHITE, 0.35), A.mix(leather, Color.BLACK, 0.35))
		A.stroke(node, pts, edge, 1.2)

	# braços
	A.shade_ellipse(node, -10, -2, 4, 4.5, A.mix(leather, Color.WHITE, 0.15), A.mix(leather, Color.BLACK, 0.45))
	A.shade_ellipse(node, 11, -2, 4, 4.5, A.mix(leather, Color.WHITE, 0.15), A.mix(leather, Color.BLACK, 0.45))
	node.draw_rect(Rect2(8, -3 - swing / 4.0, 7, 3), Color(0.47, 0.33, 0.18))

	# arco
	var bow := PackedVector2Array()
	for i in 13:
		var a := -1.1 + 2.2 * i / 12.0
		bow.append(Vector2(18 + cos(a) * 10, -2 + sin(a) * 18))
	A.stroke(node, bow, Color(0.71, 0.51, 0.27), 3, false)
	A.stroke(node, bow, Color(0.4, 0.26, 0.12), 1, false)
	node.draw_line(Vector2(22, -10), Vector2(22, 14), Color(0.92, 0.92, 0.84, 0.9), 1.1)
	A.fill_rrect(node, 20, -4, 4, 10, 2, Color(0.24, 0.16, 0.08))
	# flecha engatilhada
	node.draw_line(Vector2(8, 2), Vector2(24, 2), Color(0.8, 0.65, 0.4), 1.6)
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(24, 2), Vector2(29, 0), Vector2(29, 4),
	]), Color(0.9, 0.9, 0.95))

	# capuz
	var hood := PackedVector2Array([
		Vector2(-9, -10), Vector2(9, -10), Vector2(8, -20),
		Vector2(4, -26), Vector2(-4, -26), Vector2(-8, -18),
	])
	A.shade_poly(node, hood, A.mix(leather, Color.WHITE, 0.3), A.mix(leather, Color.BLACK, 0.5))
	A.stroke(node, hood, edge, 1.4)
	A.fill_ellipse(node, 0, -15.5, 6.5, 5.5, Color(0.07, 0.22, 0.13))

	# rosto parcial
	A.shade_ellipse(node, 0, -13.5, 5.5, 4.5, Color(0.97, 0.84, 0.69), Color(0.87, 0.7, 0.55))
	for ex in [-2, 3]:
		A.fill_ellipse(node, ex, -14, 2, 1.5, Color(0.35, 0.82, 1))
		node.draw_rect(Rect2(ex - 0.5, -15, 1, 3), Color(0.08, 0.24, 0.35))
	node.draw_line(Vector2(-1, -10), Vector2(3, -10), Color(0.75, 0.51, 0.47), 1)

# =====================================================================
#  JANNA — vestido, cajado, halo, asas
# =====================================================================
static func _janna(node: CanvasItem, bob: int, flash: bool, t: float, moving: bool) -> void:
	var swing := int(sin(t) * 4.0) if moving else 0
	var gown := _f(flash, Color(0.275, 0.667, 0.667))
	var dark := A.mix(gown, Color.BLACK, 0.5)
	var edge := A.mix(gown, Color.BLACK, 0.65)

	A.shadow(node, 0, 13, 12, 4)

	# asas
	var wing_flap := int(sin(t * 1.2) * 5.0)
	for s in [1, -1]:
		var f := -wing_flap if s > 0 else wing_flap
		var wing := PackedVector2Array([
			Vector2(s * 5, -14 + f + bob), Vector2(s * 16, -28 + f + bob),
			Vector2(s * 26, -32 + f + bob), Vector2(s * 30, -14 + f + bob),
			Vector2(s * 24, -4 + f + bob), Vector2(s * 12, 2 + bob), Vector2(s * 7, -4 + bob),
		])
		node.draw_colored_polygon(wing, Color(0.78, 0.9, 1, 0.35))
		node.draw_line(Vector2(s * 7, -12 + bob), Vector2(s * 26, -28 + f + bob),
			Color(1, 1, 1, 0.4), 1)
		node.draw_line(Vector2(s * 8, -8 + bob), Vector2(s * 26, -14 + f + bob),
			Color(1, 1, 1, 0.4), 1)

	# véu traseiro
	A.shade_poly(node, PackedVector2Array([
		Vector2(-9, -4), Vector2(9, -4), Vector2(14 + swing / 3.0, 16), Vector2(-14 + swing / 3.0, 16),
	]), A.mix(gown, Color.WHITE, 0.15), A.mix(gown, Color.BLACK, 0.5))

	# vestido
	var dress := PackedVector2Array([
		Vector2(-9, -12), Vector2(9, -12), Vector2(13, 16), Vector2(-13, 16),
	])
	A.shade_poly(node, dress, A.mix(gown, Color.WHITE, 0.4), dark)
	A.stroke(node, dress, edge, 1.4)
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-11, 8), Vector2(11, 8), Vector2(13, 16), Vector2(-13, 16),
	]), A.mix(gown, Color.WHITE, 0.25))
	node.draw_line(Vector2(-4, -6), Vector2(-8 + swing / 3.0, 14), Color(1, 1, 1, 0.3), 1)
	node.draw_line(Vector2(4, -6), Vector2(8 - swing / 3.0, 14), Color(1, 1, 1, 0.3), 1)
	node.draw_rect(Rect2(-8, 2, 16, 3), Color(0.94, 0.86, 0.51))

	# braços
	A.shade_ellipse(node, -11, -2, 3.5, 4, A.mix(gown, Color.WHITE, 0.2), A.mix(gown, Color.BLACK, 0.4))
	A.shade_ellipse(node, 11, -2, 3.5, 4, A.mix(gown, Color.WHITE, 0.2), A.mix(gown, Color.BLACK, 0.4))

	# cajado
	node.draw_line(Vector2(15, -22), Vector2(15, 14), Color(0.75, 0.61, 0.37), 2.6)
	node.draw_line(Vector2(15, -22), Vector2(15, 14), Color(0.43, 0.33, 0.18), 1.2)
	var gem_pulse := sin(t * 2.5) * 0.5 + 0.5
	A.fill_ellipse(node, 15, -25, 6.5, 6.5, Color(0.39, 0.78, 1, 0.4 + 0.35 * gem_pulse))
	A.fill_ellipse(node, 15, -25, 3.5, 3.5, Color(0.94, 0.99, 1, 0.9))
	var orb_a := t * 2.0
	A.fill_ellipse(node, 15 + cos(orb_a) * 7, -25 + sin(orb_a) * 7, 1.5, 1.5, Color(1, 1, 1, 0.85))

	# halo
	var halo_glow := sin(t * 1.5) * 0.5 + 0.5
	node.draw_arc(Vector2(0, -29), 7, 0, TAU, 20,
		Color(1, 1, 0.75, 0.65 + 0.3 * halo_glow), 2.2)

	# cabelo
	A.shade_poly(node, PackedVector2Array([
		Vector2(-9, -26), Vector2(9, -26), Vector2(10, -8), Vector2(-10, -8),
	]), Color(0.98, 0.91, 0.59), Color(0.78, 0.67, 0.35))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-9, -16), Vector2(-14, -6 + bob), Vector2(-11, 6 + bob), Vector2(-8, -8),
	]), Color(0.9, 0.82, 0.45))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(9, -16), Vector2(14, -8 - bob), Vector2(12, 4 - bob), Vector2(8, -8),
	]), Color(0.9, 0.82, 0.45))
	node.draw_line(Vector2(-6, -24), Vector2(4, -22), Color(1, 0.98, 0.82, 0.7), 1.2)

	# rosto
	A.shade_ellipse(node, 0, -15.5, 6, 6.5, Color(0.98, 0.87, 0.75), Color(0.89, 0.74, 0.61))
	node.draw_arc(Vector2(0, -15.5), 6, 0, TAU, 18, Color(0.75, 0.59, 0.47), 1)

	for ex in [-2, 3]:
		A.fill_ellipse(node, ex, -14, 2, 2, Color(0.27, 0.59, 0.9))
		node.draw_rect(Rect2(ex - 0.5, -16, 1.2, 4), Color(0.1, 0.2, 0.35))
		A.fill_ellipse(node, ex - 0.5, -15, 0.6, 0.6, Color.WHITE)
	node.draw_line(Vector2(-1, -11), Vector2(3, -11), Color(0.78, 0.47, 0.47), 1)
	# penas orbitando
	for i in 2:
		var fa := t * 1.8 + i * PI
		A.fill_ellipse(node, cos(fa) * 22, -16 + sin(fa) * 8, 2.5, 1.5,
			Color(1, 1, 1, 0.7))
