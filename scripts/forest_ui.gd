class_name ForestUI
extends RefCounted

const INK := Color("101d25")
const PANEL := Color("172b30")
const EDGE := Color("54736a")
const GOLD := Color("e9b968")
const PAPER := Color("f4e7c6")
const MINT := Color("87d6aa")

static func frame(node: CanvasItem, rect: Rect2, accent: Color = GOLD) -> void:
	node.draw_rect(Rect2(rect.position + Vector2(0, 4), rect.size), Color(0.02, 0.04, 0.06, 0.6))
	node.draw_rect(rect, INK)
	node.draw_rect(rect.grow(-2), EDGE)
	node.draw_rect(rect.grow(-4), PANEL)
	node.draw_rect(Rect2(rect.position + Vector2(8, 4), Vector2(rect.size.x - 16, 2)), accent)
	for x in [rect.position.x + 4, rect.end.x - 8]:
		for y in [rect.position.y + 4, rect.end.y - 8]:
			node.draw_rect(Rect2(x, y, 4, 4), accent)

static func style(bg: Color, accent: Color, margin: int = 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = accent
	s.set_border_width_all(2)
	s.border_width_bottom = 4
	s.set_content_margin_all(margin)
	s.shadow_color = Color(0.02, 0.04, 0.06, 0.6)
	s.shadow_size = 3
	s.shadow_offset = Vector2(0, 3)
	return s

static func button(b: Button, accent: Color = GOLD) -> void:
	b.add_theme_stylebox_override("normal", style(INK, EDGE))
	b.add_theme_stylebox_override("hover", style(PANEL.lightened(0.15), accent))
	b.add_theme_stylebox_override("pressed", style(PANEL, accent))
	b.add_theme_stylebox_override("focus", style(Color(0, 0, 0, 0), accent, 0))
	b.add_theme_color_override("font_color", PAPER)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_font_size_override("font_size", 18)
