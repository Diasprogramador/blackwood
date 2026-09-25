class_name MenuShop
extends Control

## Loja do menu (botão LOJA): habilidades com ◆ por campeão
## + suprimentos (poções iniciais) com ◆. Separada da loja da run (TAB/gold).

signal back_pressed

var progress: Dictionary = StageData.default_progress()
var champ := 2
var tab := 0  # 0 = habilidades, 1 = suprimentos
var _tick := 0.0
var _essence_label: Label = null
var _content: VBoxContainer = null
var _champ_row: HBoxContainer = null
var _tab_row: HBoxContainer = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func build(prog: Dictionary, champ_idx: int) -> void:
	progress = prog
	champ = clampi(champ_idx, 0, ChampData.CHAMPS.size() - 1)
	for c in get_children():
		c.queue_free()
	_essence_label = null
	_content = null
	_champ_row = null
	_tab_row = null

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var panel := MenuArt.FramePanel.new()
	panel.add_theme_stylebox_override("panel", MenuArt.style_panel())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	var title := MenuArt.title_label_gold("⚜  LOJA", 34)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)
	vbox.add_child(MenuArt.divider())

	var ess_row := HBoxContainer.new()
	ess_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ess_row.add_theme_constant_override("separation", 6)
	ess_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(ess_row)
	var ess_icon := EssenceIcon.new()
	ess_icon.custom_minimum_size = Vector2(22, 22)
	ess_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ess_row.add_child(ess_icon)
	_essence_label = Label.new()
	_essence_label.add_theme_font_size_override("font_size", 16)
	_essence_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1))
	_essence_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ess_row.add_child(_essence_label)

	_champ_row = HBoxContainer.new()
	_champ_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_champ_row.add_theme_constant_override("separation", 8)
	_champ_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_champ_row)
	for i in ChampData.CHAMPS.size():
		_champ_row.add_child(_make_champ_btn(i))

	_tab_row = HBoxContainer.new()
	_tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_tab_row.add_theme_constant_override("separation", 8)
	_tab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_tab_row)
	_tab_row.add_child(_make_tab_btn("Habilidades ◆", 0))
	_tab_row.add_child(_make_tab_btn("Suprimentos ◆", 1))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(scroll)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 6)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(_content)

	var back := Button.new()
	back.text = "← Voltar"
	back.custom_minimum_size = Vector2(1, 42)
	MenuArt.apply_small_btn(back, MenuArt.GOLD, 18)
	back.pressed.connect(func():
		Sfx.play(self, "click")
		back_pressed.emit()
	)
	vbox.add_child(back)

	_refresh()

func _make_champ_btn(i: int) -> Button:
	var c: Dictionary = ChampData.CHAMPS[i]
	var b := Button.new()
	b.text = c.nome
	b.custom_minimum_size = Vector2(120, 34)
	var col: Color = c.color
	MenuArt.apply_small_btn(b, col, 13)
	var idx := i
	b.pressed.connect(func():
		champ = idx
		Sfx.play(self, "click")
		_refresh()
	)
	return b

