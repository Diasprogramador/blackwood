class_name EnemyArt
extends Object

## Port do EnemyDesigner.java para Godot _draw().
## Desenha voltado para a direita; flip via scale.x do chamador.

static var A = ArtUtil

static func draw_enemy(node: CanvasItem, type: String, base: Color, flash: bool,
		walk_phase: float, moving: bool) -> void:
	var c := Color.WHITE if flash else base
	var bob := int(sin(walk_phase) * (3.0 if moving else 1.5))
	var t := walk_phase
	match type:
		"MINION": _minion(node, c, bob, t)
		"CASTER": _caster(node, c, bob, t)
		"GOLEM": _golem(node, c, bob, t)
		"DRAGON": _dragon(node, c, bob, t)
		"BARON": _baron(node, c, bob, t)
		"JUNGLE": _jungle(node, c, bob, t)
	# aura de elite (chefões dropam mais ouro)
	if type == "DRAGON" or type == "BARON":
		var pulse := sin(t * 2.0) * 0.5 + 0.5
		A.fill_ellipse(node, 0, 14, 26, 8, Color(1, 0.3, 0.2, 0.12 + 0.1 * pulse))
		node.draw_arc(Vector2(0, 14), 24, 0, TAU, 28,
			Color(1, 0.45, 0.2, 0.4 + 0.25 * pulse), 2.0)

# ---------------------------------------------------------------------
static func _minion(node: CanvasItem, skin: Color, bob: int, t: float) -> void:
	var swing := int(sin(t) * 4.0)
	var limb := A.mix(skin, Color.BLACK, 0.35)

	A.shadow(node, 0, 11, 12, 4)

	# pernas
	for s in [1, -1]:
		var ox := 2 if s > 0 else -8
		var sw := -swing if s > 0 else swing
		A.shade_poly(node, PackedVector2Array([
			Vector2(ox, 4 + sw / 2.0), Vector2(ox + 6, 4 + sw / 2.0),
			Vector2(ox + 6, 14 + sw / 2.0), Vector2(ox, 14 + sw / 2.0),
		]), A.mix(limb, Color.WHITE, 0.15), A.mix(limb, Color.BLACK, 0.4))
		A.fill_ellipse(node, ox + 3, 13 + sw / 2.0, 5, 2.5, A.mix(limb, Color.BLACK, 0.5))

	# braço traseiro
	A.fill_ellipse(node, -11, -1 + bob, 4, 4.5, limb)

	# tronco corcundo
	A.shade_ellipse(node, 0, 2 + bob, 11.5, 11.5,
		A.mix(skin, Color.WHITE, 0.28), A.mix(skin, Color.BLACK, 0.5))
	node.draw_arc(Vector2(0, 2 + bob), 11.5, 0, TAU, 24, A.mix(skin, Color.BLACK, 0.7), 1.3)
	A.fill_ellipse(node, 1, 5 + bob, 6.5, 6.5, A.mix(skin, Color(1, 0.9, 0.75), 0.45))

	# orelha traseira
	_ear(node, -12, -16 + bob, skin)

	# cabeça
	A.shade_ellipse(node, 1, -15 + bob, 10.5, 9.5,
		A.mix(skin, Color.WHITE, 0.32), A.mix(skin, Color.BLACK, 0.35))
	node.draw_arc(Vector2(1, -15 + bob), 10.5, 0, TAU, 22, A.mix(skin, Color.BLACK, 0.7), 1.3)
	_ear(node, 9, -18 + bob, skin)

	# maxilar
	A.fill_ellipse(node, 4, -8 + bob, 7.5, 4.5, A.mix(skin, Color.BLACK, 0.45))
	node.draw_arc(Vector2(4, -9 + bob), 6.5, 0, PI, 12, Color(0.16, 0.06, 0.06), 1.5)
	# presas
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(2, -9 + bob), Vector2(5, -9 + bob), Vector2(3, -4 + bob),
	]), Color(0.96, 0.94, 0.86))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(8, -9 + bob), Vector2(11, -9 + bob), Vector2(9, -5 + bob),
	]), Color(0.96, 0.94, 0.86))

	# sobrancelha + olho
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(0, -17 + bob), Vector2(10, -19 + bob),
		Vector2(10, -16 + bob), Vector2(1, -14 + bob),
	]), A.mix(skin, Color.BLACK, 0.6))
	A.fill_ellipse(node, 5, -15 + bob, 2.5, 2, Color(1, 0.86, 0.24))
	A.fill_ellipse(node, 6, -15 + bob, 1, 1.5, Color(0.08, 0.04, 0.02))

	# chifre
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -22 + bob), Vector2(-3, -23 + bob), Vector2(-5, -28 + bob),
	]), Color(0.9, 0.86, 0.78))

	# braço dianteiro + garras
	var sw2 := swing / 2.0
	A.fill_ellipse(node, 12, 0 + bob + sw2, 4.5, 4.5, limb)
	for i in 2:
		var gy := 3 + i * 3 + bob + sw2
		node.draw_line(Vector2(15, gy), Vector2(19, gy + 2), Color(0.92, 0.9, 0.82), 1.2)

	A.fill_ellipse(node, 1, -15 + bob, 10.5, 9.5, Color(1, 1, 1, 0.08))

