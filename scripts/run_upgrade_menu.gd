class_name RunUpgradeMenu
extends Control

signal chosen(id: String)
var _offers: Array = []
var _buttons: Array[Button] = []
var _title: Label
var _hint: Label
var _armed := false

class GiftCard extends Button:
	var gift: Dictionary = {}
	var rank := 1
	var slot := 0
	var accent := ForestUI.MINT
	func _ready() -> void:
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
	func _draw() -> void:
		var active := is_hovered() or has_focus()
		ForestUI.frame(self, Rect2(Vector2.ZERO,size), accent if active else ForestUI.EDGE)
		var c := Vector2(size.x/2, 82)
		draw_circle(c, 49, Color(accent,0.07))
		draw_arc(c, 43, -PI*0.8, PI*0.8, 32, Color(accent,0.45), 1.5, true)
		var diamond := PackedVector2Array([c+Vector2(0,-35),c+Vector2(35,0),c+Vector2(0,35),c+Vector2(-35,0),c+Vector2(0,-35)])
		draw_polyline(diamond, accent, 2, true)
		match str(gift.get("id","")):
			"power", "strikes":
				for offset in ([-9,9] if gift.id == "strikes" else [0]):
					var p := c+Vector2(offset,0)
					draw_line(p+Vector2(-10,18),p+Vector2(10,-18),accent,4,true)
					draw_line(p+Vector2(-12,5),p+Vector2(5,14),accent,3,true)
			"haste", "speed":
				for y in [-10,6]:
					draw_polyline(PackedVector2Array([c+Vector2(-16,y+8),c+Vector2(0,y-5),c+Vector2(16,y+8)]),accent,4,true)
			"aura":
				draw_arc(c,17,0,TAU,32,accent,3,true)
				for i in 8:
					var d := Vector2.from_angle(i*TAU/8)
					draw_line(c+d*19,c+d*26,accent,3,true)
			"vitality":
				draw_polyline(PackedVector2Array([c+Vector2(-17,-14),c+Vector2(17,-14),c+Vector2(13,8),c+Vector2(0,23),c+Vector2(-13,8),c+Vector2(-17,-14)]),accent,3,true)
				draw_line(c+Vector2(0,-8),c+Vector2(0,10),accent,3,true)
				draw_line(c+Vector2(-8,0),c+Vector2(8,0),accent,3,true)
		var font := ThemeDB.fallback_font
		draw_string(font,Vector2(18,28),"[%d]" % (slot+1),HORIZONTAL_ALIGNMENT_LEFT,-1,14,ForestUI.PAPER)
		for i in int(gift.get("limit",1)):
			var width := (size.x-40)/float(gift.get("limit",1))
			draw_rect(Rect2(20+i*width,size.y-65,width-4,4),accent if i < rank else ForestUI.EDGE)
		draw_string(font,Vector2(20,size.y-28),"ESCOLHER  →" if active else "TOQUE PARA ESCOLHER",HORIZONTAL_ALIGNMENT_CENTER,size.x-40,14,accent)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.025,0.055,0.075,0.94)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	var eyebrow := Label.new()
	eyebrow.text = "D Á D I V A S   D O   B O S Q U E"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color",ForestUI.GOLD)
	column.add_child(eyebrow)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size",32)
	_title.add_theme_color_override("font_color",ForestUI.PAPER)
	column.add_child(_title)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color",ForestUI.MINT)
	column.add_child(_hint)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation",16)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(cards)
	for i in 3:
		var card := GiftCard.new()
		card.slot = i
		card.accent = [ForestUI.MINT,ForestUI.GOLD,Color("a3c9e2")][i]
		card.custom_minimum_size = Vector2(220,340)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for state in ["normal","hover","pressed","focus"]:
			card.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		card.pressed.connect(func(): _choose(i))
		cards.add_child(card)
		_buttons.append(card)
	var footer := Label.new()
	footer.text = "1 / 2 / 3 ou toque na carta  •  Escolha um poder  •  Combate pausado"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color",ForestUI.PAPER)
	column.add_child(footer)
	hide()

func open(offers: Array, level: int, counts: Dictionary = {}, pending: int = 1) -> void:
	_offers = offers.duplicate()
	_armed = false
	_title.text = "NÍVEL %02d  ·  ESCOLHA SEU PODER" % level
	_hint.text = "Melhoria gratuita para esta partida" if pending == 1 else "%d escolhas disponíveis — uma por nível" % pending
	for i in _buttons.size():
		var card: GiftCard = _buttons[i]
		card.visible = i < offers.size()
		for child in card.get_children():
			card.remove_child(child)
			child.queue_free()
		if i >= offers.size(): continue
		card.gift = offers[i]
		card.rank = int(counts.get(offers[i].id,0))+1
		var column := VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.offset_left = 20
		column.offset_right = -20
		column.offset_top = 143
		column.offset_bottom = -80
		column.add_theme_constant_override("separation",12)
		card.add_child(column)
		for entry in [[offers[i].title,22,ForestUI.PAPER],["GRAU %d / %d" % [card.rank,offers[i].limit],13,card.accent],[offers[i].description,17,ForestUI.PAPER]]:
			var label := Label.new()
			label.text = entry[0]
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_theme_font_size_override("font_size",entry[1])
			label.add_theme_color_override("font_color",entry[2])
			column.add_child(label)
		card.queue_redraw()
	show()
	if not offers.is_empty(): _buttons[0].grab_focus()
	# Ignore the input that opened the panel, including a held skill key.
	await get_tree().create_timer(0.18,true).timeout
	_armed = visible

func _choose(index: int) -> void:
	if not visible or not _armed or index < 0 or index >= _offers.size(): return
	var id: String = _offers[index].id
	_armed = false
	hide()
	_offers.clear()
	chosen.emit(id)

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo: return
	var index: int = event.physical_keycode - KEY_1
	if index >= 0 and index < _offers.size():
		get_viewport().set_input_as_handled()
		_choose(index)
