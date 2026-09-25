class_name ChampSelect
extends Control

## Passo 1 do Jogar: só o campeão (fase e loja ficaram em telas próprias).

signal chosen(champ: int)
signal backed
signal shop_pressed

const CARD_W := 150.0
const CARD_H := 300.0
const GAP := 20.0

var selected_index := 2
var progress: Dictionary = StageData.default_progress()
var _tick := 0.0
var _cards: Array[PanelContainer] = []
var _portraits: Array[Portrait] = []
var _info_label: Label = null

## Retrato: sprite real do kit (idle) com fallback procedural.
class Portrait extends Control:
	var role := "mage"
	var tick := 0.0
	var active := false
	var accent := Color.WHITE
	var tex: Texture2D = null

	func _draw() -> void:
		var bob := sin(tick * 0.08) * 3.0
		var cx := size.x / 2.0
		if active:
			var aura := 44.0 + sin(tick * 0.1) * 7.0
			draw_circle(Vector2(cx, 48), aura, Color(accent.r, accent.g, accent.b, 0.25))
		if tex != null:
			var tw := float(tex.get_width())
			var th := float(tex.get_height())
			var sc := minf(size.x / tw, 118.0 / th)
			var dw := tw * sc
			var dh := th * sc
			draw_texture_rect(tex, Rect2(cx - dw / 2.0, 56.0 - dh / 2.0 + bob, dw, dh), false)
			return
		var cy := 60.0
		var bobi := int(bob)
		draw_set_transform(Vector2(cx, cy), 0, Vector2.ONE)
		ChampionArt.draw_champion(self, role, bobi, false, tick * 0.08, false, 0.0)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

## Barra de stat desenhada em _draw.
class StatBar extends Control:
	var label := "HP"
	var val := 100
	var mx := 150
	var col := Color.GREEN

	func _draw() -> void:
		var w := size.x
		draw_rect(Rect2(0, 0, w, 12), Color(0, 0, 0, 0.6))
		var ratio: float = clampf(val / float(maxi(1, mx)), 0.0, 1.0)
		draw_rect(Rect2(0, 0, w * ratio, 12), col)
		draw_rect(Rect2(0, 0, w, 12), Color(0, 0, 0, 0.5), false, 1.0)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(4, 10), "%s %d" % [label, val],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func build(prog: Dictionary, champ_idx: int) -> void:
	progress = prog
	selected_index = clampi(champ_idx, 0, ChampData.CHAMPS.size() - 1)
	for c in get_children():
		c.queue_free()
	_cards.clear()
	_portraits.clear()
	_info_label = null

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var title := MenuArt.title_label_gold("ESCOLHA SEU CAMPEÃO", 40)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "← → ou clique para escolher  •  ENTER avança para a fase"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub)
	vbox.add_child(MenuArt.divider())

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(center)

	var row := HBoxContainer.new()
	row.name = "Cards"
	row.add_theme_constant_override("separation", GAP)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(row)

	var champs: Array = ChampData.CHAMPS
	for i in champs.size():
		var c: Dictionary = champs[i]
		row.add_child(_make_card(c, i))

	_info_label = Label.new()
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", 14)
	_info_label.add_theme_color_override("font_color", MenuArt.CREAM)
	_info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_info_label)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	nav.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(nav)

	var back := Button.new()
	back.text = "← Voltar"
	back.custom_minimum_size = Vector2(200, 50)
	MenuArt.apply_menu_btn(back, MenuArt.GOLD)
	back.pressed.connect(func():
		Sfx.play(self, "click")
		backed.emit()
	)
	nav.add_child(back)

	var go := Button.new()
	go.text = "Avançar →"
	go.custom_minimum_size = Vector2(200, 50)
	MenuArt.apply_menu_btn(go, Color(0.4, 0.9, 0.45))
	go.pressed.connect(func(): _confirm())
	nav.add_child(go)

	var shop := Button.new()
	shop.text = "LOJA ◆"
	shop.custom_minimum_size = Vector2(160, 50)
	MenuArt.apply_menu_btn(shop, Color(0.55, 0.85, 1))
	shop.pressed.connect(func():
		Sfx.play(self, "click")
		shop_pressed.emit()
	)
	nav.add_child(shop)

	_refresh()

