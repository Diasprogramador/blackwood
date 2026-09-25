class_name MainMenu
extends Control

## Tela-título no clima da referência: nome do jogo em destaque,
## fogueira ao fundo e opções Jogar / Loja / Config / Sair.

signal play_pressed
signal shop_pressed
signal settings_pressed
signal exit_pressed

var essence := 0
var _tick := 0.0
var _buttons: Array[Button] = []
var _focus := 0
var _essence_label: Label = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func build(bank: int) -> void:
	essence = bank
	_focus = 0
	for c in get_children():
		c.queue_free()
	_buttons.clear()
	_essence_label = null

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(1, 60)
	spacer_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer_top)

	var title := MenuArt.title_label_gold("BLACKWOOD", 84)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var sub := MenuArt.title_label("✦ Ecos da Rift ✦", 22)
	sub.add_theme_color_override("font_color", MenuArt.GOLD)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub)
	vbox.add_child(MenuArt.divider())

	var spacer_mid := Control.new()
	spacer_mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer_mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer_mid)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(center)

	var opts := VBoxContainer.new()
	opts.add_theme_constant_override("separation", 10)
	center.add_child(opts)

	_add_opt(opts, "⚔  Jogar  ✧", 0)
	_add_opt(opts, "◆  Loja  ✧", 1)
	_add_opt(opts, "⚙  Configurações  ✧", 2)
	_add_opt(opts, "✕  Sair  ✧", 3)

	var ess_row := HBoxContainer.new()
	ess_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ess_row.add_theme_constant_override("separation", 6)
	ess_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(ess_row)
	var ess_icon := EssenceIcon.new()
	ess_icon.custom_minimum_size = Vector2(20, 20)
	ess_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ess_row.add_child(ess_icon)
	_essence_label = Label.new()
	_essence_label.add_theme_font_size_override("font_size", 15)
	_essence_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1))
	_essence_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ess_row.add_child(_essence_label)

	var hint := Label.new()
	hint.text = "↑ ↓ escolher  •  ENTER confirmar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hint)

	var ver := Label.new()
	ver.text = "Blackwood v1.0  •  Godot 4.7"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 11)
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(ver)

	_refresh()

func _add_opt(parent: VBoxContainer, txt: String, idx: int) -> void:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(300, 48)
	MenuArt.apply_menu_btn(b, MenuArt.GOLD)
	var i := idx
	b.pressed.connect(func(): _activate(i))
	b.mouse_entered.connect(func():
		_focus = i
		_refresh()
	)
	parent.add_child(b)
	_buttons.append(b)

func _refresh() -> void:
	for i in _buttons.size():
		var sb: StyleBoxFlat = _buttons[i].get_theme_stylebox("normal")
		if i == _focus:
			sb = MenuArt.style_btn(MenuArt.GOLD, true)
			_buttons[i].add_theme_stylebox_override("normal", sb)
			_buttons[i].add_theme_color_override("font_color", MenuArt.GOLD)
		else:
			_buttons[i].add_theme_stylebox_override("normal", MenuArt.style_btn(MenuArt.GOLD, false))
			_buttons[i].add_theme_color_override("font_color", MenuArt.CREAM)
	if _essence_label:
		_essence_label.text = "%d Essência" % essence

func _activate(i: int) -> void:
	match i:
		0: play_pressed.emit()
		1: shop_pressed.emit()
		2: settings_pressed.emit()
		_: exit_pressed.emit()

func _process(_delta: float) -> void:
	if not visible:
		return
	_tick += 1.0
	queue_redraw()

func _draw() -> void:
	MenuArt.draw_back(self, size, _tick)
	MenuArt.draw_screen_frame(self, size)

func handle_key(key: int) -> bool:
	if key == KEY_UP or key == KEY_W:
		_focus = (_focus + _buttons.size() - 1) % _buttons.size()
	elif key == KEY_DOWN or key == KEY_S:
		_focus = (_focus + 1) % _buttons.size()
	elif key == KEY_ENTER or key == KEY_KP_ENTER or key == KEY_SPACE:
		_activate(_focus)
		return true
	else:
		return false
	_refresh()
	return true
