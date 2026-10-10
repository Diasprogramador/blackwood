class_name RunUpgradeMenu
extends Control

signal chosen(id: String)
var _offers: Array = []
var _buttons: Array[Button] = []
var _title: Label
var _entrance: Tween
var _panel: PanelContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.025, 0.055, 0.075, 0.93)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	_panel = panel
	panel.custom_minimum_size = Vector2(580, 0)
	center.add_child(panel)
	panel.add_theme_stylebox_override("panel", ForestUI.style(ForestUI.PANEL, ForestUI.GOLD, 26))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var eyebrow := Label.new()
	eyebrow.text = "B L A C K W O O D   /   DÁDIVA DO BOSQUE"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", ForestUI.GOLD)
	eyebrow.add_theme_font_size_override("font_size", 12)
	column.add_child(eyebrow)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	column.add_child(_title)
	var hint := Label.new()
	hint.text = "Escolha seu próximo poder.\n1 / 2 / 3 para escolher • tempo pausado"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	for i in 3:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 92)
		ForestUI.button(button, [ForestUI.MINT, ForestUI.GOLD, Color("a7a0de")][i])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): _choose(i))
		column.add_child(button)
		_buttons.append(button)
	hide()

func open(offers: Array, level: int) -> void:
	_offers = offers.duplicate()
	_title.text = "NÍVEL %02d  ·  FLORESCER" % level
	for i in _buttons.size():
		_buttons[i].visible = i < offers.size()
		if i < offers.size():
			_buttons[i].text = "%d  ·  %s\n%s" % [i + 1, offers[i].title, offers[i].description]
	show()
	if _entrance != null:
		_entrance.kill()
	_panel.modulate.a = 0.0
	_entrance = create_tween()
	_entrance.tween_property(_panel, "modulate:a", 1.0, 0.18)
	if not offers.is_empty():
		_buttons[0].grab_focus()

func _choose(index: int) -> void:
	if not visible or index < 0 or index >= _offers.size():
		return
	var id: String = _offers[index].id
	hide()
	_offers.clear()
	chosen.emit(id)

func _exit_tree() -> void:
	if _entrance != null:
		_entrance.kill()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var index: int = event.physical_keycode - KEY_1
	if index >= 0 and index < _offers.size():
		get_viewport().set_input_as_handled()
		_choose(index)