static func _ear(node: CanvasItem, x: float, y: float, skin: Color) -> void:
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(x, y), Vector2(x - 6, y - 14), Vector2(x + 4, y - 4),
	]), A.mix(skin, Color.WHITE, 0.2))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(x, y - 2), Vector2(x - 3, y - 10), Vector2(x + 2, y - 4),
	]), A.mix(skin, Color(1, 0.6, 0.6), 0.5))

# ---------------------------------------------------------------------
static func _caster(node: CanvasItem, robe: Color, bob: int, t: float) -> void:
	var sway := int(sin(t * 0.8) * 2.0)

	A.shadow(node, 0, 12, 11, 4)

	# cauda do manto
	A.shade_poly(node, PackedVector2Array([
		Vector2(-9, -2), Vector2(9, -2), Vector2(13 + sway, 15), Vector2(-13 + sway, 15),
	]), A.mix(robe, Color.BLACK, 0.2), A.mix(robe, Color.BLACK, 0.6))

	# manto
	var body := PackedVector2Array([
		Vector2(-8, -14), Vector2(8, -14), Vector2(12, 14), Vector2(-12, 14),
	])
	A.shade_poly(node, body, A.mix(robe, Color.WHITE, 0.3), A.mix(robe, Color.BLACK, 0.55))
	A.stroke(node, body, A.mix(robe, Color.BLACK, 0.7), 1.3)
	node.draw_line(Vector2(-3, -6), Vector2(-5 + sway, 12), Color(0, 0, 0, 0.3), 1)
	node.draw_line(Vector2(3, -6), Vector2(5 + sway, 12), Color(0, 0, 0, 0.3), 1)

	# cinto
	node.draw_rect(Rect2(-8, -1, 16, 4), A.mix(robe, Color.BLACK, 0.65))
	node.draw_rect(Rect2(-1, 0, 4, 3), Color(0.86, 0.71, 0.27))

	# braço
	A.shade_ellipse(node, 11, -3, 6, 5.5, A.mix(robe, Color.WHITE, 0.15), A.mix(robe, Color.BLACK, 0.4))

	# capuz
	A.shade_ellipse(node, 0, -15, 10, 11, A.mix(robe, Color.WHITE, 0.35), A.mix(robe, Color.BLACK, 0.5))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -14), Vector2(-2, -22), Vector2(-6, -30), Vector2(-13, -20),
	]), A.mix(robe, Color.WHITE, 0.25))
	node.draw_arc(Vector2(0, -15), 10, PI * 0.85, PI * 2.15, 18, A.mix(robe, Color.BLACK, 0.7), 1.3)

	# véu + olhos
	A.fill_ellipse(node, 0, -12 + bob, 6.5, 6, Color(0.03, 0.02, 0.06))
	var glow := sin(t * 2.0) * 0.5 + 0.5
	var eye := Color(0.47, 0.9, 1, 0.65 + 0.35 * glow)
	A.fill_ellipse(node, -2.5, -12 + bob, 2, 1.5, eye)
	A.fill_ellipse(node, 3, -12 + bob, 2, 1.5, eye)

	# cajado
	node.draw_line(Vector2(15, -20), Vector2(15, 13), Color(0.37, 0.25, 0.14), 2.4)
	var pulse := sin(t * 2.5) * 0.5 + 0.5
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(10, -22), Vector2(18, -22), Vector2(14, -30),
	]), Color(1, 0.63, 0.24, 0.6 + 0.4 * pulse))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(12, -23), Vector2(16, -23), Vector2(14, -27),
	]), Color(1, 0.94, 0.78, 0.7 + 0.3 * pulse))

	# orbe flutuante
	var orb_y := -6.0 + sin(t * 1.5) * 3.0
	A.fill_ellipse(node, 24, orb_y + 5, 6, 6, Color(1, 0.67, 0.27, 0.35))
	A.fill_ellipse(node, 24, orb_y + 5, 3.5, 3.5, Color(1, 0.92, 0.7, 0.9))
	# círculo rúnico sob os pés
	node.draw_arc(Vector2(0, 13), 12, 0, TAU, 20,
		Color(1, 0.6, 0.2, 0.3 + 0.2 * pulse), 1.2)

