class_name ArtUtil
extends Object

## Helpers de desenho (equivalentes aos gradientes/contornos do Java2D).
## Port dos helpers de SpriteFactory.java (cores por role/tipo vivem em ChampData/EnemyData).

static func mix(a: Color, b: Color, f: float) -> Color:
	f = clampf(f, 0.0, 1.0)
	return Color(
		a.r + (b.r - a.r) * f,
		a.g + (b.g - a.g) * f,
		a.b + (b.b - a.b) * f,
		a.a + (b.a - a.a) * f,
	)

static func with_a(c: Color, alpha: float) -> Color:
	return Color(c.r, c.g, c.b, alpha)

static func ellipse_pts(cx: float, cy: float, rx: float, ry: float, segs: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segs:
		var a := TAU * float(i) / float(segs)
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return pts

static func fill_ellipse(node: CanvasItem, cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	node.draw_colored_polygon(ellipse_pts(cx, cy, rx, ry), color)

## Elipse com gradiente vertical (vértices claros em cima, escuros embaixo).
static func shade_ellipse(node: CanvasItem, cx: float, cy: float, rx: float, ry: float,
		light: Color, dark: Color) -> void:
	var pts := ellipse_pts(cx, cy, rx, ry)
	var cols := PackedColorArray()
	var top := cy - ry
	var bot := cy + ry
	for p in pts:
		var t := clampf((p.y - top) / maxf(0.001, bot - top), 0.0, 1.0)
		cols.append(light.lerp(dark, t))
	node.draw_polygon(pts, cols)

## Polígono com gradiente vertical por vértice.
static func shade_poly(node: CanvasItem, pts: PackedVector2Array, light: Color, dark: Color) -> void:
	if pts.is_empty():
		return
	var min_y := INF
	var max_y := -INF
	for p in pts:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var cols := PackedColorArray()
	for p in pts:
		var t := clampf((p.y - min_y) / maxf(0.001, max_y - min_y), 0.0, 1.0)
		cols.append(light.lerp(dark, t))
	node.draw_polygon(pts, cols)

static func stroke(node: CanvasItem, pts: PackedVector2Array, color: Color, width: float = 1.0, closed: bool = true) -> void:
	if pts.size() < 2:
		return
	var line := PackedVector2Array(pts)
	if closed:
		line.append(pts[0])
	node.draw_polyline(line, color, width, true)

static func fill_rrect(node: CanvasItem, x: float, y: float, w: float, h: float, r: float, color: Color) -> void:
	node.draw_colored_polygon(rrect_pts(x, y, w, h, r), color)

static func rrect_pts(x: float, y: float, w: float, h: float, r: float) -> PackedVector2Array:
	r = minf(r, minf(w, h) * 0.5)
	var pts := PackedVector2Array()
	var segs := 6
	# canto sup dir
	for i in segs + 1:
		var a := -PI * 0.5 + (PI * 0.5) * float(i) / segs
		pts.append(Vector2(x + w - r + cos(a) * r, y + r + sin(a) * r))
	# canto inf dir
	for i in segs + 1:
		var a := (PI * 0.5) * float(i) / segs
		pts.append(Vector2(x + w - r + cos(a) * r, y + h - r + sin(a) * r))
	# canto inf esq
	for i in segs + 1:
		var a := (PI * 0.5) + (PI * 0.5) * float(i) / segs
		pts.append(Vector2(x + r + cos(a) * r, y + h - r + sin(a) * r))
	# canto sup esq
	for i in segs + 1:
		var a := PI + (PI * 0.5) * float(i) / segs
		pts.append(Vector2(x + r + cos(a) * r, y + r + sin(a) * r))
	return pts

static func stroke_rrect(node: CanvasItem, x: float, y: float, w: float, h: float, r: float,
		color: Color, width: float = 2.0) -> void:
	stroke(node, rrect_pts(x, y, w, h, r), color, width, true)

static func shadow(node: CanvasItem, cx: float, cy: float, rx: float, ry: float, alpha: float = 0.35) -> void:
	fill_ellipse(node, cx, cy, rx, ry, Color(0, 0, 0, alpha))

static func star_pts(cx: float, cy: float, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := PI * 0.5 + float(i) * PI / 5.0
		var rad := r if i % 2 == 0 else r * 0.45
		pts.append(Vector2(cx + cos(a) * rad, cy - sin(a) * rad))
	return pts