func _make_tab_btn(txt: String, idx: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(220, 36)
	MenuArt.apply_small_btn(b, MenuArt.GOLD, 15)
	var t := idx
	b.pressed.connect(func():
		tab = t
		Sfx.play(self, "click")
		_refresh()
	)
	return b

func _refresh() -> void:
	if _essence_label:
		_essence_label.text = "%d Essência — ganhe limpando ondas e zerando fases" % StageData.essence(progress)
	# destaque do campeão
	for i in _champ_row.get_child_count():
		var b := _champ_row.get_child(i) as Button
		if b == null:
			continue
		var col: Color = ChampData.CHAMPS[i].color
		b.add_theme_stylebox_override("normal", MenuArt.style_btn(col, i == champ))
		b.add_theme_color_override("font_color", Color.WHITE if i == champ else MenuArt.CREAM)
	# destaque das abas
	for i in _tab_row.get_child_count():
		var b := _tab_row.get_child(i) as Button
		if b == null:
			continue
		b.add_theme_stylebox_override("normal", MenuArt.style_btn(MenuArt.GOLD, i == tab))
		b.add_theme_color_override("font_color", MenuArt.GOLD if i == tab else MenuArt.CREAM)
	# conteúdo
	for c in _content.get_children():
		c.queue_free()
	if tab == 0:
		_build_skill_rows()
	else:
		_build_supply_rows()

func _row_base(accent: Color) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(1, 56)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	MenuArt.apply_row_btn(b, accent)
	b.add_theme_color_override("font_color", MenuArt.CREAM)
	b.add_theme_font_size_override("font_size", 14)
	return b

func _build_skill_rows() -> void:
	var role: String = ChampData.CHAMPS[champ].role
	var cfgs: Array = ChampData.ROLES[role].skills
	var bank := StageData.essence(progress)
	for i in cfgs.size():
		var cfg: Dictionary = cfgs[i]
		var rcol := ChampData.rarity_color(int(cfg.get("rarity", 0)))
		var rname := ChampData.rarity_name(int(cfg.get("rarity", 0)))
		var price := int(cfg.get("price", 0))
		var is_unl := StageData.is_skill_unlocked(progress, role, i)
		var b := _row_base(rcol)
		var glyph := SkillIcon.glyph(role, str(cfg.get("kind", "damage")), i)
		if is_unl:
			b.text = "  %s ✔ [%d] %s — %s  •  %d mana • poder %d • CD %.0fs\n       %s" % [
				glyph, i + 1, str(cfg.get("name", "?")), rname, int(cfg.get("mana", 0)),
				int(cfg.get("power", 0)), float(cfg.get("cd", 0.0)), str(cfg.get("desc", ""))]
			b.disabled = true
			b.modulate = Color.WHITE
		else:
			b.text = "  %s [%d] %s — %s  •  ◆%d\n       %s" % [
				glyph, i + 1, str(cfg.get("name", "?")), rname, price, str(cfg.get("desc", ""))]
			var afford := bank >= price
			b.modulate = Color.WHITE if afford else Color(0.55, 0.55, 0.6)
			var idx := i
			var pr := price
			b.pressed.connect(func():
				if StageData.unlock_skill(progress, role, idx, pr):
					Sfx.play(self, "buy")
				else:
					Sfx.play(self, "error")
				_refresh()
			)
		_content.add_child(b)

func _build_supply_rows() -> void:
	var bank := StageData.essence(progress)
	for spec in StageData.SUPPLIES:
		var sid := str(spec.get("id", ""))
		var owned := StageData.supply_owned(progress, sid)
		var maxed := owned >= int(spec.get("max", 1))
		var price := StageData.supply_price(progress, sid)
		var b := _row_base(Color(0.55, 0.85, 0.95))
		if maxed:
			b.text = "  ✔ %s (%d/%d)\n       %s" % [
				str(spec.get("name", "?")), owned, int(spec.get("max", 1)), str(spec.get("desc", ""))]
			b.disabled = true
			b.modulate = Color.WHITE
		else:
			b.text = "  %s (%d/%d)  •  ◆%d\n       %s" % [
				str(spec.get("name", "?")), owned, int(spec.get("max", 1)), price, str(spec.get("desc", ""))]
			var afford := bank >= price
			b.modulate = Color.WHITE if afford else Color(0.55, 0.55, 0.6)
			b.pressed.connect(func():
				if StageData.buy_supply(progress, sid):
					Sfx.play(self, "buy")
				else:
					Sfx.play(self, "error")
				_refresh()
			)
		_content.add_child(b)
	var note := Label.new()
	note.text = "Suprimentos entram no inventário no início de cada run."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(note)

func _process(_delta: float) -> void:
	if not visible:
		return
	_tick += 1.0
	queue_redraw()

func _draw() -> void:
	MenuArt.draw_back(self, size, _tick)
	MenuArt.draw_screen_frame(self, size)

func handle_key(key: int) -> bool:
	if key == KEY_ESCAPE:
		back_pressed.emit()
		return true
	if key == KEY_1:
		tab = 0
		_refresh()
		return true
	if key == KEY_2:
		tab = 1
		_refresh()
		return true
	return false
