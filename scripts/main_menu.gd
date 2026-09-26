class_name MainMenu
extends Control

## Tela-título no clima da referência: nome do jogo em destaque,
## fogueira ao fundo e opções Jogar / Loja / Config / Sair.

signal play_pressed
signal shop_pressed
signal settings_pressed
signal exit_pressed
signal multi_pressed
signal login_pressed

var essence := 0
var _tick := 0.0
var _buttons: Array[Button] = []
var _focus := 0
var _essence_label: Label = null
var _update_btn: Button = null
var _http: HTTPRequest = null

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
	_add_opt(opts, "👥  Multiplayer  ✧", 1)
	_add_opt(opts, "◆  Loja  ✧", 2)
	_add_opt(opts, "⚙  Configurações  ✧", 3)
	_add_opt(opts, "✕  Sair  ✧", 4)

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
	ver.text = "Blackwood v%s" % app_version()
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 11)
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(ver)

	_update_btn = Button.new()
	_update_btn.custom_minimum_size = Vector2(1, 40)
	MenuArt.apply_small_btn(_update_btn, Color(0.4, 0.9, 0.45), 14)
	_update_btn.visible = false
	_update_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_update_btn.pressed.connect(func():
		Sfx.play(self, "click")
		OS.shell_open("https://github.com/Diasprogramador/blackwood/releases/latest")
	)
	vbox.add_child(_update_btn)
	_check_update()

	var login_row := HBoxContainer.new()
	login_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	login_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(login_row)

	var login := Button.new()
	login.text = "👤 %s" % Profiles.current_name()
	login.custom_minimum_size = Vector2(220, 36)
	MenuArt.apply_small_btn(login, Color(0.55, 0.85, 1), 13)
	login.pressed.connect(func():
		Sfx.play(self, "click")
		login_pressed.emit()
	)
	login_row.add_child(login)

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
		1: multi_pressed.emit()
		2: shop_pressed.emit()
		3: settings_pressed.emit()
		_: exit_pressed.emit()

static func app_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))

## Há release nova no GitHub? (falha silenciosa offline)
func _check_update() -> void:
	if _http != null and is_instance_valid(_http):
		_http.queue_free()
	_http = HTTPRequest.new()
	_http.timeout = 8
	add_child(_http)
	_http.request_completed.connect(_on_update_checked)
	_http.request("https://api.github.com/Diasprogramador/blackwood/releases/latest")

func _on_update_checked(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if code != 200 or body.is_empty() or _update_btn == null:
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Dictionary):
		return
	var tag := str((data as Dictionary).get("tag_name", ""))
	if tag != "" and is_newer(app_version(), tag):
		_update_btn.text = "⬇ Atualizar para %s" % tag
		_update_btn.visible = true

static func is_newer(cur: String, remote: String) -> bool:
	var a := _parts(cur)
	var b := _parts(remote)
	var an: Array = a[0]
	var bn: Array = b[0]
	var n := maxi(an.size(), bn.size())
	for i in n:
		var av := int(an[i]) if i < an.size() else 0
		var bv := int(bn[i]) if i < bn.size() else 0
		if bv != av:
			return bv > av
	var asuf := str(a[1])
	var bsuf := str(b[1])
	if asuf == bsuf:
		return false
	if asuf == "":
		return false
	if bsuf == "":
		return true
	return bsuf > asuf

static func _parts(v: String) -> Array:
	var s := v.strip_edges()
	if s.begins_with("v") or s.begins_with("V"):
		s = s.substr(1)
	var suffix := ""
	if s.contains("-"):
		var sp := s.split("-", true, 1)
		s = sp[0]
		suffix = str(sp[1]) if sp.size() > 1 else ""
	var nums := []
	for p in s.split("."):
		nums.append(int(p) if str(p).is_valid_int() else 0)
	return [nums, suffix]

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
