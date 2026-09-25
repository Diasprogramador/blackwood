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
	_draw_moon(node, w, h, tick)
	_draw_shooting(node, w, h, tick)
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

static func _draw_moon(node: CanvasItem, w: float, h: float, tick: float) -> void:
	var m := Vector2(w * 0.72, h * 0.20)
	var breathe := 0.5 + 0.5 * sin(tick * 0.05)
	node.draw_circle(m, 46 + breathe * 5.0, Color(0.95, 0.85, 0.65, 0.10 + breathe * 0.05))
	node.draw_circle(m, 30, Color(0.95, 0.85, 0.65, 0.18))
	node.draw_circle(m, 20, Color(0.96, 0.90, 0.74))
	node.draw_circle(m + Vector2(-6, -4), 15, Color(0.90, 0.83, 0.66))

## Estrela cadente a cada ~7s.
static func _draw_shooting(node: CanvasItem, w: float, h: float, tick: float) -> void:
	var k := fmod(tick, 420.0) / 60.0  # segundos no ciclo
	if k >= 1.2:
		return
	var a := clampf((1.2 - k) / 1.2, 0.0, 1.0)
	var head := Vector2(w * 0.85 - k * 260.0, h * 0.08 + k * 90.0)
	var tail := head + Vector2(46, -32)
	node.draw_line(tail, head, Color(1, 0.95, 0.85, 0.55 * a), 2.0)
	node.draw_circle(head, 2.2, Color(1, 1, 1, 0.9 * a))

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
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 2)
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

## Título dourado (telas principais).
static func title_label_gold(txt: String, fsize: int) -> Label:
	var l := title_label(txt, fsize)
	l.add_theme_color_override("font_color", GOLD)
	l.add_theme_color_override("font_shadow_color", Color(0.3, 0.15, 0.0, 0.9))
	return l

## Cabeçalho de seção ("— ÁUDIO —" etc.).
static func section_label(txt: String) -> Label:
	var l := Label.new()
	l.text = "— %s —" % txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", GOLD)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

## Ornamento divisor: linha ◆ linha.
static func divider(accent := GOLD) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in [0, 1]:
		var line := ColorRect.new()
		line.color = Color(accent, 0.5)
		line.custom_minimum_size = Vector2(120, 2)
		line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(line)
		if side == 0:
			var mid := Label.new()
			mid.text = "◆"
			mid.add_theme_font_size_override("font_size", 12)
			mid.add_theme_color_override("font_color", accent)
			mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(mid)
	return row

