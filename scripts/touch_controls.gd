class_name TouchControls
extends Control

## Controles touch (mobile): joystick direcional + botões de ação.
## Aparece só em PLAY (main controla visible). Usa _input (não bloqueia
## os botões da loja) e desenha tudo via código, com os ícones das skills.

const JOY_R := 70.0
const JOY_DEAD := 0.15

var main = null  # Main (sem tipo: evita referência cíclica)
var player_ref = null  # Player local (ícones das skills)
var held := {}  # id -> bool
var joy_index := -1
var joy_origin := Vector2.ZERO
var joy_pos := Vector2.ZERO
var btn_index := {}  # touch index -> id
var _redraw_t := 0.0
var layout_override: Dictionary = {}
var editing := false
const TOUCH_ICONS := {"channel": preload("res://assets/icons/channel.svg"), "item": preload("res://assets/icons/item.svg"), "shop": preload("res://assets/icons/shop.svg")}
var painters: Array[Node2D] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_fit()
	get_viewport().size_changed.connect(_fit)
	visibility_changed.connect(reset_input)

## Sob CanvasLayer as âncoras não valem: tamanho explícito.
func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()

func is_down(action_id: String) -> bool:
	return bool(held.get(action_id, false))

func pad_dir() -> Vector2:
	if joy_index < 0:
		return Vector2.ZERO
	var off := joy_pos - joy_origin
	if off.length() < joy_radius() * JOY_DEAD:
		return Vector2.ZERO
	return off.limit_length(joy_radius()) / joy_radius()

