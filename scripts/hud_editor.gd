class_name HudEditor
extends Control

var data: Dictionary
var mp := 0
var settings: Dictionary:
	get:
		return data
var preview: TouchControls
var selected := "primary"
var finger := -1
var offset := Vector2.ZERO
var title: Label
var scale_slider: HSlider
var alpha_slider: HSlider

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	preview = TouchControls.new()
	preview.editing = true
	preview.main = self
	preview.layout_override = data.get("touch_layout", {}).duplicate(true)
	add_child(preview)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 16)
	panel.add_theme_stylebox_override("panel", ForestUI.style(ForestUI.INK, ForestUI.GOLD, 12))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	title = Label.new()
	title.text = "SEU HUD • arraste um controle"
	box.add_child(title)
	var sliders := HBoxContainer.new()
	box.add_child(sliders)
	scale_slider = _slider(sliders, "Tamanho", 0.75, 1.6)
	alpha_slider = _slider(sliders, "Opacidade", 0.25, 1.0)
	scale_slider.value_changed.connect(func(value): _property("scale", value))
	alpha_slider.value_changed.connect(func(value): _property("alpha", value))
	var row := HBoxContainer.new()
	box.add_child(row)
	_button(row, "Salvar", func():
		data["touch_layout"] = preview.layout_override.duplicate(true)
		GameSettings.save_data(data)
		queue_free())
	_button(row, "Cancelar", queue_free)
	_button(row, "Restaurar", func():
		preview.layout_override.clear()
		_select("primary")
		preview.queue_redraw())
	_select("primary")

func _slider(row: HBoxContainer, label: String, low: float, high: float) -> HSlider:
	var text := Label.new()
	text.text = label
	row.add_child(text)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(110, 44)
	row.add_child(slider)
	return slider

func _button(row: HBoxContainer, label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(130, 44)
	ForestUI.button(button)
	button.pressed.connect(action)
	row.add_child(button)

func _select(key: String) -> void:
	selected = key
	title.text = "SEU HUD • %s • arraste para mover" % str({"primary": "ESQUIVA / ATAQUE", "joystick": "MOVIMENTO", "channel": "MANA", "item": "POÇÃO", "shop": "LOJA", "pause": "PAUSA", "skip": "PRÓXIMA ONDA"}.get(key, key.replace("skill", "HABILIDADE ")))
	var custom: Dictionary = preview.layout_override.get(key, {})
	scale_slider.set_value_no_signal(float(custom.get("scale", 1.0)))
	alpha_slider.set_value_no_signal(float(custom.get("alpha", 0.85)))
	queue_redraw()

func _property(key: String, value: float) -> void:
	var custom: Dictionary = preview.layout_override.get(selected, {})
	custom[key] = value
	preview.layout_override[selected] = custom
	preview.queue_redraw()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger < 0:
			var pos: Vector2 = event.position
			var hit := preview._at_button(pos)
			if not hit.is_empty():
				_select("primary" if str(hit.id) in ["attack", "dash"] else str(hit.id))
				offset = Vector2(hit.c) - pos
				finger = event.index
			elif pos.distance_to(preview.joy_center()) < preview.joy_radius():
				_select("joystick")
				offset = preview.joy_center() - pos
				finger = event.index
		elif not event.pressed and event.index == finger:
			finger = -1
		accept_event()
	elif event is InputEventScreenDrag and event.index == finger:
		var point: Vector2 = event.position + offset
		_property("x", clampf(point.x / size.x, 0.04, 0.96))
		_property("y", clampf(point.y / size.y, 0.04, 0.96))
		accept_event()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ForestUI.INK)
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(ForestUI.EDGE, 0.16))
	for y in range(0, int(size.y), 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(ForestUI.EDGE, 0.16))
	if preview != null:
		var center := preview.joy_center()
		var radius := preview.joy_radius()
		if selected != "joystick":
			for b in preview._buttons():
				if str(b.id) == selected or (selected == "primary" and str(b.id) in ["attack", "dash"]):
					center = b.c
					radius = b.r
		MenuArt.frame_corners(self, Rect2(center - Vector2.ONE * (radius + 8), Vector2.ONE * (radius + 8) * 2), ForestUI.GOLD)