# ---------------------------------------------------------------------
static func _golem(node: CanvasItem, rock: Color, bob: int, t: float) -> void:
	var swing := int(sin(t) * 3.0)
	var edge := A.mix(rock, Color.BLACK, 0.7)

	A.shadow(node, 0, 13, 16, 5)

	# pernas
	for s in [1, -1]:
		var ox := 2 if s > 0 else -11
		var sw := -swing / 2.0 if s > 0 else swing / 2.0
		A.shade_poly(node, PackedVector2Array([
			Vector2(ox, 2 + sw), Vector2(ox + 10, 2 + sw),
			Vector2(ox + 10, 15 + sw), Vector2(ox, 15 + sw),
		]), A.mix(rock, Color.WHITE, 0.15), A.mix(rock, Color.BLACK, 0.5))
		A.stroke(node, PackedVector2Array([
			Vector2(ox, 2 + sw), Vector2(ox + 10, 2 + sw),
			Vector2(ox + 10, 15 + sw), Vector2(ox, 15 + sw),
		]), A.mix(rock, Color.BLACK, 0.65), 1.4)

	# braço traseiro
	A.shade_poly(node, PackedVector2Array([
		Vector2(-20, -10 + bob), Vector2(-11, -10 + bob),
		Vector2(-11, 10 + bob), Vector2(-20, 10 + bob),
	]), A.mix(rock, Color.WHITE, 0.1), A.mix(rock, Color.BLACK, 0.55))

	# tronco
	var torso := PackedVector2Array([
		Vector2(-14, -16), Vector2(14, -16), Vector2(12, 6), Vector2(-12, 6),
	])
	A.shade_poly(node, torso, A.mix(rock, Color.WHITE, 0.25), A.mix(rock, Color.BLACK, 0.55))
	A.stroke(node, torso, edge, 1.6)
	# rachaduras
	node.draw_line(Vector2(-6, -14), Vector2(-2, -4), Color(0, 0, 0, 0.55), 1.2)
	node.draw_line(Vector2(-2, -4), Vector2(-6, 2), Color(0, 0, 0, 0.55), 1.2)
	node.draw_line(Vector2(7, -12), Vector2(4, -2), Color(0, 0, 0, 0.55), 1.2)
	# musgo
	A.fill_ellipse(node, -6, -12, 6, 3.5, Color(0.27, 0.51, 0.24, 0.55))
	A.fill_ellipse(node, 6, -13, 5, 3, Color(0.27, 0.51, 0.24, 0.55))
	# runa no peito
	var rune := sin(t * 1.2) * 0.5 + 0.5
	A.fill_ellipse(node, 0, -4, 3, 4, Color(0.5, 0.9, 1, 0.35 + 0.35 * rune))

	# ombreiras
	for pts in [
		PackedVector2Array([Vector2(-15, -17), Vector2(-6, -17), Vector2(-8, -10), Vector2(-17, -9)]),
		PackedVector2Array([Vector2(7, -17), Vector2(16, -17), Vector2(18, -9), Vector2(9, -10)]),
	]:
		A.shade_poly(node, pts, A.mix(rock, Color.WHITE, 0.35), A.mix(rock, Color.BLACK, 0.3))
		A.stroke(node, pts, edge, 1.3)

	# cabeça
	var head := PackedVector2Array([
		Vector2(-7, -24 + bob), Vector2(8, -24 + bob),
		Vector2(8, -11 + bob), Vector2(-7, -11 + bob),
	])
	A.shade_poly(node, head, A.mix(rock, Color.WHITE, 0.3), A.mix(rock, Color.BLACK, 0.35))
	A.stroke(node, head, edge, 1.4)

	# olhos de lava
	var glow := sin(t * 1.8) * 0.5 + 0.5
	var lava := Color(1, 0.67, 0.16, 0.75 + 0.25 * glow)
	node.draw_rect(Rect2(-4, -19 + bob, 4, 3), lava)
	node.draw_rect(Rect2(2, -19 + bob, 4, 3), lava)
	node.draw_rect(Rect2(-3, -19 + bob, 2, 2), Color(1, 0.94, 0.63, 0.9))
	node.draw_rect(Rect2(3, -19 + bob, 4, 3), Color(1, 0.94, 0.63, 0.3))

	# punho dianteiro
	var fist := PackedVector2Array([
		Vector2(12, -6 + bob + swing), Vector2(26, -6 + bob + swing),
		Vector2(26, 10 + bob + swing), Vector2(12, 10 + bob + swing),
	])
	A.shade_poly(node, fist, A.mix(rock, Color.WHITE, 0.2), A.mix(rock, Color.BLACK, 0.5))
	A.stroke(node, fist, edge, 1.5)
	for i in 2:
		for j in 2:
			A.fill_ellipse(node, 16 + i * 6, -4 + j * 6 + bob + swing, 2, 2,
				A.mix(rock, Color.BLACK, 0.45))

