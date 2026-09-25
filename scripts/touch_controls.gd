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

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_fit()
	get_viewport().size_changed.connect(_fit)

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
	if off.length() < JOY_R * JOY_DEAD:
		return Vector2.ZERO
	return off.limit_length(JOY_R) / JOY_R

func _to_local(viewport_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_pos

func _buttons() -> Array:
	var w := size.x
	var h := size.y
	var out := []
	out.append({ id = "attack", c = Vector2(w - 95, h - 95), r = 44.0 })
	for i in 5:
		out.append({ id = "skill%d" % (i + 1),
			c = Vector2(w - 180, h - 90 - i * 62), r = 26.0 })
	out.append({ id = "item", c = Vector2(w - 270, h - 95), r = 24.0 })
	out.append({ id = "channel", c = Vector2(150, h - 235), r = 26.0 })
	out.append({ id = "shop", c = Vector2(w - 95, 175), r = 22.0 })
	out.append({ id = "pause", c = Vector2(w - 40, 175), r = 22.0 })
	return out

func _at_button(p: Vector2) -> Dictionary:
	for b in _buttons():
		var c: Vector2 = b.c
		if p.distance_to(c) <= float(b.r) + 6.0:
			return b
	return {}

func _input(event: InputEvent) -> void:
	if not visible:
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
			elif pos.x < size.x * 0.45 and pos.y > size.y * 0.35 and joy_index < 0:
				joy_index = event.index
				joy_origin = pos
				joy_pos = pos
				queue_redraw()
		else:
			if event.index == joy_index:
				joy_index = -1
				queue_redraw()
			if btn_index.has(event.index):
				held[btn_index[event.index]] = false
				btn_index.erase(event.index)
	elif event is InputEventScreenDrag:
		if event.index == joy_index:
			joy_pos = _to_local(event.position)
			queue_redraw()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	# Joystick.
	if joy_index >= 0:
		draw_circle(joy_origin, JOY_R, Color(1, 1, 1, 0.12))
		draw_arc(joy_origin, JOY_R, 0, TAU, 32, Color(1, 1, 1, 0.35), 2.0)
		var knob := joy_origin + (joy_pos - joy_origin).limit_length(JOY_R)
		draw_circle(knob, 26, Color(1, 1, 1, 0.35))
		draw_arc(knob, 26, 0, TAU, 24, Color(1, 1, 1, 0.6), 2.0)
	var role := "tank"
	var pl = null
	if player_ref != null and is_instance_valid(player_ref):
		pl = player_ref
		role = str(pl.role)
	for b in _buttons():
		_draw_button(font, b, role, pl)

func _draw_button(font: Font, b: Dictionary, role: String, pl) -> void:
	var c: Vector2 = b.c
	var r: float = b.r
	var id := str(b.id)
	var down := is_down(id)
	draw_circle(c, r, Color(0, 0, 0, 0.45 if down else 0.30))
	draw_arc(c, r, 0, TAU, 28, Color(1, 1, 1, 0.65 if down else 0.4), 2.0)
	if id == "attack":
		var ready := true
		if pl != null:
			ready = pl.attack_cd <= 0.0
		SkillIcon.draw_basic(self, role, c + Vector2(0, -4), r * 0.45, ready)
		_center(font, "ATK", c.x, c.y + r - 8, 10, Color(1, 0.85, 0.2))
	elif id.begins_with("skill"):
		_draw_skill_button(font, c, r, id, role, pl)
	elif id == "channel":
		_center(font, "E", c.x, c.y + 6, 18, Color(0.55, 0.78, 1))
	elif id == "item":
		_center(font, "Q", c.x, c.y + 6, 18, Color(1, 0.9, 0.5))
	elif id == "shop":
		_center(font, "LOJA", c.x, c.y + 4, 10, Color(1, 0.85, 0.2))
	elif id == "pause":
		_center(font, "II", c.x, c.y + 5, 13, Color.WHITE)

func _draw_skill_button(font: Font, c: Vector2, r: float, id: String, role: String, pl) -> void:
	var slot := int(id.trim_prefix("skill")) - 1
	_center(font, str(slot + 1), c.x - r + 4, c.y - r + 12, 10, Color(1, 0.85, 0.2))
	if pl == null or slot < 0 or slot >= (pl.skills as Array).size():
		_center(font, "–", c.x, c.y + 6, 16, Color(0.5, 0.5, 0.55))
		return
	var s: Dictionary = (pl.skills as Array)[slot]
	var cfg: Dictionary = s.cfg
	var can: bool = float(s.get("cd_left", 0.0)) <= 0.0 and float(pl.mana) >= float(cfg.get("mana", 0))
	SkillIcon.draw_icon(self, role, str(cfg.get("kind", "damage")), slot, c, r * 0.5, not can)
	if float(s.get("cd_left", 0.0)) > 0.0:
		var ratio := clampf(float(s.get("cd_left", 0.0)) / maxf(0.01, float(cfg.get("cd", 1.0))), 0.0, 1.0)
		draw_circle(c, r * 0.62, Color(0, 0, 0, 0.55 * ratio))
		_center(font, str(int(ceil(float(s.get("cd_left", 0.0))))), c.x, c.y + 5, 13, Color.WHITE)

func _center(font: Font, txt: String, cx: float, y: float, fsize: int, col: Color) -> void:
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	draw_string(font, Vector2(cx - tw / 2.0, y), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