func _to_local(viewport_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_pos

func _buttons() -> Array:
	var w := size.x
	var h := size.y
	var s := _tscale()
	var mir := _mirror()
	var out := []
	var primary := "dash" if editing or (main != null and main.mp == 0) else "attack"
	out.append({ id = primary, c = _bp(w - 95, h - 95, mir, w), r = 44.0 * s })
	for i in 5:
		# O passo cresce com a escala: no tamanho "Grande" (r=31) o pitch fixo
		# de 62 fazia os botões se sobrepor.
		out.append({ id = "skill%d" % (i + 1),
			c = _bp(w - 180, h - 90 - i * 62.0 * s, mir, w), r = 26.0 * s })
	out.append({ id = "item", c = _bp(w - 270, h - 95, mir, w), r = 24.0 * s })
	out.append({ id = "channel", c = _bp(150, h - 235, mir, w), r = 26.0 * s })
	out.append({ id = "shop", c = _bp(w - 95, 175, mir, w), r = 22.0 * s })
	out.append({ id = "pause", c = _bp(w - 40, 175, mir, w), r = 22.0 * s })
	out.append({ id = "skip", c = _bp(w - 150, 175, mir, w), r = 22.0 * s })
	for b in out:
		var key := "primary" if b.id in ["dash", "attack"] else str(b.id)
		var custom: Dictionary = layout_data().get(key, {})
		b.r = maxf(22.0, float(b.r) * clampf(float(custom.get("scale", 1.0)), 0.75, 1.6))
		if custom.has("x"):
			b.c = Vector2(float(custom.x), float(custom.y)) * size
		b.c = clamp_center(b.c, float(b.r))
		b["alpha"] = clampf(float(custom.get("alpha", 0.85)), 0.25, 1.0)
	return out

func layout_data() -> Dictionary:
	if editing:
		return layout_override
	return main.settings.get("touch_layout", {}) if main != null else {}

func clamp_center(point: Vector2, radius: float) -> Vector2:
	return Vector2(clampf(point.x, radius + 12, size.x - radius - 12), clampf(point.y, radius + 12, size.y - radius - 12))

func joy_center() -> Vector2:
	var custom: Dictionary = layout_data().get("joystick", {})
	return clamp_center(Vector2(float(custom.get("x", 0.83 if _mirror() else 0.17)), float(custom.get("y", 0.77))) * size, joy_radius())

func joy_radius() -> float:
	return JOY_R * clampf(float(layout_data().get("joystick", {}).get("scale", 1.0)), 0.75, 1.6)

func reset_input() -> void:
	held.clear()
	btn_index.clear()
	joy_index = -1
	joy_pos = Vector2.ZERO
	joy_origin = Vector2.ZERO

func _bp(x: float, y: float, mir: bool, w: float) -> Vector2:
	return Vector2(w - x if mir else x, y)

func _tsize() -> int:
	if main == null:
		return 1
	var st = main.get("settings")
	if not (st is Dictionary):
		return 1
	return clampi(int((st as Dictionary).get("touch_size", 1)), 0, 2)

func _tscale() -> float:
	return [0.85, 1.0, 1.2][_tsize()]

func _mirror() -> bool:
	if main == null:
		return false
	var st = main.get("settings")
	if not (st is Dictionary):
		return false
	return int((st as Dictionary).get("touch_side", 0)) == 1

func _at_button(p: Vector2) -> Dictionary:
	for b in _buttons():
		var c: Vector2 = b.c
		if p.distance_to(c) <= float(b.r) + 6.0:
			return b
	return {}

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or editing:
		return
	if event is InputEventScreenTouch:
		var pos := _to_local(event.position)
		if event.pressed:
			var b := _at_button(pos)
			if not b.is_empty():
				var id := str(b.id)
				held[id] = true
				btn_index[event.index] = id
				if main != null:
					main.touch_button(id)
			elif _joy_zone(pos) and joy_index < 0:
				joy_index = event.index
				joy_origin = joy_center()
				joy_pos = pos
				queue_redraw()
		else:
			if event.index == joy_index:
				joy_index = -1
				queue_redraw()
			if btn_index.has(event.index):
				var released: String = btn_index[event.index]
				btn_index.erase(event.index)
				held[released] = released in btn_index.values()
	elif event is InputEventScreenDrag:
		if event.index == joy_index:
			joy_pos = _to_local(event.position)
			queue_redraw()

func _joy_zone(pos: Vector2) -> bool:
	return pos.distance_to(joy_center()) <= joy_radius() * 1.35

func _process(delta: float) -> void:
	if not visible:
		return
	_redraw_t += delta
	var interval := 1.0 / 30.0 if GameSettings.quality_cache >= 1 else 1.0 / 60.0
	if _redraw_t >= interval:
		_redraw_t = 0.0
		queue_redraw()
		_sync_painters()

func _sync_painters() -> void:
	var buttons := _buttons()
	while painters.size() < buttons.size():
		var painter := ButtonPainter.new()
		painter.controls = self
		add_child(painter)
		painters.append(painter)
	for i in buttons.size():
		painters[i].button = buttons[i]
		painters[i].modulate.a = buttons[i].alpha
		painters[i].queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	# Persistent engraved thumb pad; exact same geometry in the HUD editor.
	var origin := joy_center()
	var radius := joy_radius()
	var alpha := float(layout_data().get("joystick", {}).get("alpha", 0.7))
	SkillIcon.draw_round_bg(self, origin, radius, Color(ForestUI.MINT, alpha), true, joy_index >= 0)
	var knob := origin + (joy_pos - joy_origin).limit_length(radius) if joy_index >= 0 else origin
	draw_circle(knob, radius * 0.34, Color(ForestUI.EDGE, alpha))
	draw_arc(knob, radius * 0.34, 0, TAU, 24, Color(ForestUI.GOLD, alpha), 2.0)
class ButtonPainter extends Node2D:
	var controls: TouchControls
	var button: Dictionary = {}
	func _draw() -> void:
		if button.is_empty():
			return
		var pl = controls.player_ref
		var role := str(pl.role) if is_instance_valid(pl) else "tank"
		_draw_button(ThemeDB.fallback_font, button, role, pl)

	func _draw_button(font: Font, b: Dictionary, role: String, pl) -> void:
		var c: Vector2 = b.c
		var r: float = b.r
		var id := str(b.id)
		var down := controls.is_down(id)
		SkillIcon.draw_round_bg(self, c, r, SkillIcon.role_color(role), true, down)
		if down:
			draw_circle(c, r * 0.86, Color(1, 1, 1, 0.08))
		if id == "attack":
			var ready := true
			if pl != null:
				ready = pl.attack_cd <= 0.0
			SkillIcon.draw_basic(self, role, c + Vector2(0, -4), r * 0.45, ready)
			_center(font, "ATK", c.x, c.y + r - 8, 10, Color(1, 0.85, 0.2))
		elif id == "dash":
			draw_texture_rect(preload("res://assets/icons/dash.svg"), Rect2(c - Vector2.ONE * r * 0.6, Vector2.ONE * r * 1.2), false)
			_center(font, "ESQUIVA", c.x, c.y + r - 7, 9, ForestUI.MINT)
			if pl != null and pl.dash_cd > 0.0:
				_draw_wedge(c, r * 0.94, pl.dash_cd / 1.6)
				_center(font, "%.1f" % pl.dash_cd, c.x, c.y + 6, 14, Color.WHITE)
		elif id.begins_with("skill"):
			_draw_skill_button(font, c, r, id, role, pl)
		elif id in ["channel", "item"]:
			var icon: Texture2D = TouchControls.TOUCH_ICONS[id]
			draw_texture_rect(icon, Rect2(c - Vector2.ONE * r * 0.6, Vector2.ONE * r * 1.2), false)
		elif id == "shop":
			draw_texture_rect(TouchControls.TOUCH_ICONS["shop"], Rect2(c - Vector2.ONE * r * 0.6, Vector2.ONE * r * 1.2), false)
		elif id == "pause":
			_center(font, "II", c.x, c.y + 5, 13, Color.WHITE)
		elif id == "skip":
			var can_skip := true
			if controls.main != null and controls.main.has_method("can_skip_wave"):
				can_skip = bool(controls.main.can_skip_wave())
			var skip_col := Color(1, 0.85, 0.2) if can_skip else Color(0.5, 0.5, 0.55)
			for x in [-5.0, 5.0]:
				draw_colored_polygon(PackedVector2Array([c + Vector2(x - 4, -7), c + Vector2(x + 4, 0), c + Vector2(x - 4, 7)]), skip_col)

	func _draw_skill_button(font: Font, c: Vector2, r: float, id: String, role: String, pl) -> void:
		var slot := int(id.trim_prefix("skill")) - 1
		_center(font, str(slot + 1), c.x - r + 4, c.y - r + 12, 10, Color(1, 0.85, 0.2))
		if pl == null or slot < 0 or slot >= (pl.skills as Array).size():
			if controls.editing:
				SkillIcon.draw_icon(self, role, "damage", slot, c, r * 0.55)
			else:
				_center(font, "–", c.x, c.y + 6, 16, Color(0.5, 0.5, 0.55))
			return
		var s: Dictionary = (pl.skills as Array)[slot]
		var cfg: Dictionary = s.cfg
		var can: bool = float(s.get("cd_left", 0.0)) <= 0.0 and float(pl.mana) >= float(cfg.get("mana", 0))
		SkillIcon.draw_icon(self, role, str(cfg.get("kind", "damage")), slot, c, r * 0.5, not can)
		if float(s.get("cd_left", 0.0)) > 0.0:
			var ratio := clampf(float(s.get("cd_left", 0.0)) / maxf(0.01, float(cfg.get("cd", 1.0))), 0.0, 1.0)
			# A versão antiga pintava um disco escuro e "limpava" com uma segunda
			# cor em alpha 0 — que não limpa nada. Agora é uma fatia de verdade,
			# que encolhe conforme o CD passa.
			_draw_wedge(c, r * 0.94, ratio)
			_center(font, str(int(ceil(float(s.get("cd_left", 0.0))))), c.x, c.y + 5, 13, Color.WHITE)
		elif not can:
			draw_circle(c, r * 0.94, Color(0.1, 0.08, 0.1, 0.45))

	## Fatia circular do topo no sentido horário, cobrindo `frac` do círculo.
	func _draw_wedge(c: Vector2, r: float, frac: float) -> void:
		frac = clampf(frac, 0.0, 1.0)
		if frac <= 0.0:
			return
		var pts := PackedVector2Array([c])
		var segs := maxi(6, int(28.0 * frac))
		for i in segs + 1:
			var a := -PI * 0.5 + TAU * frac * float(i) / float(segs)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.62))

	func _center(font: Font, txt: String, cx: float, y: float, fsize: int, col: Color) -> void:
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		draw_string(font, Vector2(cx - tw / 2.0, y), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset_input()
