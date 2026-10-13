class_name StageMenu
extends Control

signal back_pressed
signal shop_pressed
signal start_pressed(stage: int, diff: int)

var progress: Dictionary = StageData.default_progress()
var selected_stage := 0
var selected_diff := 0
var step := 0
var _tick := 0.0
var _stage_btns: Array[Button] = []
var _diff_btns: Array[Button] = []
var _info_label: Label

class ExpeditionCard extends Button:
	var index := 0
	var difficulty := false
	var chosen := false
	var locked := false
	var cleared := false

	func _ready() -> void:
		text = ""
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)

	func caption(value: String, y: float, px: int, col: Color) -> void:
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		draw_string(font, Vector2((size.x-width)/2,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,col)

	func _draw() -> void:
		var accent: Color = StageData.DIFFS[index].color if difficulty else BiomeArt.palette(index)[4]
		var active := chosen or (is_hovered() and not locked) or has_focus()
		ForestUI.frame(self, Rect2(Vector2.ZERO,size),accent if active else ForestUI.EDGE)
		if active:
			draw_rect(Rect2(5,5,size.x-10,size.y-10), Color(accent,0.08))
		if difficulty:
			_draw_difficulty(accent)
		else:
			_draw_region(accent)
		if locked:
			caption("BLOQUEADO",size.y-18,12,ForestUI.PAPER)
			caption("Conclua " + (StageData.diff_name(maxi(0,index-1)) if difficulty else "o reino %d" % index),size.y-40,11,ForestUI.PAPER)
		elif chosen:
			var w := size.x-32
			draw_rect(Rect2(16,size.y-38,w,25),accent)
			caption("SELECIONADO",size.y-20,12,ForestUI.INK)
		else:
			caption("CONCLUÍDO" if cleared else "SELECIONAR",size.y-20,12,ForestUI.PAPER)

	func _draw_region(accent: Color) -> void:
		var art_h := size.y-137
		var pal: Dictionary = StageData.STAGES[index].palette
		draw_rect(Rect2(8,8,size.x-16,art_h),pal.grass.darkened(0.2))
		# A composed miniature of the actual region, using its own art vocabulary.
		for i in 9:
			var x := 15.0 + fmod(i*67.0,size.x-35)
			var y := 24.0 + fmod(i*37.0,maxf(30,art_h-40))
			draw_line(Vector2(x,y),Vector2(x+15,y+3),Color(accent,0.12),2)
		ArtUtil.fill_ellipse(self,size.x*0.5,art_h*0.82,size.x*0.38,22,pal.dirt)
		for i in 4:
			var x: float = size.x * [0.17,0.81,0.28,0.88][i]
			var y: float = art_h * [0.55,0.56,0.88,0.9][i]
			draw_set_transform(Vector2(x,y),0,Vector2.ONE*0.85)
			BiomeArt.tree(self,index,i)
		draw_set_transform(Vector2(size.x*0.53,art_h*0.88),0,Vector2.ONE*minf(1.25,art_h/95))
		BiomeEnemyArt.draw_enemy(self,StageData.boss_type(index),index,0)
		draw_set_transform(Vector2.ZERO)
		if locked:
			draw_rect(Rect2(8,8,size.x-16,art_h),Color(ForestUI.INK,0.42))
		caption("REINO %02d / 05 ONDAS" % (index+1),size.y-113,11,accent)
		caption(StageData.stage_name(index).to_upper(),size.y-85,18,ForestUI.PAPER)
		caption(BiomeEnemyArt.title(StageData.boss_type(index),index),size.y-62,12,ForestUI.MINT)

	func _draw_difficulty(accent: Color) -> void:
		var center := Vector2(size.x/2,67)
		# A threat seal: each additional blade corresponds to a difficulty tier.
		draw_arc(center,35,0,TAU,6,Color(accent,0.25),9)
		for i in index+1:
			var x := (i-index*0.5)*15
			var points := PackedVector2Array([center+Vector2(x, -27),center+Vector2(x+4,-17),center+Vector2(x+3,17),center+Vector2(x-3,17),center+Vector2(x-4,-17)])
			draw_colored_polygon(points,accent)
			draw_line(center+Vector2(x-7,18),center+Vector2(x+7,18),ForestUI.PAPER,2)
			draw_line(center+Vector2(x,18),center+Vector2(x,28),accent,3)
		var d: Dictionary = StageData.DIFFS[index]
		caption(d.name,126,20,accent)
		caption(["Aprenda a sobreviver", "Cada erro pesa", "Sem espaço para hesitar", "O bosque não perdoa"][index],149,11,ForestUI.PAPER)
		var top := 175.0
		for line in ["VIDA INIMIGA   ×%.2f" % d.hp,"DANO INIMIGO   ×%.2f" % d.atk,"HORDA   ×%.2f" % d.count,"OURO   ×%.2f" % d.gold]:
			caption(line,top,14,ForestUI.PAPER)
			top += 23

func build(prog: Dictionary, stage: int, diff: int) -> void:
	progress = prog
	selected_stage = stage if StageData.is_stage_unlocked(prog,stage) else 0
	selected_diff = diff if StageData.is_diff_unlocked(prog,selected_stage,diff) else 0
	step = 0
	_rebuild()

func _label(value: String, px: int, col: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",px)
	label.add_theme_color_override("font_color",col)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(value: String, callback: Callable, col: Color = ForestUI.GOLD) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(180,48)
	ForestUI.button(button,col)
	button.pressed.connect(callback)
	return button

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_stage_btns.clear()
	_diff_btns.clear()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",10)
	margin.add_child(layout)
	layout.add_child(_label("BLACKWOOD   /   EXPEDIÇÃO   /   %s" % ("01 • DESTINO" if step == 0 else "02 • DESAFIO"),12,ForestUI.MINT))
	layout.add_child(_label("ATRAVESSE A FRONTEIRA" if step == 0 else "ESCOLHA SEU DESAFIO",34,ForestUI.PAPER))
	_info_label = _label("",13,ForestUI.GOLD)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_info_label)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation",14)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(cards)
	for i in (3 if step == 0 else 4):
		var card := ExpeditionCard.new()
		card.index = i
		card.difficulty = step == 1
		card.custom_minimum_size = Vector2(170,300)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.pressed.connect(_select.bind(i))
		cards.add_child(card)
		if step == 0: _stage_btns.append(card)
		else: _diff_btns.append(card)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation",14)
	layout.add_child(nav)
	nav.add_child(_button("VOLTAR" if step == 0 else "TROCAR MAPA",_back,ForestUI.EDGE))
	var help := _label("Setas: escolher  •  Enter: confirmar",12,ForestUI.PAPER)
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_child(help)
	nav.add_child(_button("DEFINIR DESAFIO" if step == 0 else "INICIAR EXPEDIÇÃO",_confirm))
	_refresh()

func _select(index: int) -> void:
	if step == 0:
		if not StageData.is_stage_unlocked(progress,index): return
		selected_stage = index
		if not StageData.is_diff_unlocked(progress,index,selected_diff): selected_diff = 0
	else:
		if not StageData.is_diff_unlocked(progress,selected_stage,index): return
		selected_diff = index
	Sfx.play(self,"click")
	_refresh()

func _refresh() -> void:
	for i in _stage_btns.size():
		var card := _stage_btns[i] as ExpeditionCard
		card.locked = not StageData.is_stage_unlocked(progress,i)
		card.disabled = card.locked
		card.chosen = selected_stage == i
		card.cleared = StageData.is_cleared(progress,i,0)
		card.tooltip_text = "Vença %s para liberar." % StageData.stage_name(maxi(0,i-1)) if card.locked else StageData.STAGES[i].desc
		card.queue_redraw()
	for i in _diff_btns.size():
		var card := _diff_btns[i] as ExpeditionCard
		card.locked = not StageData.is_diff_unlocked(progress,selected_stage,i)
		card.disabled = card.locked
		card.chosen = selected_diff == i
		card.cleared = StageData.is_cleared(progress,selected_stage,i)
		card.tooltip_text = "Conclua %s neste mapa para liberar." % StageData.diff_name(maxi(0,i-1)) if card.locked else "Multiplicadores aplicados aos inimigos desta expedição."
		card.queue_redraw()
	_info_label.text = (StageData.STAGES[selected_stage].desc as String).replace("\n"," ") if step == 0 else "%s  /  %s  •  Sem escolhas de melhorias durante a luta" % [StageData.stage_name(selected_stage),StageData.diff_name(selected_diff)]

func _confirm() -> void:
	if step == 0: _to_step_1()
	else: _try_start()

func _to_step_1() -> void:
	step = 1
	Sfx.play(self,"click")
	_rebuild()

func _back() -> void:
	Sfx.play(self,"click")
	if step == 0: back_pressed.emit()
	else:
		step = 0
		_rebuild()

func _try_start() -> void:
	if StageData.is_stage_unlocked(progress,selected_stage) and StageData.is_diff_unlocked(progress,selected_stage,selected_diff):
		Sfx.play(self,"click")
		start_pressed.emit(selected_stage,selected_diff)

func handle_key(key: int) -> bool:
	if key in [KEY_LEFT,KEY_UP,KEY_A,KEY_W,KEY_Q,KEY_RIGHT,KEY_DOWN,KEY_D,KEY_S,KEY_E]:
		var direction := -1 if key in [KEY_LEFT,KEY_UP,KEY_A,KEY_W,KEY_Q] else 1
		var count := 3 if step == 0 else 4
		var current := selected_stage if step == 0 else selected_diff
		for i in count:
			current = posmod(current+direction,count)
			var unlocked := StageData.is_stage_unlocked(progress,current) if step == 0 else StageData.is_diff_unlocked(progress,selected_stage,current)
			if unlocked:
				_select(current)
				break
		return true
	if key in [KEY_ENTER,KEY_KP_ENTER]:
		_confirm()
		return true
	if key in [KEY_ESCAPE,KEY_BACKSPACE]:
		_back()
		return true
	return false

func _process(delta: float) -> void:
	if visible: _tick = MenuArt.back_tick(self,delta,_tick)[0]

func _draw() -> void:
	MenuArt.draw_back(self,size,_tick)
