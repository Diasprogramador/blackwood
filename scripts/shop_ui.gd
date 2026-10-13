class_name ShopUI
extends Control

## Provisões compradas com ouro; poderes são escolhas de nível.

signal closed

var main  # Main
var _rows: Array[Button] = []
var _item_rows: Array[Button] = []
var _gold_label: Label
var _stats_label: Label
var _inv_label: Label
var _shop_items: Array = []
var _gold_delta: Label
var _last_gold := -1
var _delta_t := 0.0

func _ready() -> void:
	# (tamanho full-rect aplicado pelo criador ANTES do add_child — ver main.gd)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()

func _build() -> void:
	# fundo escurecido com tom de mata (integrado ao cenário)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.09, 0.05, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# centralizado via container (sem conta manual de posição)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	add_child(center)

	# painel central
	var panel := MenuArt.FramePanel.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(580, 580)
	center.add_child(panel)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.075, 0.115, 0.085, 0.97)  # verde-musgo escuro
	sb.border_color = Color(0.79, 0.64, 0.15)        # dourado
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)
	# borda interna sutil de "madeira"
	sb.border_width_bottom = 3
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# cabeçalho
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "PROVISÕES DO BOSQUE"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.8, 0.35))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	header.add_child(_gold_label)

	_gold_delta = Label.new()
	_gold_delta.add_theme_font_size_override("font_size", 14)
	_gold_delta.add_theme_color_override("font_color", Color(0.5, 1, 0.55))
	header.add_child(_gold_delta)
	var close_button := Button.new()
	close_button.text = "FECHAR"
	close_button.custom_minimum_size = Vector2(80,44)
	ForestUI.button(close_button)
	close_button.add_theme_font_size_override("font_size",13)
	close_button.pressed.connect(func(): main._close_shop())
	header.add_child(close_button)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 13)
	_stats_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.72))
	vbox.add_child(_stats_label)

	_inv_label = Label.new()
	_inv_label.add_theme_font_size_override("font_size", 12)
	_inv_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.85))
	vbox.add_child(_inv_label)

	var tagline := Label.new()
	tagline.text = "Use ouro em itens. Novos poderes são escolhidos ao subir de nível."
	tagline.add_theme_font_size_override("font_size", 12)
	tagline.add_theme_color_override("font_color", Color(0.75, 0.7, 0.5, 0.9))
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tagline)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.79, 0.64, 0.15, 0.5))
	vbox.add_child(sep)

	# rolagem do meio (conteúdo maior que a tela não vaza mais)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var scrollbox := VBoxContainer.new()
	scrollbox.add_theme_constant_override("separation", 6)
	scrollbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scrollbox)

	var item_title := Label.new()
	item_title.text = "✦  ITENS DA LOJA"
	item_title.add_theme_font_size_override("font_size", 16)
	item_title.add_theme_color_override("font_color", Color(0.55, 0.85, 0.95))
	scrollbox.add_child(item_title)

	# seção de itens (port do shop do GameManager.java)
	_shop_items = [
		HealthPotion.new(ItemType.HEALTH_POTION, 100),
		ManaPotion.new(ItemType.MANA_POTION, 80),
		Elixir.new(ItemType.ELIXIR, 200, 150),
		Equipment.new(ItemType.ATTACK_BOOTS, "ATK", 5),
		Equipment.new(ItemType.DEFENSE_ARMOR, "DEF", 8),
		Equipment.new(ItemType.MAGIC_ROBE, "MAG", 7),
	]
	var item_icons := ["♥", "💧", "✦", "⚔", "🛡", "◎"]
	var item_accents := [
		Color(0.9, 0.35, 0.35), Color(0.35, 0.65, 1), Color(0.75, 0.45, 1),
		Color(0.95, 0.65, 0.25), Color(0.55, 0.6, 0.7), Color(0.6, 0.85, 1),
	]
	var _item_keys := ["7", "8", "9", "0", "Q", "R"]
	for i in _shop_items.size():
		var it: Item = _shop_items[i]
		var row := Button.new()
		row.custom_minimum_size = Vector2(530, 54)
		row.flat = false
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.text = "  [%s]  %s  %s\n          %s" % [_item_keys[i], item_icons[i], it.name, it.description]
		row.tooltip_text = it.description

		var row_sb := StyleBoxFlat.new()
		row_sb.bg_color = Color(0.1, 0.14, 0.18, 0.95)
		row_sb.border_color = Color(item_accents[i].r, item_accents[i].g, item_accents[i].b, 0.85)
		row_sb.set_border_width_all(1)
		row_sb.border_width_left = 5
		row_sb.set_corner_radius_all(8)
		row_sb.set_content_margin_all(6)
		row_sb.content_margin_left = 12
		row.add_theme_stylebox_override("normal", row_sb)

		var row_hover := row_sb.duplicate()
		row_hover.bg_color = Color(0.13, 0.19, 0.24, 0.98)
		row_hover.border_color = Color(item_accents[i].r, item_accents[i].g, item_accents[i].b, 1.0)
		row.add_theme_stylebox_override("hover", row_hover)

		var row_press := row_sb.duplicate()
		row_press.bg_color = Color(0.16, 0.24, 0.3, 1)
		row_press.border_color = Color(0.7, 0.9, 1)
		row.add_theme_stylebox_override("pressed", row_press)

		row.add_theme_color_override("font_color", Color(0.88, 0.93, 0.96))
		row.add_theme_color_override("font_hover_color", Color.WHITE)
		row.add_theme_color_override("font_pressed_color", MenuArt.GOLD)
		row.add_theme_stylebox_override("focus", ForestUI.style(Color(0,0,0,0), ForestUI.GOLD,0))
		row.add_theme_font_size_override("font_size", 14)

		var cost := Label.new()
		cost.name = "Cost"
		cost.add_theme_font_size_override("font_size", 14)
		cost.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		cost.offset_left = -95
		cost.offset_right = -14
		cost.offset_top = 10
		cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost.custom_minimum_size = Vector2(80,22)
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(cost)

		var idx := i
		row.pressed.connect(func(): _on_buy_item(idx))
		scrollbox.add_child(row)
		_item_rows.append(row)

	var footer := Label.new()
	footer.text = "7/8/9/0/Q/R comprar itens  •  TAB/ESC fechar"
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.7, 0.75, 0.68, 0.85))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(footer)

