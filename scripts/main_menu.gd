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
		remove_child(c)
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

	var masthead := HBoxContainer.new()
	vbox.add_child(masthead)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	masthead.add_child(brand)
	var title := MenuArt.title_label_gold("BLACKWOOD", 66)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	brand.add_child(title)
	var sub := MenuArt.title_label("E C O S   D O   B O S Q U E", 16)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	brand.add_child(sub)
	var seal := Label.new()
	seal.text = "A FLORESTA\nNÃO PERDOA"
	seal.add_theme_color_override("font_color", ForestUI.GOLD)
	seal.add_theme_font_size_override("font_size", 16)
	seal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	masthead.add_child(seal)
	var body_row := HBoxContainer.new()
	body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_theme_constant_override("separation", 28)
	vbox.add_child(body_row)
	var opts := VBoxContainer.new()
	opts.custom_minimum_size.x = 310
	opts.alignment = BoxContainer.ALIGNMENT_CENTER
	opts.add_theme_constant_override("separation", 10)
	body_row.add_child(opts)
	opts.add_child(MenuArt.section_label("A SUA PRÓXIMA CAÇADA"))
	_add_opt(opts, "Entrar no bosque", 0)
	_add_opt(opts, "Jogar em grupo", 1)
	_add_opt(opts, "Arsenal de essência", 2)
	_add_opt(opts, "Configurações", 3)
	_add_opt(opts, "Sair do jogo", 4)
	var hero := CampPortrait.new()
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_row.add_child(hero)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 18)
	vbox.add_child(footer)
	var login := Button.new()
	login.text = Profiles.current_name()
	login.custom_minimum_size = Vector2(170, 44)
	ForestUI.button(login)
	login.pressed.connect(func(): login_pressed.emit())
	footer.add_child(login)
	_essence_label = Label.new()
	_essence_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_essence_label.add_theme_color_override("font_color", ForestUI.MINT)
	footer.add_child(_essence_label)
	_update_btn = Button.new()
	_update_btn.custom_minimum_size.y = 44
	ForestUI.button(_update_btn)
	_update_btn.visible = false
	_update_btn.pressed.connect(func(): OS.shell_open("https://github.com/Diasprogramador/blackwood/releases/latest"))
	footer.add_child(_update_btn)
	var ver := Label.new()
	ver.text = "ECOS DO BOSQUE • v%s" % app_version()
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", ForestUI.PAPER)
	footer.add_child(ver)
	_check_update()

	_refresh()

func _add_opt(parent: VBoxContainer, txt: String, idx: int) -> void:
	var b := Button.new()
	b.text = txt
	b.icon = load("res://assets/icons/%s.svg" % ["hunt", "party", "shop", "settings", "exit"][idx])
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 28)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(310, 52)
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
	_http.request("https://api.github.com/repos/Diasprogramador/blackwood/releases/latest")

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

func _process(delta: float) -> void:
	if not visible:
		return
	_tick = MenuArt.back_tick(self, delta, _tick)[0]

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

class CampPortrait extends Control:
	var figures: Array[Sprite2D] = []
	func _ready() -> void:
		for role in ["marksman", "tank", "mage"]:
			var sprite := Sprite2D.new()
			sprite.texture = CanvaSprites.frame(role, 0)
			sprite.material = CanvaSprites.material()
			add_child(sprite)
			figures.append(sprite)
		resized.connect(_layout)
		_layout()
	func _layout() -> void:
		for i in figures.size():
			var k := minf(size.x / 460.0, size.y / 380.0)
			figures[i].scale = Vector2.ONE * k * (1.9 if i == 1 else 1.5)
			figures[i].position = Vector2(size.x * (0.21 + i * 0.29), size.y * 0.45)
		queue_redraw()
	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y * 0.72)
		ArtUtil.fill_ellipse(self, c.x, c.y, size.x * 0.46, 32, Color(ForestUI.INK, 0.8))
		draw_arc(c, size.x * 0.35, PI, TAU, 40, Color(ForestUI.GOLD, 0.4), 2)
		var font := ThemeDB.fallback_font
		var text := "CINCO GUARDIÕES. UMA ÚLTIMA FOGUEIRA."
		var fs := 13
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2((size.x - width) / 2, size.y - 40), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ForestUI.GOLD)
		text = "Sobreviva às hordas. Escolha sua evolução."
		width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2((size.x - width) / 2, size.y - 18), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ForestUI.PAPER)
