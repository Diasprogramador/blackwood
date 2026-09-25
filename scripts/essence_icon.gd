class_name EssenceIcon
extends Control

## Ícone da essência (moeda meta ◆): cristal facetado desenhado via código.
## Use o Control nos menus ou draw_crystal() direto em canvas (HUD).

var tick := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	tick += delta
	queue_redraw()

static func essence_col() -> Color:
	return Color(0.55, 0.85, 1.0)

static func draw_crystal(node: CanvasItem, c: Vector2, r: float, shine := 1.0) -> void:
	var top := essence_col()
	var deep := Color(0.2, 0.5, 0.9)
	var edge := Color(0.85, 0.97, 1.0)
	# brilho ambiente
	ArtUtil.fill_ellipse(node, c.x, c.y, r * 1.1, r * 1.1, Color(top, 0.18 * shine))
	# corpo: trapézio superior + ponta inferior
	var gem := PackedVector2Array([
		c + Vector2(-r * 0.62, -r * 0.25), c + Vector2(r * 0.62, -r * 0.25),
		c + Vector2(0, r * 0.85)])
	ArtUtil.shade_poly(node, gem, ArtUtil.mix(top, Color.WHITE, 0.25), deep)
	ArtUtil.stroke(node, gem, edge, 1.5)
	# facetas
	node.draw_line(c + Vector2(-r * 0.62, -r * 0.25), c + Vector2(r * 0.62, -r * 0.25), edge, 1.5)
	node.draw_line(c + Vector2(-r * 0.3, -r * 0.25), c + Vector2(0, r * 0.85), Color(edge, 0.6), 1.0)
	node.draw_line(c + Vector2(r * 0.3, -r * 0.25), c + Vector2(0, r * 0.85), Color(edge, 0.6), 1.0)
	# brilho + estrelinha
	ArtUtil.fill_ellipse(node, c.x - r * 0.22, c.y - r * 0.12, r * 0.16, r * 0.1,
		Color(1, 1, 1, 0.9 * shine))
	node.draw_colored_polygon(ArtUtil.star_pts(c.x + r * 0.35, c.y - r * 0.45, r * 0.16),
		Color(1, 1, 1, 0.8 * shine))

func _draw() -> void:
	var r := minf(size.x, size.y) * 0.38
	if r <= 0.0:
		return
	var pulse := 0.85 + 0.15 * sin(tick * 2.5)
	draw_crystal(self, size * 0.5, r, pulse)