func _process(delta: float) -> void:
	if _delta_t > 0.0:
		_delta_t -= delta
		_gold_delta.modulate = Color(1, 1, 1, clampf(_delta_t / 1.5, 0.0, 1.0))
		if _delta_t <= 0.0:
			_gold_delta.text = ""

func open() -> void:
	visible = true
	_refresh()
	var panel := get_node("Center/Panel")
	panel.pivot_offset = Vector2(290, 290)
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate = Color(1, 1, 1, 0.6)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate", Color.WHITE, 0.14)

func close() -> void:
	visible = false
	closed.emit()

func _refresh() -> void:
	if main == null or main.player == null:
		return
	var p: Player = main.player
	_gold_label.text = "◉ %d" % p.gold
	if _last_gold >= 0 and p.gold != _last_gold:
		var diff := p.gold - _last_gold
		_gold_delta.text = "+%d" % diff if diff > 0 else "%d" % diff
		_gold_delta.add_theme_color_override("font_color",
			Color(0.5, 1, 0.55) if diff > 0 else Color(1, 0.5, 0.45))
		_gold_delta.modulate = Color.WHITE
		_delta_t = 1.5
	_last_gold = p.gold
	_stats_label.text = "HP %d/%d   ATK %d   DEF %d   MAG %d   CRIT %d%%   Lv.%d" % [
		p.hp, p.max_hp, p.attack, p.defense, p.magic,
		int(p.crit_chance * 100), p.level
	]
	_inv_label.text = "Inventário %d/%d  |  Arma: %s  |  Armadura: %s" % [
		p.inventory.size(), Player.MAX_INVENTORY,
		p.weapon.name if p.weapon else "—",
		p.armor.name if p.armor else "—",
	]
	for i in _item_rows.size():
		var row := _item_rows[i]
		var it: Item = _shop_items[i]
		var can := p.gold >= it.price
		var cost_lbl: Label = row.get_node("Cost")
		cost_lbl.text = "%d ⬤" % it.price
		cost_lbl.add_theme_color_override("font_color",
			Color(1, 0.85, 0.3) if can else Color(0.85, 0.4, 0.35))
		row.modulate = Color.WHITE if can else Color(0.55, 0.55, 0.6)

func _on_buy_item(idx: int) -> void:
	if main == null or main.player == null:
		return
	if main.mp == 2:
		main.mp_buy_item(idx)
		return
	var p: Player = main.player
	var clone: Item = main._clone_shop_item(_shop_items[idx])
	if clone == null:
		return
	if p.buy_item(clone):
		main.hud.add_message("Comprado: %s" % clone.name)
		Sfx.play(self, "buy")
	else:
		main.hud.add_message("Gold insuficiente!")
		Sfx.play(self, "error")
	_refresh()

func handle_key(key: int) -> bool:
	if not visible:
		return false
	if key == KEY_TAB or key == KEY_ESCAPE:
		close()
		return true
	# itens: 7-9 e 0 (teclas numéricas do teclado principal)
	match key:
		KEY_7: _on_buy_item(0)
		KEY_8: _on_buy_item(1)
		KEY_9: _on_buy_item(2)
		KEY_0: _on_buy_item(3)
		KEY_Q: _on_buy_item(4)
		KEY_R: _on_buy_item(5)
		_:
			pass
	return true  # consome todas as teclas com loja aberta
