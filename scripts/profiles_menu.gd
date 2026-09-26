class_name ProfilesMenu
extends Control

## Login offline: perfis locais com save próprio (nada se perde).
## Opcional — sem perfil logado o jogo usa o "Jogador".

signal back_pressed
signal picked

var _content: VBoxContainer = null
var _name_edit: LineEdit = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func build() -> void:
	for c in get_children():
		c.queue_free()
	_content = null
	_name_edit = null

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 200)
	margin.add_theme_constant_override("margin_right", 200)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var panel := MenuArt.FramePanel.new()
	panel.add_theme_stylebox_override("panel", MenuArt.style_panel())
	margin.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	var title := MenuArt.title_label_gold("👤  PERFIL", 32)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)
	vbox.add_child(MenuArt.divider())

	var info := Label.new()
	info.text = "O progresso fica salvo neste aparelho.\nTroque de perfil sem perder nada (opcional)."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(info)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 6)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_content)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(row)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nome do novo perfil…"
	_name_edit.max_length = 16
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.custom_minimum_size = Vector2(1, 40)
	row.add_child(_name_edit)

	var add := Button.new()
	add.text = "+ Novo"
	add.custom_minimum_size = Vector2(140, 40)
	MenuArt.apply_small_btn(add, Color(0.4, 0.9, 0.45), 15)
	add.pressed.connect(func():
		Profiles.create(_name_edit.text)
		Sfx.play(self, "buy")
		_refresh()
		picked.emit()
	)
	row.add_child(add)

	var back := Button.new()
	back.text = "← Voltar"
	back.custom_minimum_size = Vector2(1, 44)
	MenuArt.apply_small_btn(back, MenuArt.GOLD, 16)
	back.pressed.connect(func():
		Sfx.play(self, "click")
		back_pressed.emit()
	)
	vbox.add_child(back)

	_refresh()

func _refresh() -> void:
	if _content == null:
		return
	for c in _content.get_children():
		c.queue_free()
	var cur := Profiles.current_id()
	for p in Profiles.list():
		var pid := str((p as Dictionary).get("id", "0"))
		var pname := str((p as Dictionary).get("name", "Jogador"))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content.add_child(row)
		var b := Button.new()
		b.text = ("✔ " if pid == cur else "") + pname
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(1, 42)
		MenuArt.apply_small_btn(b, MenuArt.GOLD if pid == cur else Color(0.55, 0.85, 1), 15)
		var pp := pid
		b.pressed.connect(func():
			Profiles.select(pp)
			Sfx.play(self, "click")
			_refresh()
			picked.emit()
		)
		row.add_child(b)
		var dele := Button.new()
		dele.text = "✖"
		dele.custom_minimum_size = Vector2(52, 42)
		MenuArt.apply_small_btn(dele, Color(0.8, 0.4, 0.4), 14)
		dele.pressed.connect(func():
			if Profiles.remove(pp):
				Sfx.play(self, "click")
			else:
				Sfx.play(self, "error")
			_refresh()
			picked.emit()
		)
		row.add_child(dele)
