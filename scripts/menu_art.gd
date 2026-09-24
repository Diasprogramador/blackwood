class_name MenuArt
extends Object

## Visual dos menus no clima da referência: clareira na floresta ao entardecer,
## fogueira acesa, pinheiros em silhueta e vinheta escura. Tudo procedural.

const CREAM := Color(0.96, 0.90, 0.74)
const GOLD := Color(1.0, 0.85, 0.4)
const DIM := Color(0.7, 0.68, 0.62)

## Fundo completo (chame no _draw da tela, com size do Control + tick animado).
static func draw_back(node: CanvasItem, size: Vector2, tick: float) -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	_draw_sky(node, w, h)
	_draw_stars(node, w, h)
	_draw_moon(node, w, h)
	_draw_pines(node, w, h, 0.52, Color(0.08, 0.14, 0.13), 46.0)
	_draw_ground(node, w, h)
	_draw_pines(node, w, h, 0.60, Color(0.04, 0.08, 0.07), 70.0)
	_draw_campfire(node, w * 0.36, h * 0.80, tick)
	_draw_side_trees(node, w, h)
	_draw_embers(node, w, h, tick)
	_draw_vignette(node, w, h)

static func _draw_sky(node: CanvasItem, w: float, h: float) -> void:
	var top := Color(0.04, 0.09, 0.12)
	var mid := Color(0.35, 0.22, 0.20)
	var hor := Color(0.75, 0.45, 0.28)
	var bands := 28
	for i in bands:
		var t := float(i) / float(bands - 1)
		var c: Color
		if t < 0.55:
			c = top.lerp(mid, t / 0.55)
		else:
			c = mid.lerp(hor, (t - 0.55) / 0.45)
		node.draw_rect(Rect2(0, h * 0.62 * t, w, h * 0.62 / bands + 1), c)

static func _draw_stars(node: CanvasItem, w: float, h: float) -> void:
	for i in 40:
		var hx := float(hash(i * 2 + 1) % 1000) / 1000.0
		var hy := float(hash(i * 3 + 7) % 1000) / 1000.0
		if hy > 0.45:
			continue
		var a := 0.25 + 0.55 * float(hash(i * 5 + 3) % 100) / 100.0
		node.draw_circle(Vector2(hx * w, hy * h), 1.2, Color(1, 0.95, 0.85, a))

static func _draw_moon(node: CanvasItem, w: float, h: float) -> void:
	var m := Vector2(w * 0.72, h * 0.20)
	node.draw_circle(m, 46, Color(0.95, 0.85, 0.65, 0.12))
	node.draw_circle(m, 30, Color(0.95, 0.85, 0.65, 0.18))
	node.draw_circle(m, 20, Color(0.96, 0.90, 0.74))
	node.draw_circle(m + Vector2(-6, -4), 15, Color(0.90, 0.83, 0.66))

static func _pine(node: CanvasItem, x: float, base_y: float, pw: float, ph: float, c: Color) -> void:
	for k in 3:
		var t := float(k) / 2.0
		var ww := pw * (1.0 - t * 0.35)
		var y0 := base_y - ph * t * 0.55
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(x - ww * 0.5, y0), Vector2(x + ww * 0.5, y0),
			Vector2(x, y0 - ph * 0.55),
		]), c)
	node.draw_rect(Rect2(x - 3, base_y - 6, 6, 8), c.darkened(0.2))

static func _draw_pines(node: CanvasItem, w: float, h: float, y_frac: float, c: Color, max_h: float) -> void:
	var base_y := h * y_frac
	var x := -20.0
	var i := 0
	while x < w + 20.0:
		var hh := max_h * (0.5 + 0.5 * float(hash(i * 7 + 1) % 100) / 100.0)
		var ww := hh * 0.55
		_pine(node, x, base_y, ww, hh, c)
		x += ww * 0.55
		i += 1

static func _draw_ground(node: CanvasItem, w: float, h: float) -> void:
	var gy := h * 0.58
	node.draw_rect(Rect2(0, gy, w, h - gy), Color(0.07, 0.10, 0.07))
	node.draw_rect(Rect2(0, gy, w, 10), Color(0.10, 0.14, 0.09))
	# clareira de terra batida
	ArtUtil.fill_ellipse(node, w * 0.38, h * 0.86, w * 0.30, h * 0.13, Color(0.16, 0.12, 0.08))
	ArtUtil.fill_ellipse(node, w * 0.38, h * 0.85, w * 0.22, h * 0.09, Color(0.20, 0.15, 0.10))

static func _draw_side_trees(node: CanvasItem, w: float, h: float) -> void:
	# Troncos grossos nas laterais (moldura de floresta).
	for s in [-1.0, 1.0]:
		var tx: float = w * 0.5 + s * w * 0.52
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(tx - s * 30, 0), Vector2(tx + s * 60, 0),
			Vector2(tx + s * 30, h), Vector2(tx - s * 70, h),
		]), Color(0.02, 0.03, 0.025))
		# galhos
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(tx, h * 0.1), Vector2(tx - s * 130, h * 0.22),
			Vector2(tx - s * 120, h * 0.26), Vector2(tx, h * 0.16),
		]), Color(0.02, 0.03, 0.025))
		# copa escura no topo
		ArtUtil.fill_ellipse(node, tx, -20, 150, 90, Color(0.02, 0.04, 0.03))