# ---------------------------------------------------------------------
static func _dragon(node: CanvasItem, scale_c: Color, bob: int, t: float) -> void:
	var wing := int(sin(t * 1.4) * 8.0)
	var swing := int(sin(t) * 4.0)

	A.shadow(node, 0, 16, 18, 6)

	# cauda
	A.shade_poly(node, PackedVector2Array([
		Vector2(-12, 2 + bob), Vector2(-30, -4 + bob + swing / 2.0),
		Vector2(-34, 8 + bob), Vector2(-14, 10 + bob),
	]), A.mix(scale_c, Color.WHITE, 0.1), A.mix(scale_c, Color.BLACK, 0.45))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-28, -4 + bob + swing / 2.0), Vector2(-34, -2 + bob + swing / 2.0),
		Vector2(-30, -10 + bob + swing / 2.0),
	]), A.mix(scale_c, Color.BLACK, 0.3))

	# perna traseira
	A.shade_poly(node, PackedVector2Array([
		Vector2(-10, 2 + bob - swing / 2.0), Vector2(-1, 2 + bob - swing / 2.0),
		Vector2(-1, 15 + bob - swing / 2.0), Vector2(-10, 15 + bob - swing / 2.0),
	]), A.mix(scale_c, Color.WHITE, 0.15), A.mix(scale_c, Color.BLACK, 0.5))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(-11, 14 + bob - swing / 2.0), Vector2(-6, 14 + bob - swing / 2.0),
		Vector2(-8, 18 + bob - swing / 2.0),
	]), Color(0.92, 0.88, 0.75))

	# asa traseira
	var wing_back := PackedVector2Array([
		Vector2(-6, -2 + bob), Vector2(-26, -34 + wing + bob),
		Vector2(-34, -8 + bob), Vector2(-16, 6 + bob), Vector2(-4, 8 + bob),
	])
	A.shade_poly(node, wing_back, A.mix(scale_c, Color.BLACK, 0.15), A.mix(scale_c, Color.BLACK, 0.55))
	A.stroke(node, wing_back, A.mix(scale_c, Color.BLACK, 0.5), 1.2)

	# tronco
	A.shade_ellipse(node, 1, 1 + bob, 15, 13,
		A.mix(scale_c, Color.WHITE, 0.3), A.mix(scale_c, Color.BLACK, 0.5))
	node.draw_arc(Vector2(1, 1 + bob), 15, 0, TAU, 24, A.mix(scale_c, Color.BLACK, 0.7), 1.6)

	# ventre
	A.fill_ellipse(node, 4, 4 + bob, 8, 8.5, A.mix(scale_c, Color(1, 0.92, 0.7), 0.65))
	for i in 4:
		node.draw_arc(Vector2(4, 1 + i * 4 + bob), 6, 0, PI, 10, Color(0, 0, 0, 0.3), 1)

	# asa dianteira
	var wing_front := PackedVector2Array([
		Vector2(-4, -8 + bob), Vector2(-20, -40 + wing + bob),
		Vector2(-38, -30 + wing + bob), Vector2(-44, -4 + bob),
		Vector2(-24, 8 + bob), Vector2(-2, 6 + bob),
	])
	A.shade_poly(node, wing_front, A.mix(scale_c, Color.WHITE, 0.05), A.mix(scale_c, Color.BLACK, 0.5))
	A.stroke(node, wing_front, A.mix(scale_c, Color.BLACK, 0.55), 1.2)
	node.draw_line(Vector2(-4, -8 + bob), Vector2(-20, -40 + wing + bob), Color(0, 0, 0, 0.35), 1)
	node.draw_line(Vector2(-4, -6 + bob), Vector2(-38, -30 + wing + bob), Color(0, 0, 0, 0.35), 1)

	# pescoço
	A.shade_poly(node, PackedVector2Array([
		Vector2(6, -6 + bob), Vector2(16, -24 + bob),
		Vector2(20, -22 + bob), Vector2(8, 2 + bob),
	]), A.mix(scale_c, Color.WHITE, 0.25), A.mix(scale_c, Color.BLACK, 0.4))

	# cabeça
	A.shade_ellipse(node, 18, -26 + bob, 11, 8,
		A.mix(scale_c, Color.WHITE, 0.35), A.mix(scale_c, Color.BLACK, 0.35))
	A.shade_poly(node, PackedVector2Array([
		Vector2(24, -30 + bob), Vector2(36, -28 + bob),
		Vector2(34, -22 + bob), Vector2(22, -20 + bob),
	]), A.mix(scale_c, Color.WHITE, 0.3), A.mix(scale_c, Color.BLACK, 0.4))
	node.draw_arc(Vector2(18, -26 + bob), 11, 0, TAU, 20, A.mix(scale_c, Color.BLACK, 0.7), 1.5)

	# chifres
	for hp in [Vector2(14, -34), Vector2(20, -34)]:
		node.draw_colored_polygon(PackedVector2Array([
			hp, hp + Vector2(4, -1), hp + Vector2(-2, -12),
		]), Color(0.92, 0.88, 0.78))

	# mandíbula + dentes
	A.shade_poly(node, PackedVector2Array([
		Vector2(22, -24 + bob), Vector2(35, -23 + bob),
		Vector2(33, -18 + bob), Vector2(22, -19 + bob),
	]), A.mix(scale_c, Color.BLACK, 0.3), A.mix(scale_c, Color.BLACK, 0.5))
	for i in 3:
		var dx := 25.0 + i * 5
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(dx, -23 + bob), Vector2(dx + 2, -23 + bob), Vector2(dx + 1, -19 + bob),
		]), Color(0.98, 0.96, 0.88))

	# olho
	var glow := sin(t * 3.0) * 0.5 + 0.5
	A.fill_ellipse(node, 20, -28 + bob, 3, 2.5, Color(1, 0.78, 0.2, 0.8 + 0.2 * glow))
	node.draw_rect(Rect2(21, -30 + bob, 1.5, 4), Color(0.12, 0.04, 0.02))

	# perna dianteira
	A.shade_poly(node, PackedVector2Array([
		Vector2(6, 2 + bob + swing), Vector2(15, 2 + bob + swing),
		Vector2(15, 15 + bob + swing), Vector2(6, 15 + bob + swing),
	]), A.mix(scale_c, Color.WHITE, 0.2), A.mix(scale_c, Color.BLACK, 0.5))
	for i in 2:
		var cx := 7.0 + i * 5
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(cx, 15 + bob + swing), Vector2(cx + 4, 15 + bob + swing),
			Vector2(cx + 1, 20 + bob + swing),
		]), Color(0.92, 0.88, 0.75))

	# espinhos dorsais
	for i in 3:
		var bx := -8 + i * 7
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(bx, -11 + bob), Vector2(bx + 4, -18 + bob), Vector2(bx + 6, -11 + bob),
		]), A.mix(scale_c, Color.BLACK, 0.45))