## Cartão (escolha de campeão): borda e brilho na cor do dono.
static func style_card(accent: Color, selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.13, 0.20, 0.98) if selected else Color(0.10, 0.10, 0.16, 0.95)
	sb.border_color = Color(1, 0.85, 0.3) if selected else accent.darkened(0.25)
	sb.set_border_width_all(3 if selected else 2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(1, 0.85, 0.3, 0.35) if selected else Color(accent, 0.25)
	sb.shadow_size = 12 if selected else 6
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	return sb

## Linha de loja (botão com barra lateral de destaque).
static func style_row(accent: Color, hover := false, pressed := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if pressed:
		sb.bg_color = Color(accent.r * 0.28, accent.g * 0.28, accent.b * 0.28, 0.98)
	elif hover:
		sb.bg_color = Color(0.14, 0.15, 0.18, 0.97)
	else:
		sb.bg_color = Color(0.09, 0.10, 0.13, 0.95)
	sb.border_color = Color(0.35, 0.33, 0.30) if not hover and not pressed else accent
	sb.set_border_width_all(1)
	sb.border_width_left = 5
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func apply_row_btn(b: Button, accent: Color) -> void:
	b.add_theme_stylebox_override("normal", style_row(accent))
	b.add_theme_stylebox_override("hover", style_row(accent, true))
	b.add_theme_stylebox_override("pressed", style_row(accent, false, true))
	b.add_theme_stylebox_override("disabled", style_row(Color(0.4, 0.4, 0.42)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.48))

static func spark() -> String:
	return "✦"

# ---------------------------------------------------------------------
#  IDENTIDADE BLACKWOOD — moldura dourada, brasões e véus
# ---------------------------------------------------------------------
## Cantos em L + rebites (a assinatura visual do jogo).
static func frame_corners(node: CanvasItem, rect: Rect2, accent: Color) -> void:
	var p := rect.position
	var s := rect.size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	var L := 14.0
	var t := 2.5
	var c := Color(accent, 0.9)
	for corner in [p, Vector2(p.x + s.x, p.y), Vector2(p.x, p.y + s.y), p + s]:
		var sx := 1.0 if corner.x < p.x + s.x * 0.5 else -1.0
		var sy := 1.0 if corner.y < p.y + s.y * 0.5 else -1.0
		node.draw_line(corner, corner + Vector2(sx * L, 0), c, t)
		node.draw_line(corner, corner + Vector2(0, sy * L), c, t)
		node.draw_circle(corner + Vector2(sx * 8.0, sy * 8.0), 2.0, Color(c, 0.7))

## Moldura de tela (chamar no _draw depois do draw_back).
static func draw_screen_frame(node: CanvasItem, size: Vector2) -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var inset := 8.0
	node.draw_rect(Rect2(inset, inset, w - inset * 2, h - inset * 2), Color(GOLD, 0.35), false, 1.5)
	node.draw_rect(Rect2(inset + 4, inset + 4, w - (inset + 4) * 2, h - (inset + 4) * 2),
		Color(GOLD, 0.15), false, 1.0)
	frame_corners(node, Rect2(inset, inset, w - inset * 2, h - inset * 2), Color(GOLD, 0.8))

## Painel com cantos rebitados (troque PanelContainer por ele).
class FramePanel extends PanelContainer:
	var accent := Color(1.0, 0.85, 0.4)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var inset := 5.0
		MenuArt.frame_corners(self,
			Rect2(inset, inset, size.x - inset * 2, size.y - inset * 2), accent)

## Caveira (game over).
static func draw_skull(node: CanvasItem, c: Vector2, r: float) -> void:
	var bone := Color(0.88, 0.85, 0.78)
	var dark := Color(0.15, 0.05, 0.05)
	ArtUtil.fill_ellipse(node, c.x, c.y - r * 0.15, r * 0.62, r * 0.58, bone)
	node.draw_rect(Rect2(c.x - r * 0.32, c.y + r * 0.25, r * 0.64, r * 0.35), bone)
	ArtUtil.fill_ellipse(node, c.x - r * 0.25, c.y - r * 0.15, r * 0.2, r * 0.24, dark)
	ArtUtil.fill_ellipse(node, c.x + r * 0.25, c.y - r * 0.15, r * 0.2, r * 0.24, dark)
	ArtUtil.fill_ellipse(node, c.x - r * 0.25, c.y - r * 0.15, r * 0.08, r * 0.1,
		Color(1, 0.3, 0.2, 0.9))
	ArtUtil.fill_ellipse(node, c.x + r * 0.25, c.y - r * 0.15, r * 0.08, r * 0.1,
		Color(1, 0.3, 0.2, 0.9))
	node.draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, r * 0.15), c + Vector2(-r * 0.1, r * 0.35), c + Vector2(r * 0.1, r * 0.35)]), dark)
	for i in 3:
		var x := c.x - r * 0.2 + i * r * 0.2
		node.draw_line(Vector2(x, c.y + r * 0.35), Vector2(x, c.y + r * 0.58), dark, 1.5)

class EmblemSkull extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(64, 64)

	func _draw() -> void:
		MenuArt.draw_skull(self, size * 0.5, 24.0)