static func _draw_campfire(node: CanvasItem, cx: float, cy: float, tick: float) -> void:
	# brilho quente no chão
	var glow := 0.5 + 0.5 * sin(tick * 0.09)
	ArtUtil.fill_ellipse(node, cx, cy + 10, 130 + glow * 20, 46, Color(0.9, 0.45, 0.15, 0.10))
	ArtUtil.fill_ellipse(node, cx, cy + 6, 80, 28, Color(1, 0.6, 0.2, 0.12))
	# anel de pedras
	for i in 9:
		var a := TAU * i / 9.0
		node.draw_circle(Vector2(cx + cos(a) * 44, cy + sin(a) * 12 + 8), 7, Color(0.32, 0.30, 0.28))
		node.draw_circle(Vector2(cx + cos(a) * 44 - 2, cy + sin(a) * 12 + 6), 4, Color(0.42, 0.40, 0.37))
	# toras
	for spec in [[-0.35, 30], [0.3, -26], [1.2, 4]]:
		var ang: float = spec[0]
		var off: float = spec[1]
		var dir := Vector2(cos(ang), sin(ang) * 0.4)
		var p1 := Vector2(cx, cy + 6) - dir * 34 + Vector2(0, off * 0.2)
		var p2 := Vector2(cx, cy + 6) + dir * 34 + Vector2(0, off * 0.2)
		node.draw_line(p1, p2, Color(0.30, 0.18, 0.10), 11)
		node.draw_line(p1, p2 + Vector2(0, -2), Color(0.42, 0.26, 0.14), 7)
	# chama (3 camadas tremeluzindo)
	var f := sin(tick * 0.35) * 3.0 + sin(tick * 0.13) * 2.0
	ArtUtil.fill_ellipse(node, cx, cy - 26 + f, 20, 34, Color(0.95, 0.35, 0.08, 0.9))
	ArtUtil.fill_ellipse(node, cx + 2, cy - 22 + f, 13, 24, Color(1.0, 0.65, 0.15, 0.95))
	ArtUtil.fill_ellipse(node, cx, cy - 16 + f, 7, 13, Color(1.0, 0.93, 0.70))
	# banco de tronco à direita
	node.draw_line(Vector2(cx + 120, cy + 26), Vector2(cx + 230, cy + 22), Color(0.30, 0.18, 0.10), 20)
	node.draw_line(Vector2(cx + 120, cy + 22), Vector2(cx + 230, cy + 18), Color(0.42, 0.26, 0.14), 14)

static func _draw_embers(node: CanvasItem, w: float, h: float, tick: float) -> void:
	for i in 16:
		var seed := float(hash(i * 11 + 5) % 1000) / 1000.0
		var speed := 14.0 + seed * 22.0
		var yy := h * 0.80 - fmod(tick * speed * 0.06 + seed * 260.0, 260.0)
		var xx := w * 0.36 + sin(tick * 0.05 + seed * 9.0) * 40.0 + (seed - 0.5) * 120.0
		var a := clampf((yy - h * 0.30) / (h * 0.5), 0.0, 1.0)
		if a <= 0.0:
			continue
		node.draw_circle(Vector2(xx, yy), 1.6, Color(1, 0.6, 0.2, a * 0.8))

static func _draw_vignette(node: CanvasItem, w: float, h: float) -> void:
	for i in 8:
		var t := float(i) / 8.0
		var a := 0.30 * (1.0 - t)
		var m := 70.0 * t
		var c := Color(0, 0, 0, a)
		node.draw_rect(Rect2(m, m, w - m * 2, 5), c)
		node.draw_rect(Rect2(m, h - m - 5, w - m * 2, 5), c)
		node.draw_rect(Rect2(m, m, 5, h - m * 2), c)
		node.draw_rect(Rect2(w - m - 5, m, 5, h - m * 2), c)
	# cantos bem escuros
	for corner in [Vector2(0, 0), Vector2(w, 0), Vector2(0, h), Vector2(w, h)]:
		ArtUtil.fill_ellipse(node, corner.x, corner.y, 190, 150, Color(0, 0, 0, 0.55))

# ---------------------------------------------------------------------
#  ESTILOS COMPARTILHADOS
# ---------------------------------------------------------------------
static func style_panel() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.08, 0.92)
	sb.border_color = Color(0.79, 0.64, 0.30)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 12
	return sb

static func style_btn(accent: Color, selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if selected:
		sb.bg_color = Color(accent.r * 0.30, accent.g * 0.30, accent.b * 0.30, 0.95)
		sb.border_color = accent
		sb.set_border_width_all(2)
	else:
		sb.bg_color = Color(0.07, 0.08, 0.11, 0.90)
		sb.border_color = Color(0.35, 0.33, 0.30)
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func apply_menu_btn(b: Button, accent: Color) -> void:
	b.add_theme_stylebox_override("normal", style_btn(accent, false))
	b.add_theme_stylebox_override("hover", style_btn(accent, true))
	b.add_theme_stylebox_override("pressed", style_btn(GOLD, true))
	b.add_theme_stylebox_override("disabled", style_btn(Color(0.4, 0.4, 0.42), false))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.48))
	b.add_theme_font_size_override("font_size", 20)

static func apply_small_btn(b: Button, accent: Color, fsize: int = 14) -> void:
	apply_menu_btn(b, accent)
	b.add_theme_font_size_override("font_size", fsize)

static func title_label(txt: String, fsize: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", CREAM)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	return l

static func spark() -> String:
	return "✦"