# ---------------------------------------------------------------------
static func _baron(node: CanvasItem, flesh: Color, bob: int, t: float) -> void:
	var sway := int(sin(t * 0.7) * 3.0)

	A.shadow(node, 0, 18, 24, 7)

	# tentáculos
	for i in 3:
		var ty := -4.0 + i * 8.0 + bob
		var pts := PackedVector2Array()
		for k in 6:
			var u := k / 5.0
			pts.append(Vector2(-18 - u * 16 - i * 3,
				ty + sin(t + i + u * 2.5) * 6 * u + sway * u))
		A.stroke(node, pts, A.mix(flesh, Color.BLACK, 0.45), 3 - i * 0.5, false)

	# segmentos
	for i in 3:
		var cx := -14.0 - i * 9.0
		var r := 22.0 - i * 4.0
		A.shade_ellipse(node, cx, bob + i * 2, r, r,
			A.mix(flesh, Color.WHITE, 0.3), A.mix(flesh, Color.BLACK, 0.55))
		node.draw_arc(Vector2(cx, bob + i * 2), r, 0, TAU, 24, A.mix(flesh, Color.BLACK, 0.75), 1.6)
		node.draw_arc(Vector2(cx, bob + i * 2), r - 5, 0, TAU, 20, Color(0, 0, 0, 0.35), 1.4)

	# cabeça
	A.shade_ellipse(node, 13, bob, 17, 21,
		A.mix(flesh, Color.WHITE, 0.38), A.mix(flesh, Color.BLACK, 0.45))
	node.draw_arc(Vector2(13, bob), 21, 0, TAU, 28, A.mix(flesh, Color.BLACK, 0.8), 1.8)

	# chifres
	var horn := A.mix(flesh, Color(0.94, 0.9, 0.82), 0.6)
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(0, -20 + bob), Vector2(6, -22 + bob), Vector2(-2, -40 + bob),
	]), horn)
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(12, -20 + bob), Vector2(18, -22 + bob), Vector2(14, -38 + bob),
	]), horn)
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(22, -16 + bob), Vector2(28, -18 + bob), Vector2(26, -32 + bob),
	]), horn)

	# mandíbula
	A.shade_poly(node, PackedVector2Array([
		Vector2(12, 4 + bob), Vector2(34, 6 + bob),
		Vector2(30, 18 + bob), Vector2(10, 16 + bob),
	]), A.mix(flesh, Color.BLACK, 0.55), A.mix(flesh, Color.BLACK, 0.7))
	A.shade_poly(node, PackedVector2Array([
		Vector2(12, 4 + bob), Vector2(32, 5 + bob),
		Vector2(28, 14 + bob), Vector2(10, 14 + bob),
	]), Color(0.27, 0.06, 0.14), Color(0.18, 0.03, 0.09))

	for i in 4:
		var dx := 14.0 + i * 5
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(dx, 4 + bob), Vector2(dx + 4, 4 + bob), Vector2(dx + 2, 10 + bob),
		]), Color(0.96, 0.94, 0.86))
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(dx + 2, 14 + bob), Vector2(dx + 6, 14 + bob), Vector2(dx + 4, 9 + bob),
		]), Color(0.96, 0.94, 0.86))

	# olhos
	var glow := sin(t * 2.0) * 0.5 + 0.5
	var ea := 0.8 + 0.2 * glow
	A.fill_ellipse(node, 10, -10 + bob, 4, 3.5, Color(1, 0.24, 0.24, ea))
	A.fill_ellipse(node, 22, -6 + bob, 3, 2.5, Color(1, 0.24, 0.24, ea))
	A.fill_ellipse(node, 8, -18 + bob, 2.5, 2, Color(1, 0.24, 0.24, ea))
	A.fill_ellipse(node, 11, -9 + bob, 1.5, 1.5, Color(1, 0.86, 0.78, ea))

	# crista óssea
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(2, -14 + bob), Vector2(24, -16 + bob),
		Vector2(26, -11 + bob), Vector2(4, -8 + bob),
	]), A.mix(flesh, Color(0.92, 0.88, 0.8), 0.7))

	# úlceras
	A.fill_ellipse(node, 0, 6 + bob, 4, 3, Color(0.71, 0.24, 0.63, 0.4))
	A.fill_ellipse(node, -16, -6 + bob, 3.5, 2.5, Color(0.71, 0.24, 0.63, 0.4))

