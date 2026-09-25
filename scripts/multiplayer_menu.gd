class_name MultiMenu
extends Control

## Lobby multiplayer: hospedar (com UPnP + IP local) ou entrar com IP.
## O fluxo de campeões/fases reaproveita as telas normais.

signal host_pressed
signal join_pressed(ip: String, port: int)
signal back_pressed
signal cancel_pressed
signal count_pressed(n: int)

var _status: Label = null
var _ip_edit: LineEdit = null
var _port_edit: LineEdit = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func build_choice() -> void:
	_clear()
	var v := _frame("👥  MULTIPLAYER")
	var info := _label("Jogue em dupla com um amigo (2 jogadores).", 14, Color(0.78, 0.78, 0.78))
	v.add_child(info)
	var h := Button.new()
	h.text = "🏠 Hospedar partida"
	h.custom_minimum_size = Vector2(320, 50)
	MenuArt.apply_menu_btn(h, MenuArt.GOLD)
	h.pressed.connect(func():
		Sfx.play(self, "click")
		host_pressed.emit()
	)
	v.add_child(_centered(h))
	var j := Button.new()
	j.text = "🔌 Entrar com IP"
	j.custom_minimum_size = Vector2(320, 50)
	MenuArt.apply_menu_btn(j, Color(0.55, 0.85, 1))
	j.pressed.connect(func():
		Sfx.play(self, "click")
		build_join("")
	)
	v.add_child(_centered(j))
	v.add_child(_back_btn())

func build_host(local_ip: String, port: int, net_info: String, max_n: int = 2) -> void:
	_clear()
	var v := _frame("🏠  HOSPEDAR")
	v.add_child(_label("Seu IP local: %s   •   porta %d" % [local_ip, port], 15, Color(0.55, 0.85, 1)))
	v.add_child(_label(net_info, 12, Color(1, 1, 1, 0.6)))
	v.add_child(_label("Pela internet sem configurar roteador:\nuse Radmin VPN ou ZeroTier e passe o IP de lá.", 12, Color(1, 0.85, 0.4)))
	v.add_child(_label("Jogadores na sala (máx. 4):", 14, MenuArt.CREAM))
	var crow := HBoxContainer.new()
	crow.alignment = BoxContainer.ALIGNMENT_CENTER
	crow.add_theme_constant_override("separation", 10)
	crow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(crow)
	for n in [2, 3, 4]:
		var cb := Button.new()
		cb.text = "%dP" % n
		cb.custom_minimum_size = Vector2(90, 40)
		MenuArt.apply_menu_btn(cb, Color(0.4, 0.9, 0.45) if n == max_n else MenuArt.GOLD)
		var nn: int = n
		cb.pressed.connect(func():
			Sfx.play(self, "click")
			count_pressed.emit(nn)
		)
		crow.add_child(cb)
	_status = _label("Escolha seu campeão em Jogar…", 14, MenuArt.CREAM)
	v.add_child(_status)
	var go := Button.new()
	go.text = "⚔ Escolher campeão e hospedar →"
	go.custom_minimum_size = Vector2(320, 50)
	MenuArt.apply_menu_btn(go, Color(0.4, 0.9, 0.45))
	go.pressed.connect(func():
		Sfx.play(self, "click")
		host_pressed.emit()
	)
	v.add_child(_centered(go))
	v.add_child(_back_btn())

func build_join(status: String) -> void:
	_clear()
	var v := _frame("🔌  ENTRAR")
	v.add_child(_label("IP do host (local, Radmin ou internet):", 14, Color(0.78, 0.78, 0.78)))
	_ip_edit = LineEdit.new()
	_ip_edit.text = "127.0.0.1"
	_ip_edit.custom_minimum_size = Vector2(320, 40)
	_ip_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_centered(_ip_edit))
	_port_edit = LineEdit.new()
	_port_edit.text = "4242"
	_port_edit.custom_minimum_size = Vector2(160, 36)
	_port_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_centered(_port_edit))
	_status = _label(status, 14, MenuArt.CREAM)
	v.add_child(_status)
	var go := Button.new()
	go.text = "Entrar →"
	go.custom_minimum_size = Vector2(320, 48)
	MenuArt.apply_menu_btn(go, Color(0.4, 0.9, 0.45))
	go.pressed.connect(func():
		Sfx.play(self, "click")
		join_pressed.emit(_ip_edit.text, int(_port_edit.text))
	)
	v.add_child(_centered(go))
	v.add_child(_back_btn())

func build_waiting(champ_name: String) -> void:
	_clear()
	var v := _frame("⏳  AGUARDANDO HOST")
	v.add_child(_label("Pronto como %s!" % champ_name, 16, Color(0.5, 1, 0.55)))
	_status = _label("O host escolhe a fase e começa…", 14, MenuArt.CREAM)
	v.add_child(_status)
	var c := Button.new()
	c.text = "Cancelar"
	c.custom_minimum_size = Vector2(240, 44)
	MenuArt.apply_menu_btn(c, Color(0.8, 0.4, 0.4))
	c.pressed.connect(func():
		Sfx.play(self, "click")
		cancel_pressed.emit()
	)
	v.add_child(_centered(c))

func set_status(txt: String) -> void:
	if _status != null:
		_status.text = txt

func _frame(title: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 200)
	margin.add_theme_constant_override("margin_right", 200)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var panel := MenuArt.FramePanel.new()
	panel.add_theme_stylebox_override("panel", MenuArt.style_panel())
	margin.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	var t := MenuArt.title_label_gold(title, 32)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	v.add_child(MenuArt.divider())
	return v

func _label(txt: String, fsize: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _centered(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc

func _back_btn() -> CenterContainer:
	var b := Button.new()
	b.text = "← Voltar"
	b.custom_minimum_size = Vector2(240, 44)
	MenuArt.apply_menu_btn(b, MenuArt.GOLD)
	b.pressed.connect(func():
		Sfx.play(self, "click")
		back_pressed.emit()
	)
	return _centered(b)

func _clear() -> void:
	for c in get_children():
		c.queue_free()
	_status = null
	_ip_edit = null
	_port_edit = null
