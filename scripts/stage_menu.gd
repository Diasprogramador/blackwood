class_name StageMenu
extends Control

## Passo 2 do Jogar: escolher fase + dificuldade (tela própria, sem mistura).

signal back_pressed
signal shop_pressed
signal start_pressed(stage: int, diff: int)

var progress: Dictionary = StageData.default_progress()
var selected_stage := 0
var selected_diff := 0
var _tick := 0.0
var _stage_btns: Array[Button] = []
var _diff_btns: Array[Button] = []
var _essence_label: Label = null
var _info_label: Label = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func build(prog: Dictionary, stage: int, diff: int) -> void:
	progress = prog
	selected_stage = stage
	selected_diff = diff
	if not StageData.is_stage_unlocked(progress, selected_stage):
		selected_stage = 0
	if not StageData.is_diff_unlocked(progress, selected_stage, selected_diff):
		selected_diff = 0
	for c in get_children():
		c.queue_free()
	_stage_btns.clear()
	_diff_btns.clear()
	_essence_label = null
	_info_label = null

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var title := MenuArt.title_label("ESCOLHA A FASE", 40)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

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

	var st_title := _section("— FASE (passe para liberar a próxima) —")
	vbox.add_child(st_title)
	var stage_row := HBoxContainer.new()
	stage_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_row.add_theme_constant_override("separation", 12)
	stage_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stage_row)
	for s in StageData.STAGES.size():
		stage_row.add_child(_make_stage_btn(s))

	vbox.add_child(_section("— DIFICULDADE (passe para liberar a próxima) —"))
	var diff_row := HBoxContainer.new()
	diff_row.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_row.add_theme_constant_override("separation", 12)
	diff_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(diff_row)
	for d in StageData.DIFFS.size():
		diff_row.add_child(_make_diff_btn(d))

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
		back_pressed.emit()
	)
	nav.add_child(back)

	var go := Button.new()
	go.name = "Go"
	go.text = "COMEÇAR ✧"
	go.custom_minimum_size = Vector2(260, 50)
	MenuArt.apply_menu_btn(go, Color(0.4, 0.9, 0.45))
	go.pressed.connect(func(): _try_start())
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

func _section(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", MenuArt.GOLD)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _make_stage_btn(s: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(250, 74)
	MenuArt.apply_small_btn(b, Color(0.5, 0.8, 0.5), 14)
	var idx := s
	b.pressed.connect(func():
		if StageData.is_stage_unlocked(progress, idx):
			selected_stage = idx
			if not StageData.is_diff_unlocked(progress, selected_stage, selected_diff):
				selected_diff = 0
			Sfx.play(self, "click")
			_refresh()
		else:
			Sfx.play(self, "error")
	)
	_stage_btns.append(b)
	return b

func _make_diff_btn(d: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(160, 52)
	MenuArt.apply_small_btn(b, Color(1, 0.85, 0.4), 15)
	var idx := d
	b.pressed.connect(func():
		if StageData.is_diff_unlocked(progress, selected_stage, idx):
			selected_diff = idx
			Sfx.play(self, "click")
			_refresh()
		else:
			Sfx.play(self, "error")
	)
	_diff_btns.append(b)
	return b

func _refresh() -> void:
	for s in _stage_btns.size():
		var b := _stage_btns[s]
		var st: Dictionary = StageData.STAGES[s]
		var st_col: Color = st.get("color", Color.WHITE)
		if not StageData.is_stage_unlocked(progress, s):
			b.text = "🔒 Fase %d\n???" % (s + 1)
			b.disabled = true
			b.modulate = Color(0.5, 0.5, 0.55)
		else:
			var mark := " ✔" if StageData.is_cleared(progress, s, selected_diff) else ""
			b.text = "Fase %d: %s%s\nBoss: %s" % [s + 1, str(st.get("name", "?")), mark, str(st.get("boss", "?"))]
			b.disabled = false
			b.modulate = Color.WHITE
			var sel := s == selected_stage
			b.add_theme_stylebox_override("normal", MenuArt.style_btn(st_col, sel))
			b.add_theme_color_override("font_color", Color.WHITE if sel else MenuArt.CREAM)
	for d in _diff_btns.size():
		var b := _diff_btns[d]
		var dd: Dictionary = StageData.DIFFS[d]
		var d_col: Color = dd.get("color", Color.WHITE)
		if not StageData.is_diff_unlocked(progress, selected_stage, d):
			b.text = "🔒 %s" % str(dd.get("name", "?"))
			b.disabled = true
			b.modulate = Color(0.5, 0.5, 0.55)
		else:
			var mark := " ✔" if StageData.is_cleared(progress, selected_stage, d) else ""
			b.text = "%s%s" % [str(dd.get("name", "?")), mark]
			b.disabled = false
			b.modulate = Color.WHITE
			var sel := d == selected_diff
			b.add_theme_stylebox_override("normal", MenuArt.style_btn(d_col, sel))
			b.add_theme_color_override("font_color", d_col if sel else MenuArt.CREAM)
	if _essence_label:
		_essence_label.text = "%d Essência" % StageData.essence(progress)
	if _info_label:
		var gw := StageData.global_wave(selected_stage, 0)
		_info_label.text = "Ondas %d-%d  •  %s + %s  •  ↑ ↓ fase  •  Q/E dificuldade" % [
			gw, gw + 4, StageData.stage_name(selected_stage), StageData.diff_name(selected_diff)]

func _try_start() -> void:
	if not StageData.is_stage_unlocked(progress, selected_stage):
		return
	if not StageData.is_diff_unlocked(progress, selected_stage, selected_diff):
		return
	Sfx.play(self, "click")
	start_pressed.emit(selected_stage, selected_diff)

func _process(_delta: float) -> void:
	if not visible:
		return
	_tick += 1.0
	queue_redraw()

func _draw() -> void:
	MenuArt.draw_back(self, size, _tick)

func handle_key(key: int) -> bool:
	if key == KEY_UP or key == KEY_W:
		_cycle_stage(-1)
		return true
	elif key == KEY_DOWN or key == KEY_S:
		_cycle_stage(1)
		return true
	elif key == KEY_Q:
		_cycle_diff(-1)
		return true
	elif key == KEY_E:
		_cycle_diff(1)
		return true
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_try_start()
		return true
	elif key == KEY_ESCAPE:
		back_pressed.emit()
		return true
	return false

func _cycle_stage(dir: int) -> void:
	var s := selected_stage
	for i in StageData.STAGES.size():
		s = (s + dir + StageData.STAGES.size()) % StageData.STAGES.size()
		if StageData.is_stage_unlocked(progress, s):
			selected_stage = s
			if not StageData.is_diff_unlocked(progress, selected_stage, selected_diff):
				selected_diff = 0
			Sfx.play(self, "click")
			_refresh()
			return

func _cycle_diff(dir: int) -> void:
	var d := selected_diff
	for i in StageData.DIFFS.size():
		d = (d + dir + StageData.DIFFS.size()) % StageData.DIFFS.size()
		if StageData.is_diff_unlocked(progress, selected_stage, d):
			selected_diff = d
			Sfx.play(self, "click")
			_refresh()
			return
