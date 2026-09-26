class_name SettingsMenu
extends Control

## Configurações padrão de jogo: volumes, teclas, tela cheia e shake.

signal back_pressed

var data: Dictionary = GameSettings.default_data()
var _tick := 0.0
var _capturing := ""
var _rows: Dictionary = {}  # action_id -> Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func build(d: Dictionary) -> void:
	data = d
	_capturing = ""
	for c in get_children():
		c.queue_free()
	_rows.clear()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_right", 120)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var panel := MenuArt.FramePanel.new()
	panel.add_theme_stylebox_override("panel", MenuArt.style_panel())
	margin.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := MenuArt.title_label_gold("CONFIGURAÇÕES", 34)
	vbox.add_child(title)
	vbox.add_child(MenuArt.divider())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	_add_section(box, "— ÁUDIO —")
	_add_slider(box, "Volume geral", "master")
	_add_slider(box, "Música", "music")
	_add_slider(box, "Efeitos", "sfx")

	_add_section(box, "— VÍDEO —")
	_add_toggle(box, "Tela cheia", "fullscreen")
	_add_toggle(box, "Tremor de tela", "shake")
	_add_touch_row(box)
	_add_cycle(box, "Qualidade", "quality", ["Alta", "Média", "Baixa"])
	_add_toggle(box, "Mostrar FPS", "show_fps")

	_add_section(box, "— HUD TOUCH —")
	_add_toggle(box, "Barra de skills", "hud_bar")
	_add_cycle(box, "Tamanho dos botões", "touch_size", ["Pequeno", "Médio", "Grande"])
	_add_cycle(box, "Lado do joystick", "touch_side", ["Esquerda", "Direita"])

	_add_section(box, "— TECLAS (clique e pressione a nova tecla) —")
	for a in GameSettings.ACTIONS:
		_add_key_row(box, a.id, str(a.label))

	var reset := Button.new()
	reset.text = "Restaurar teclas padrão"
	reset.custom_minimum_size = Vector2(1, 36)
	MenuArt.apply_small_btn(reset, MenuArt.GOLD)
	reset.pressed.connect(func():
		GameSettings.reset_keys(data)
		Sfx.play(self, "click")
		_refresh_keys()
	)
	box.add_child(reset)

	var back := Button.new()
	back.name = "Back"
	back.text = "← Voltar"
	back.custom_minimum_size = Vector2(1, 44)
	MenuArt.apply_small_btn(back, MenuArt.GOLD, 18)
	back.pressed.connect(func():
		Sfx.play(self, "click")
		back_pressed.emit()
	)
	vbox.add_child(back)
	_refresh_keys()

func _add_section(parent: VBoxContainer, txt: String) -> void:
	parent.add_child(MenuArt.section_label(txt.trim_prefix("— ").trim_suffix(" —")))

func _add_slider(parent: VBoxContainer, label: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(150, 30)
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", MenuArt.CREAM)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = int(data.get(key, 80))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var val := Label.new()
	val.custom_minimum_size = Vector2(52, 30)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_size_override("font_size", 15)
	val.add_theme_color_override("font_color", MenuArt.CREAM)
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(val)
	val.text = "%d%%" % int(slider.value)
	slider.value_changed.connect(func(v):
		data[key] = int(v)
		val.text = "%d%%" % int(v)
		GameSettings.save_data(data)
		Sfx.apply_volumes(data)
	)

func _add_toggle(parent: VBoxContainer, label: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", MenuArt.CREAM)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	var tgl := Button.new()
	tgl.custom_minimum_size = Vector2(170, 32)
	_refresh_toggle(tgl, key)
	row.add_child(tgl)
	tgl.pressed.connect(func():
		data[key] = not bool(data.get(key, false))
		GameSettings.save_data(data)
		if key == "fullscreen":
			GameSettings.apply_video(data)
		Sfx.play(self, "click")
		_refresh_toggle(tgl, key)
	)

func _refresh_toggle(b: Button, key: String) -> void:
	var on := bool(data.get(key, false))
	b.text = "✔ LIGADO" if on else "✖ DESLIGADO"
	MenuArt.apply_small_btn(b, Color(0.4, 0.85, 0.45) if on else Color(0.8, 0.4, 0.4), 14)

func _add_cycle(parent: VBoxContainer, label: String, key: String, options: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", MenuArt.CREAM)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	var b := Button.new()
	b.custom_minimum_size = Vector2(170, 32)
	_refresh_cycle(b, key, options)
	row.add_child(b)
	var k := key
	var opts := options
	b.pressed.connect(func():
		data[k] = (int(data.get(k, 0)) + 1) % opts.size()
		GameSettings.save_data(data)
		Sfx.play(self, "click")
		_refresh_cycle(b, k, opts)
	)

func _refresh_cycle(b: Button, key: String, options: Array) -> void:
	var idx := clampi(int(data.get(key, 0)), 0, maxi(0, options.size() - 1))
	b.text = str(options[idx])
	MenuArt.apply_small_btn(b, Color(0.55, 0.85, 1), 14)

func _add_touch_row(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var l := Label.new()
	l.text = "Controles touch"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", MenuArt.CREAM)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	var b := Button.new()
	b.custom_minimum_size = Vector2(170, 32)
	_refresh_touch(b)
	row.add_child(b)
	b.pressed.connect(func():
		data["touch"] = (int(data.get("touch", 0)) + 1) % 3
		GameSettings.save_data(data)
		Sfx.play(self, "click")
		_refresh_touch(b)
	)

func _refresh_touch(b: Button) -> void:
	var m := int(data.get("touch", 0))
	b.text = ["No celular", "Sempre", "Nunca"][clampi(m, 0, 2)]
	MenuArt.apply_small_btn(b, Color(0.55, 0.85, 1), 14)

func _add_key_row(parent: VBoxContainer, action_id: String, label: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", MenuArt.CREAM)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 32)
	MenuArt.apply_keycap(b)
	var aid := action_id
	b.pressed.connect(func():
		_capturing = aid
		b.text = "pressione…"
	)
	row.add_child(b)
	_rows[action_id] = b

func _refresh_keys() -> void:
	for aid in _rows.keys():
		var b: Button = _rows[aid]
		var capturing: bool = aid == _capturing
		MenuArt.apply_keycap(b, capturing)
		if capturing:
			b.text = "pressione…"
		else:
			b.text = GameSettings.key_label(data, aid)

func _input(event: InputEvent) -> void:
	if _capturing == "" or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var ke := event as InputEventKey
		var code := int(ke.physical_keycode)
		if code == 0:
			code = int(ke.keycode)
		if code == KEY_ESCAPE:
			_capturing = ""
			_refresh_keys()
			get_viewport().set_input_as_handled()
			return
		var keys: Dictionary = data.get("keys", {})
		keys[_capturing] = [code]
		GameSettings.save_data(data)
		_capturing = ""
		_refresh_keys()
		Sfx.play(self, "click")
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not visible:
		return
	_tick += 1.0
	queue_redraw()

func _draw() -> void:
	MenuArt.draw_back(self, size, _tick)
	MenuArt.draw_screen_frame(self, size)

func handle_key(key: int) -> bool:
	if _capturing != "":
		return true
	if key == KEY_ESCAPE:
		back_pressed.emit()
		return true
	return false