## Explosão estelar (vitória).
static func draw_starburst(node: CanvasItem, c: Vector2, r: float) -> void:
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 1.05, r * 1.05, Color(1, 0.85, 0.3, 0.18))
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0 - PI * 0.5
		var rr := r * 0.85 if i % 2 == 0 else r * 0.38
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	node.draw_colored_polygon(pts, Color(1, 0.82, 0.3))
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 0.25, r * 0.25, Color(1, 1, 1))
	for i in 8:
		var a := TAU * i / 8.0
		node.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.9,
			c + Vector2(cos(a), sin(a)) * r * 1.15, Color(1, 0.9, 0.5, 0.7), 2.0)

class EmblemStar extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(64, 64)

	func _draw() -> void:
		MenuArt.draw_starburst(self, size * 0.5, 24.0)

## Crescente (pausa).
static func draw_crescent(node: CanvasItem, c: Vector2, r: float) -> void:
	node.draw_arc(c, r * 0.7, 0.7, 5.3, 24, Color(0.85, 0.9, 1), 5.0)
	node.draw_arc(c, r * 0.7, 1.0, 5.0, 22, Color(1, 1, 1), 1.5)
	node.draw_circle(c + Vector2(r * 0.55, -r * 0.45), 2.0, Color(1, 1, 0.8))
	node.draw_circle(c + Vector2(-r * 0.6, r * 0.4), 1.5, Color(1, 1, 0.8, 0.7))

class EmblemMoon extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(56, 56)

	func _draw() -> void:
		MenuArt.draw_crescent(self, size * 0.5, 22.0)

## Véu animado com brasas (fundo de game over / vitória).
class EmberVeil extends Control:
	var tick := 0.0
	var dim := Color(0.08, 0.0, 0.0, 0.72)
	var ember := Color(1, 0.4, 0.12)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if not visible:
			return
		tick += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 0.0 or h <= 0.0:
			return
		draw_rect(Rect2(Vector2.ZERO, size), dim)
		for i in 6:
			var t := float(i) / 6.0
			var a := 0.35 * (1.0 - t)
			var m := 60.0 * t
			var cc := Color(0, 0, 0, a)
			draw_rect(Rect2(m, m, w - m * 2, 5), cc)
			draw_rect(Rect2(m, h - m - 5, w - m * 2, 5), cc)
			draw_rect(Rect2(m, m, 5, h - m * 2), cc)
			draw_rect(Rect2(w - m - 5, m, 5, h - m * 2), cc)
		for i in 22:
			var seed := float(hash(i * 13 + 7) % 1000) / 1000.0
			var yy := h - fmod(tick * (14.0 + seed * 20.0) + seed * 400.0, h + 40.0) + 20.0
			var xx := w * (0.2 + 0.6 * seed) + sin(tick * 0.8 + seed * 9.0) * 30.0
			var ea := clampf(yy / h, 0.0, 1.0) * 0.8
			draw_circle(Vector2(xx, yy), 1.8, Color(ember, ea))

## Tecla física (botões de configuração): keycap claro com sombra 3D.
static func style_keycap(capturing := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.95, 0.5, 0.45, 0.98) if capturing else Color(0.85, 0.82, 0.74, 0.98)
	sb.border_color = Color(0.25, 0.22, 0.18)
	sb.set_border_width_all(2)
	sb.border_width_bottom = 4
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 4
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

static func apply_keycap(b: Button, capturing := false) -> void:
	b.add_theme_stylebox_override("normal", style_keycap(capturing))
	var pr := style_keycap(capturing)
	pr.border_width_bottom = 2
	b.add_theme_stylebox_override("pressed", pr)
	var hv := style_keycap(capturing)
	hv.border_color = Color(1, 0.85, 0.4)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("disabled", style_keycap())
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1))
	b.add_theme_color_override("font_hover_color", Color(0.1, 0.08, 0.06))
	b.add_theme_color_override("font_pressed_color", Color(0.1, 0.08, 0.06))
	b.add_theme_font_size_override("font_size", 14)