# ---------------------------------------------------------------------
static func _jungle(node: CanvasItem, fur: Color, bob: int, t: float) -> void:
	var swing := int(sin(t * 1.6) * 5.0)

	A.shadow(node, 0, 13, 16, 5)

	# cauda
	A.shade_poly(node, PackedVector2Array([
		Vector2(-14, -6 + bob), Vector2(-26, -14 + bob + swing / 3.0),
		Vector2(-28, -8 + bob), Vector2(-16, -2 + bob),
	]), A.mix(fur, Color.WHITE, 0.1), A.mix(fur, Color.BLACK, 0.4))

	# pernas
	var leg := A.mix(fur, Color.BLACK, 0.4)
	for spec in [
		[-13, swing / 2.0], [-5, -swing / 2.0],
		[6, swing / 2.0], [12, -swing / 2.0],
	]:
		var lx: float = spec[0]
		var lsw: float = spec[1]
		A.shade_poly(node, PackedVector2Array([
			Vector2(lx, 3 + lsw), Vector2(lx + 6, 3 + lsw),
			Vector2(lx + 6, 15 + lsw), Vector2(lx, 15 + lsw),
		]), A.mix(leg, Color.WHITE, 0.1), A.mix(leg, Color.BLACK, 0.5))
		A.fill_ellipse(node, lx + 3, 14 + lsw, 4, 2, A.mix(leg, Color.BLACK, 0.6))

	# corpo
	A.shade_ellipse(node, 1, bob, 16, 10,
		A.mix(fur, Color.WHITE, 0.3), A.mix(fur, Color.BLACK, 0.5))
	node.draw_arc(Vector2(1, bob), 16, 0, TAU, 24, A.mix(fur, Color.BLACK, 0.7), 1.5)
	A.fill_ellipse(node, 2, 4 + bob, 10, 4, A.mix(fur, Color(0.94, 0.92, 0.78), 0.5))

	# juba
	for i in 5:
		var bx := -12.0 + i * 6.0
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(bx, -8 + bob), Vector2(bx + 3, -18 - (i % 2) * 4 + bob),
			Vector2(bx + 6, -8 + bob),
		]), A.mix(fur, Color.BLACK, 0.5))

	# cabeça
	A.shade_ellipse(node, 16, -11 + bob, 10, 9,
		A.mix(fur, Color.WHITE, 0.35), A.mix(fur, Color.BLACK, 0.35))
	node.draw_arc(Vector2(16, -11 + bob), 10, 0, TAU, 20, A.mix(fur, Color.BLACK, 0.7), 1.5)

	# orelhas
	for hx in [12.0, 22.0]:
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(hx, -20 + bob), Vector2(hx + 4, -21 + bob), Vector2(hx - 2, -33 + bob),
		]), A.mix(fur, Color.WHITE, 0.2))
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(hx + 1, -21 + bob), Vector2(hx + 3, -22 + bob), Vector2(hx, -30 + bob),
		]), A.mix(fur, Color(0.86, 0.63, 0.59), 0.5))

	# focinho
	A.shade_ellipse(node, 25, -7 + bob, 7, 5,
		A.mix(fur, Color.WHITE, 0.25), A.mix(fur, Color.BLACK, 0.3))
	A.fill_ellipse(node, 31, -6 + bob, 2.5, 2.5, Color(0.1, 0.1, 0.12))
	node.draw_arc(Vector2(24, -5 + bob), 5, 0, PI * 0.8, 10, Color(0.16, 0.08, 0.08), 1.5)
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(24, -3 + bob), Vector2(27, -3 + bob), Vector2(25, 1 + bob),
	]), Color(0.98, 0.96, 0.88))

	# olho
	var glow := sin(t * 2.2) * 0.5 + 0.5
	A.fill_ellipse(node, 18, -14 + bob, 3, 2.5, Color(1, 0.9, 0.32, 0.8 + 0.2 * glow))
	node.draw_rect(Rect2(19, -16 + bob, 1.5, 5), Color(0.06, 0.04, 0.02))
	node.draw_colored_polygon(PackedVector2Array([
		Vector2(14, -19 + bob), Vector2(23, -21 + bob),
		Vector2(23, -18 + bob), Vector2(15, -16 + bob),
	]), A.mix(fur, Color.BLACK, 0.6))

	# garras
	for i in 2:
		var cx := 8.0 + i * 7
		var csw := swing / 2.0 if i == 0 else -swing / 2.0
		node.draw_line(Vector2(cx, 15 + csw), Vector2(cx + 3, 18 + csw), Color(0.92, 0.9, 0.82), 1.2)