func _make_card(c: Dictionary, i: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var col: Color = c.color
	card.add_theme_stylebox_override("panel", MenuArt.style_card(col, i == selected_index))

	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 4)
	card.add_child(inner)

	var portrait := Portrait.new()
	portrait.role = c.role
	portrait.accent = c.color
	portrait.tex = SpriteKit.tex(SpriteKit.champ_pose(c.role, "idle"))
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(CARD_W - 16, 110)
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(portrait)
	_portraits.append(portrait)

	var name_lbl := Label.new()
	name_lbl.text = c.nome
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	inner.add_child(name_lbl)

	var role_lbl := Label.new()
	role_lbl.text = ChampData.ROLES[c.role].display
	role_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_lbl.add_theme_font_size_override("font_size", 13)
	role_lbl.add_theme_color_override("font_color", c.color)
	inner.add_child(role_lbl)

	var stats := VBoxContainer.new()
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_theme_constant_override("separation", 4)
	_add_stat(stats, "HP", int(ChampData.ROLES[c.role].hp), 150, Color(0.2, 0.8, 0.3))
	_add_stat(stats, "ATK", int(ChampData.ROLES[c.role].atk), 20, Color(0.9, 0.3, 0.3))
	_add_stat(stats, "MAG", int(ChampData.ROLES[c.role].mag), 20, Color(0.55, 0.35, 1))
	inner.add_child(stats)

	var key_lbl := Label.new()
	key_lbl.text = "[%d] %s" % [i + 1, c.desc.split("\n")[0]]
	key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_lbl.add_theme_font_size_override("font_size", 11)
	key_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	inner.add_child(key_lbl)

	var idx := i
	card.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if selected_index == idx:
				_confirm()
			else:
				selected_index = idx
				Sfx.play(self, "click")
				_refresh()
	)
	_cards.append(card)
	return card

func _add_stat(parent: VBoxContainer, label: String, val: int, mx: int, col: Color) -> void:
	var bar := StatBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.label = label
	bar.val = val
	bar.mx = mx
	bar.col = col
	bar.custom_minimum_size = Vector2(CARD_W - 30, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(bar)

func _refresh() -> void:
	for i in _cards.size():
		var sel := i == selected_index
		var col: Color = ChampData.CHAMPS[i].color
		_cards[i].add_theme_stylebox_override("panel", MenuArt.style_card(col, sel))
		_cards[i].queue_redraw()
		if i < _portraits.size():
			_portraits[i].active = sel
			_portraits[i].queue_redraw()
	if _info_label:
		var role: String = ChampData.CHAMPS[selected_index].role
		var n := StageData.unlocked_count(progress, role)
		_info_label.text = "◆ %d Essência   •   %d/%d habilidades de %s (compre na LOJA)" % [
			StageData.essence(progress), n, ChampData.SKILL_SLOTS, ChampData.CHAMPS[selected_index].nome]

func _confirm() -> void:
	Sfx.play(self, "click")
	chosen.emit(selected_index)

func _process(_delta: float) -> void:
	if not visible:
		return
	_tick += 1.0
	for p in _portraits:
		p.tick = _tick
		p.queue_redraw()
	queue_redraw()

func _draw() -> void:
	MenuArt.draw_back(self, size, _tick)

func handle_key(key: int) -> bool:
	var n: int = ChampData.CHAMPS.size()
	if key == KEY_LEFT or key == KEY_A:
		selected_index = (selected_index + n - 1) % n
	elif key == KEY_RIGHT or key == KEY_D:
		selected_index = (selected_index + n + 1) % n
	elif key >= KEY_1 and key <= KEY_5:
		selected_index = key - KEY_1
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_confirm()
		return true
	elif key == KEY_ESCAPE:
		backed.emit()
		return true
	else:
		return false
	_refresh()
	return true
