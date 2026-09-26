extends Node2D

## Main do jogo Godot: estados (select → play → pause/shop → gameover),
## spawn, câmera, drop de gold e integração das UIs.
## Port de Main.java (modo gráfico) + GamePanel.java (loop, spawn, input, overlays).

enum State { MENU, SETTINGS, CHAMP, STAGE, MENUSHOP, PLAY, PAUSE, SHOP, GAMEOVER, VICTORY, MULTI, PROFILE }

const WorldScript := preload("res://scripts/world.gd")
const PlayerScript := preload("res://scripts/player.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const CoinScript := preload("res://scripts/gold_coin.gd")
const FloatingTextScript := preload("res://scripts/floating_text.gd")

var state: State = State.MENU

var world: World
var player: Player
var camera: Camera2D
var enemies: Array = []
var shots: Array = []  # projéteis inimigos (ticados só em PLAY)
# Multiplayer (0 solo, 1 host, 2 client). Host simula tudo; client renderiza.
var netplay: Netplay = null
var mult_ui: MultiMenu = null
var mp := 0
var allies: Array = []  # Players P2..P4 (host simula, client renderiza)
var ally_peers: Array = []  # peer id de cada aliado (mesma ordem)
var ally_ready: Array = []  # pronto de cada aliado (mesma ordem)
var ally_keys: Array = []  # client: chave de cada aliado (mesma ordem)
var _ally_picks := {}  # slot -> champ idx escolhido
var mp_max := 2  # jogadores na sala (2 a 4, escolhido no lobby)
var mp_armed := false  # host vai jogar em dupla
var client_pick := false  # client escolhendo campeão
var mp_own_champ := 2
var mp_seed := -1
var mp_foes := {}  # client: net_id -> Enemy
var net_ins := {}  # host: peer id -> inputs do aliado
var snap_t := 0.0
var esnap_t := 0.0
var wsnap_t := 0.0
var input_t := 0.0
var wave_banner_txt := ""
var wave_banner_t := 0.0
var msg_seq := 0
var msg_last := ""
var msg_seen := 0
var mp_prev := {}
var net_id_counter := 0
var touch_ui: TouchControls = null
var profiles_ui: ProfilesMenu = null
var walk_cache: Array = []  # tiles livres (cache por run: evita scan 60x60 por spawn)
var kill_count := 0
var game_time := 0.0
var minimap_tex: ImageTexture

var entities: Node2D
var fx_layer: Node2D
var coin_layer: Node2D
var hud: HUD
var shop: ShopUI
var select_ui: ChampSelect
var stage_ui: StageMenu
var menushop_ui: MenuShop
var menu_ui: MainMenu
var settings_ui: SettingsMenu
var pause_layer: Control
var gameover_layer: Control
var victory_layer: Control
var settings: Dictionary = GameSettings.default_data()
var _shop_return: State = State.MENU

var _spawn_timer := 0.0
var _selected := 2
var _msg_timer := 0.0
var shake := 0.0

# ---- Sistema de waves/fases (3 fases x 5 ondas = 15 ondas) ----
var cur_stage := 0
var cur_diff := 0
var wave_idx := 0
var wave_spawned := 0
var wave_killed := 0
var wave_quota := 0
var wave_active := false
var between_timer := 0.0
var boss_left := 0
var mini_left := 0
var progress: Dictionary = StageData.default_progress()
const BETWEEN_DELAY := 3.5
# Onda do meio da run onde o mini-boss aparece (3ª onda, idx 2).
const MINIBOSS_WAVE := 2

# =====================================================================
#  SETUP
# =====================================================================
func _ready() -> void:
	randomize()
	settings = GameSettings.load_data()
	GameSettings.apply_video(settings)
	Sfx.ensure_buses(settings)
	Profiles.ensure()

	netplay = Netplay.new()
	netplay.name = "Netplay"
	add_child(netplay)
	netplay.peer_joined.connect(_mp_peer_joined)
	netplay.peer_left.connect(_mp_peer_left)
	netplay.server_ready.connect(_mp_server_ready)
	netplay.connect_failed.connect(_mp_connect_failed)

	world = WorldScript.new()
	world.name = "World"
	add_child(world)

	coin_layer = Node2D.new()
	coin_layer.name = "Coins"
	coin_layer.z_index = 2
	add_child(coin_layer)

	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)

	fx_layer = Node2D.new()
	fx_layer.name = "Fx"
	fx_layer.z_index = 20
	add_child(fx_layer)

	camera = Camera2D.new()
	camera.name = "Camera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)

	# UIs em CanvasLayer
	var ui_root := CanvasLayer.new()
	ui_root.name = "UIRoot"
	ui_root.layer = 10
	add_child(ui_root)

	hud = HUD.new()
	hud.name = "HUD"
	hud.main = self
	hud.visible = false
	hud.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	ui_root.add_child(hud)

	shop = ShopUI.new()
	shop.name = "Shop"
	shop.main = self
	shop.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	ui_root.add_child(shop)

	select_ui = ChampSelect.new()
	select_ui.name = "ChampSelect"
	select_ui.chosen.connect(_on_champ_chosen)
	select_ui.backed.connect(_enter_menu)
	select_ui.shop_pressed.connect(func(): _enter_menushop(State.CHAMP))
	select_ui.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	ui_root.add_child(select_ui)

	stage_ui = StageMenu.new()
	stage_ui.name = "StageMenu"
	stage_ui.back_pressed.connect(_enter_champ)
	stage_ui.shop_pressed.connect(func(): _enter_menushop(State.STAGE))
	stage_ui.start_pressed.connect(_on_stage_start)
	stage_ui.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	ui_root.add_child(stage_ui)

	menushop_ui = MenuShop.new()
	menushop_ui.name = "MenuShop"
	menushop_ui.back_pressed.connect(_on_menushop_back)
	menushop_ui.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	ui_root.add_child(menushop_ui)

	menu_ui = MainMenu.new()
	menu_ui.name = "MainMenu"
	menu_ui.play_pressed.connect(_enter_champ)
	menu_ui.multi_pressed.connect(_enter_multi)
	menu_ui.login_pressed.connect(_enter_profile)
	menu_ui.shop_pressed.connect(func(): _enter_menushop(State.MENU))
	menu_ui.settings_pressed.connect(_enter_settings)
	menu_ui.exit_pressed.connect(func(): get_tree().quit())
	menu_ui.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	ui_root.add_child(menu_ui)

	settings_ui = SettingsMenu.new()
	settings_ui.name = "SettingsMenu"
	settings_ui.back_pressed.connect(_on_settings_back)
	settings_ui.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	ui_root.add_child(settings_ui)

	mult_ui = MultiMenu.new()
	mult_ui.name = "MultiMenu"
	mult_ui.host_pressed.connect(_mp_host_go)
	mult_ui.join_pressed.connect(_mp_join_go)
	mult_ui.back_pressed.connect(_mp_lobby_back)
	mult_ui.cancel_pressed.connect(_mp_lobby_cancel)
	mult_ui.count_pressed.connect(_mp_count)
	mult_ui.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	ui_root.add_child(mult_ui)

	var touch_layer := CanvasLayer.new()
	touch_layer.name = "TouchLayer"
	touch_layer.layer = 30
	add_child(touch_layer)
	touch_ui = TouchControls.new()
	touch_ui.name = "Touch"
	touch_ui.main = self
	touch_ui.visible = false
	touch_layer.add_child(touch_ui)

	profiles_ui = ProfilesMenu.new()
	profiles_ui.name = "ProfilesMenu"
	profiles_ui.back_pressed.connect(_enter_menu)
	profiles_ui.picked.connect(_on_profile_picked)
	profiles_ui.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	ui_root.add_child(profiles_ui)

	_build_pause_ui(ui_root)
	_build_gameover_ui(ui_root)
	_build_victory_ui(ui_root)

	_enter_menu()

func _overlay_btn(txt: String, accent := Color(1.0, 0.85, 0.4)) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(220, 44)
	MenuArt.apply_menu_btn(b, accent)
	return b

func _quality_name() -> String:
	return ["Alta", "Média", "Baixa"][clampi(int(settings.get("quality", 1)), 0, 2)]

func _build_pause_ui(parent: Node) -> void:
	pause_layer = Control.new()
	pause_layer.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	pause_layer.visible = false
	pause_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(pause_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	pause_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	pause_layer.add_child(center)

	var panel := MenuArt.FramePanel.new()
	panel.add_theme_stylebox_override("panel", MenuArt.style_panel())
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var lbl := MenuArt.title_label_gold("PAUSADO", 36)
	v.add_child(lbl)
	v.add_child(MenuArt.EmblemMoon.new())

	var sub := Label.new()
	sub.text = "Respire — a Rift espera por você."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", MenuArt.CREAM)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sub)

	var cont := _overlay_btn("▶ Continuar  (ESC)")
	cont.pressed.connect(func(): _set_pause(false))
	v.add_child(cont)

	var sh := _overlay_btn("🛒 Loja  (TAB)")
	sh.pressed.connect(func():
		_set_pause(false)
		_open_shop()
	)
	v.add_child(sh)

	var cfg := _overlay_btn("⚙ Configurações")
	cfg.pressed.connect(func(): _enter_settings(State.PAUSE))
	v.add_child(cfg)

	var menu := _overlay_btn("🏠 Menu principal")
	menu.pressed.connect(func(): _enter_menu())
	v.add_child(menu)

	var gfx := _overlay_btn("🎨 Gráficos: " + _quality_name())
	gfx.pressed.connect(func():
		settings["quality"] = (int(settings.get("quality", 1)) + 1) % 3
		GameSettings.save_data(settings)
		Sfx.play(self, "click")
		gfx.text = "🎨 Gráficos: " + _quality_name()
	)
	v.add_child(gfx)

func _build_gameover_ui(parent: Node) -> void:
	gameover_layer = Control.new()
	gameover_layer.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	gameover_layer.visible = false
	gameover_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(gameover_layer)

	var veil := MenuArt.EmberVeil.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	gameover_layer.add_child(veil)

	var panel := MenuArt.FramePanel.new()
	panel.accent = Color(0.8, 0.25, 0.25)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(460, 300)
	panel.position = Vector2(-230, -150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.06, 0.06, 0.97)
	sb.border_color = Color(0.8, 0.2, 0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	gameover_layer.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.95, 0.25, 0.25))
	v.add_child(title)
	v.add_child(MenuArt.EmblemSkull.new())

	var kills := Label.new()
	kills.name = "Kills"
	kills.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kills.add_theme_font_size_override("font_size", 18)
	v.add_child(kills)

	var lv := Label.new()
	lv.name = "Level"
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_theme_font_size_override("font_size", 18)
	v.add_child(lv)

	var hint := Label.new()
	hint.text = "ENTER — menu principal\nR — jogar de novo"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(1, 1, 0.4))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hint)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(row)

	var again := _overlay_btn("🔄 De novo  (R)", Color(0.85, 0.32, 0.3))
	again.pressed.connect(func(): start_game())
	row.add_child(again)

	var menu := _overlay_btn("🏠 Menu  (ENTER)", Color(0.85, 0.32, 0.3))
	menu.pressed.connect(func(): _enter_menu())
	row.add_child(menu)

func _build_victory_ui(parent: Node) -> void:
	victory_layer = Control.new()
	victory_layer.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	victory_layer.visible = false
	victory_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(victory_layer)

	var veil := MenuArt.EmberVeil.new()
	veil.dim = Color(0.02, 0.08, 0.03, 0.78)
	veil.ember = Color(1, 0.85, 0.3)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	victory_layer.add_child(veil)

	var panel := MenuArt.FramePanel.new()
	panel.accent = Color(0.5, 0.9, 0.45)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(460, 300)
	panel.position = Vector2(-230, -150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.12, 0.08, 0.97)
	sb.border_color = Color(1, 0.85, 0.3)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	victory_layer.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var title := Label.new()
	title.text = "★ FASE VENCIDA! ★"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	v.add_child(title)
	v.add_child(MenuArt.EmblemStar.new())

	var info := Label.new()
	info.name = "Info"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 16)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(420, 60)
	v.add_child(info)

	var unlocks := Label.new()
	unlocks.name = "Unlocks"
	unlocks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlocks.add_theme_font_size_override("font_size", 16)
	unlocks.add_theme_color_override("font_color", Color(0.5, 1, 0.55))
	unlocks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unlocks.custom_minimum_size = Vector2(420, 50)
	v.add_child(unlocks)

	var hint2 := Label.new()
	hint2.text = "ENTER — menu principal\nR — jogar de novo"
	hint2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint2.add_theme_font_size_override("font_size", 14)
	hint2.add_theme_color_override("font_color", Color(1, 1, 0.4))
	hint2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hint2)

	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_theme_constant_override("separation", 12)
	row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(row2)

	var again2 := _overlay_btn("🔄 De novo  (R)", Color(0.45, 0.9, 0.5))
	again2.pressed.connect(func(): start_game())
	row2.add_child(again2)

	var menu2 := _overlay_btn("🏠 Menu  (ENTER)", Color(0.45, 0.9, 0.5))
	menu2.pressed.connect(func(): _enter_menu())
	row2.add_child(menu2)

# =====================================================================
#  FLUXO DE TELAS (menu → campeão → fase → jogo)
# =====================================================================
func _hide_all() -> void:
	hud.visible = false
	shop.visible = false
	pause_layer.visible = false
	gameover_layer.visible = false
	victory_layer.visible = false
	select_ui.visible = false
	stage_ui.visible = false
	menushop_ui.visible = false
	menu_ui.visible = false
	settings_ui.visible = false
	mult_ui.visible = false
	profiles_ui.visible = false

func _enter_menu() -> void:
	state = State.MENU
	if mp == 1:
		if netplay.peer != null:
			netplay.to_menu.rpc()
		netplay.leave()
	if mp == 2:
		netplay.leave()
	mp = 0
	mp_armed = false
	client_pick = false
	_reset_mp_session()
	_clear_world()
	settings = GameSettings.load_data()
	progress = StageData.load_progress()
	_hide_all()
	menu_ui.visible = true
	menu_ui.build(StageData.essence(progress))

func _enter_champ() -> void:
	state = State.CHAMP
	progress = StageData.load_progress()
	_hide_all()
	select_ui.visible = true
	select_ui.build(progress, _selected)

func _enter_stage() -> void:
	state = State.STAGE
	progress = StageData.load_progress()
	_hide_all()
	stage_ui.visible = true
	stage_ui.build(progress, cur_stage, cur_diff)
	_stage_ally_line()

func _enter_menushop(from: State) -> void:
	state = State.MENUSHOP
	_shop_return = from
	progress = StageData.load_progress()
	_hide_all()
	menushop_ui.visible = true
	menushop_ui.build(progress, _selected)

func _on_menushop_back() -> void:
	if _shop_return == State.STAGE:
		_enter_stage()
	elif _shop_return == State.CHAMP:
		_enter_champ()
	else:
		_enter_menu()

var _settings_return = State.MENU

func _enter_settings(ret: State = State.MENU) -> void:
	state = State.SETTINGS
	_settings_return = ret
	settings = GameSettings.load_data()
	_hide_all()
	settings_ui.visible = true
	settings_ui.build(settings)

func _on_settings_back() -> void:
	if _settings_return == State.PAUSE and state == State.SETTINGS:
		_hide_all()
		pause_layer.visible = true
		state = State.PAUSE
	else:
		_enter_menu()

func _enter_multi() -> void:
	state = State.MULTI
	_clear_world()
	mp = 0
	mp_armed = false
	client_pick = false
	mp_max = 2
	_reset_mp_session()
	netplay.leave()
	_hide_all()
	mult_ui.visible = true
	mult_ui.build_choice()

func _enter_profile() -> void:
	state = State.PROFILE
	_hide_all()
	profiles_ui.visible = true
	profiles_ui.build()

func _on_profile_picked() -> void:
	progress = StageData.load_progress()
	menu_ui.build(StageData.essence(progress))

## Zera a sessão do lobby (peers, prontos, inputs). Run não mexe aqui.
func _reset_mp_session() -> void:
	ally_peers.clear()
	ally_ready.clear()
	_ally_picks.clear()
	net_ins.clear()

func _mp_host_go() -> void:
	if mp == 1:
		mp_armed = true
		_enter_champ()
		return
	var err := netplay.host(Netplay.PORT, mp_max)
	if err != "":
		Sfx.play(self, "error")
		_hide_all()
		mult_ui.visible = true
		mult_ui.build_choice()
		return
	mp = 1
	mp_armed = false
	_hide_all()
	mult_ui.visible = true
	mult_ui.build_host(netplay.local_ip, Netplay.PORT, netplay.upnp_info, mp_max)

func _mp_count(n: int) -> void:
	if netplay.has_ally():
		Sfx.play(self, "error")
		mult_ui.set_status("Amigos já conectados — não dá pra mudar agora.")
		return
	mp_max = clampi(n, 2, 4)
	var err := netplay.host(Netplay.PORT, mp_max)
	if err != "":
		Sfx.play(self, "error")
		return
	_hide_all()
	mult_ui.visible = true
	mult_ui.build_host(netplay.local_ip, Netplay.PORT, netplay.upnp_info, mp_max)

func _mp_join_go(ip: String, port: int) -> void:
	var err := netplay.join(ip, port)
	_hide_all()
	mult_ui.visible = true
	if err != "":
		Sfx.play(self, "error")
		mult_ui.build_join(err)
	else:
		mult_ui.build_join("Conectando a %s:%d…" % [ip.strip_edges(), port])

func _mp_lobby_back() -> void:
	_enter_menu()

func _mp_lobby_cancel() -> void:
	_enter_menu()

func _mp_server_ready() -> void:
	# Cliente conectou: escolhe o campeão.
	mp = 2
	client_pick = true
	mp_own_champ = _selected
	_enter_champ()

func _mp_connect_failed() -> void:
	Sfx.play(self, "error")
	_hide_all()
	mult_ui.visible = true
	mult_ui.build_join("Falha: host offline ou IP/porta errados.")

func _mp_peer_joined(_id: int) -> void:
	if mp == 1:
		if state == State.MULTI:
			mult_ui.set_status("Amigo conectado! Escolha seu campeão →")
	elif state == State.PLAY:
		say("Amigo entrou na arena!")

func _mp_peer_left(pid: int) -> void:
	if mp == 1:
		var i := _ally_index(pid)
		if i < 0:
			return  # sinal espúrio com id desconhecido: ignora
		var gone = allies[i]
		if is_instance_valid(gone):
			gone.queue_free()
		allies.remove_at(i)
		ally_peers.remove_at(i)
		ally_ready.remove_at(i)
		if state == State.PLAY:
			var me_up := player != null and is_instance_valid(player) and player.is_alive()
			if not me_up and _living_allies().is_empty():
				_on_player_died()
			else:
				say("Amigo desconectou — seguimos sem ele.")
		elif state == State.MULTI:
			mult_ui.set_status("Amigo saiu.")
		elif state == State.STAGE:
			stage_ui._refresh()
			_stage_ally_line()
	elif mp == 2:
		_enter_menu()

func _on_champ_chosen(champ_idx: int) -> void:
	_selected = clampi(champ_idx, 0, ChampData.CHAMPS.size() - 1)
	if mp == 2 and client_pick:
		mp_own_champ = _selected
		client_pick = false
		netplay.send_hello(mp_own_champ)
		_hide_all()
		mult_ui.visible = true
		mult_ui.build_waiting(str(ChampData.CHAMPS[mp_own_champ].get("nome", "?")))
		return
	_enter_stage()

func mp_on_hello(pid: int, champ_idx: int) -> void:
	if mp != 1:
		return
	var champ := clampi(champ_idx, 0, ChampData.CHAMPS.size() - 1)
	var i := _ally_index(pid)
	if i < 0:
		if ally_peers.size() >= mp_max - 1:
			return  # sala cheia
		ally_peers.append(pid)
		ally_ready.append(false)
		_ally_picks[ally_peers.size() - 1] = champ
		net_ins[pid] = { move = Vector2.ZERO, atk = false,
			sk = [false, false, false, false, false], channel = false, item = false }
	else:
		_ally_picks[i] = champ

func mp_on_ready(pid: int) -> void:
	if mp != 1:
		return
	var i := _ally_index(pid)
	if i < 0:
		return
	ally_ready[i] = true
	if state == State.STAGE:
		stage_ui._refresh()
		_stage_ally_line()

func _ready_count() -> int:
	var n := 0
	for r in ally_ready:
		if bool(r):
			n += 1
	return n

func _stage_ally_line() -> void:
	if mp == 1 and mp_armed and stage_ui._info_label != null:
		var parts := []
		for i in ally_peers.size():
			var nm := "?"
			if _ally_picks.has(i):
				nm = str(ChampData.CHAMPS[int(_ally_picks[i])].get("nome", "?"))
			parts.append("P%d: %s %s" % [i + 2, nm, "PRONTO" if i < ally_ready.size() and bool(ally_ready[i]) else "…"])
		if parts.is_empty():
			stage_ui._info_label.text += "   •   aguardando amigos…"
		else:
			stage_ui._info_label.text += "   •   " + "  ".join(parts)

func _on_stage_start(stage_idx: int, diff_idx: int) -> void:
	if mp == 1 and mp_armed:
		if _ready_count() < 1 or not netplay.has_ally():
			Sfx.play(self, "error")
			stage_ui._refresh()
			if stage_ui._info_label != null:
				stage_ui._info_label.text = "Aguardando amigos conectar e ficar pronto…"
			return
		mp_seed = randi()
		var picks := []
		for i in ally_peers.size():
			picks.append(int(_ally_picks.get(i, 2)))
		start_game(_selected, stage_idx, diff_idx, mp_seed, picks)
		netplay.begin.rpc(mp_seed, cur_stage, cur_diff, _selected)
		return
	start_game(_selected, stage_idx, diff_idx)

func start_game(champ_idx: int = -1, stage_idx: int = -1, diff_idx: int = -1, seed_value: int = -1, ally_list: Array = []) -> void:
	# Client reiniciando vira solo; host reiniciando reabre a sala.
	if mp == 2:
		netplay.leave()
		mp = 0
	if mp == 1 and mp_armed and ally_list.is_empty() and _ready_count() >= 1:
		ally_list = []
		for i in ally_peers.size():
			ally_list.append(int(_ally_picks.get(i, 2)))
		seed_value = randi()
		mp_seed = seed_value
		netplay.begin.rpc(mp_seed, cur_stage, cur_diff, _selected)
	# R do gameover/vitória repete a mesma combinação.
	if champ_idx < 0:
		champ_idx = _selected
	if stage_idx < 0:
		stage_idx = cur_stage
	if diff_idx < 0:
		diff_idx = cur_diff
	_selected = champ_idx
	cur_stage = clampi(stage_idx, 0, StageData.STAGES.size() - 1)
	cur_diff = clampi(diff_idx, 0, StageData.DIFFS.size() - 1)
	progress = StageData.load_progress()
	_clear_world()

	world.stage_idx = cur_stage
	world.generate(seed_value)
	world.apply_stage(cur_stage)
	minimap_tex = world.build_minimap_image()
	walk_cache = world.walkable_tiles()

	var c: Dictionary = ChampData.CHAMPS[_selected]
	player = PlayerScript.new()
	player.name = "Player"
	player.world = world
	# Só as habilidades desbloqueadas no menu entram (novo jogador = só ATK).
	var role_skills: Array = ChampData.ROLES[c.role].skills
	var unl: Array = StageData.unlocked_skills(progress, c.role)
	var cfgs: Array = []
	for i in mini(role_skills.size(), unl.size()):
		if bool(unl[i]):
			cfgs.append(role_skills[i])
	player.setup(c.nome, c.role, cfgs)
	player.position = world.center_px()
	player.died.connect(_on_player_died)
	player.leveled_up.connect(func(msg):
		if msg != "":
			say(msg)
			_float_text(msg, player.position + Vector2(0, -40), Color(1, 0.9, 0.4), 13)
			Sfx.play(self, "levelup")
	)
	entities.add_child(player)
	camera.position = player.position

	for a in ally_list.size():
		_spawn_ally(int(ally_list[a]), a)

	kill_count = 0
	game_time = 0.0
	_spawn_timer = 0.0
	wave_idx = 0
	between_timer = 0.0
	hud.clear_messages()
	_hide_all()
	hud.visible = true
	state = State.PLAY

	# Sem entrada no meio da run (sala fechada).
	if mp == 1 and netplay.peer != null:
		netplay.peer.refuse_new_connections = true

	# Client não roda waves (recebe tudo do host).
	if mp != 2:
		_start_wave(0)
	var nskills := player.skills.size()
	var atk_key := GameSettings.key_label(settings, "attack")
	var shop_key := GameSettings.key_label(settings, "shop")
	if nskills == 0:
		say("Bem-vindo, %s! %s • %s" % [c.nome, StageData.stage_name(cur_stage), StageData.diff_name(cur_diff)])
		say("Só ATK por enquanto — ganhe ◆ nas ondas e desbloqueie skills na LOJA!")
	else:
		say("Bem-vindo, %s! %s • %s (%d/5 skills)" % [c.nome, StageData.stage_name(cur_stage), StageData.diff_name(cur_diff), nskills])
		say("%s = soco | 1-%d = skills | %s = loja" % [atk_key, nskills, shop_key])
	say("Mana é curta: cada skill conta! Sobreviva às 5 ondas!")

## Spawna um aliado P2..P4 (host simula, client só renderiza).
func _spawn_ally(champ_idx: int, slot: int) -> void:
	var c2: Dictionary = ChampData.CHAMPS[clampi(champ_idx, 0, ChampData.CHAMPS.size() - 1)]
	var p2 := PlayerScript.new()
	p2.name = "Player%d" % (slot + 2)
	p2.world = world
	var cfgs2: Array = []
	var unl2: Array = StageData.unlocked_skills(progress, str(c2.role))
	var rskills2: Array = ChampData.ROLES[str(c2.role)].skills
	for i in mini(rskills2.size(), unl2.size()):
		if bool(unl2[i]):
			cfgs2.append(rskills2[i])
	p2.setup(str(c2.get("nome", "?")), str(c2.get("role", "tank")), cfgs2)
	p2.position = world.center_px() + Vector2(40, 0) + Vector2(0, slot * 36)
	p2.died.connect(_on_player_died)
	p2.leveled_up.connect(func(msg):
		if msg != "":
			say(msg)
	)
	if mp == 1:
		# Host simula o aliado com os inputs que chegam pela rede.
		p2.controlled = true
		p2.use_ext = true
	else:
		p2.controlled = false
	entities.add_child(p2)
	allies.append(p2)

func _start_wave(idx: int) -> void:
	wave_idx = idx
	wave_quota = StageData.wave_quota(cur_stage, idx, cur_diff)
	var extra := _all_players().size() - 1
	if extra > 0:
		wave_quota = int(wave_quota * (1.0 + 0.5 * float(extra)))
	# Co-op: caídos revivem a cada onda com metade da vida.
	for pl in _all_players():
		if not (pl as Player).is_alive():
			(pl as Player).hp = maxi(1, int((pl as Player).max_hp * 0.5))
			(pl as Player).mana = (pl as Player).max_mana
			say("%s reviveu! (50%%)" % (pl as Player).champ_name)
	wave_spawned = 0
	wave_killed = 0
	wave_active = true
	_show_banner("ONDA %d/15" % StageData.global_wave(cur_stage, idx))
	boss_left = 0
	mini_left = 0
	_spawn_timer = 0.0
	var gw := StageData.global_wave(cur_stage, idx)
	var is_last := idx == StageData.WAVES_PER_STAGE - 1
	var is_mid := idx == MINIBOSS_WAVE
	if is_last:
		# Final: chefão (+1 extra no IMPOSSÍVEL) SEMPRE com mini-bosses junto.
		boss_left = 2 if cur_diff >= 3 else 1
		mini_left = 1 if cur_diff < 2 else 2
		say("★ ONDA FINAL %d/15 — BOSS %s + %d MINI-BOSS! ★" % [gw, StageData.boss_type(cur_stage), mini_left])
		add_shake(6.0)
	elif is_mid:
		# Meio da run: mini-boss (2 no HARD+). A cada 5 ondas tem mini-boss.
		mini_left = 1 if cur_diff < 2 else 2
		say("👹 ONDA %d/15 (%s %d/5) — MINI-BOSS à vista! — %d inimigos!" % [gw, StageData.stage_name(cur_stage), idx + 1, wave_quota])
		add_shake(4.0)
	else:
		say("— ONDA %d/15 (%s %d/5) — %d inimigos!" % [gw, StageData.stage_name(cur_stage), idx + 1, wave_quota])
	# Enche a arena até o teto da fase (pressão imediata).
	var cap := StageData.alive_cap(cur_stage, cur_diff)
	for i in mini(cap, wave_quota):
		_spawn_next()
		if wave_spawned >= wave_quota:
			break

func _wave_level() -> int:
	# Nível difícil: acompanha a onda global + dificuldade + um pouco do player.
	var gw := StageData.global_wave(cur_stage, wave_idx)
	if player == null or not is_instance_valid(player):
		return maxi(1, gw + randi_range(-1, 1))
	var base := gw + cur_diff * 2 + int(player.level / 3.0)
	return maxi(1, base + randi_range(-1, 1))

func _diff_mults() -> Dictionary:
	var dd: Dictionary = StageData.DIFFS[clampi(cur_diff, 0, StageData.DIFFS.size() - 1)]
	var m := {
		"hp": float(dd.get("hp", 1.0)), "atk": float(dd.get("atk", 1.0)),
		"df": float(dd.get("df", 1.0)), "gold": float(dd.get("gold", 1.0)),
		"exp": float(dd.get("exp", 1.0)), "speed": float(dd.get("speed", 1.0)),
	}
	if _all_players().size() > 1:
		m["hp"] = float(m["hp"]) * (1.0 + 0.2 * float(_all_players().size() - 1))
	return m

func _clear_world() -> void:
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	for s in shots:
		if is_instance_valid(s):
			s.queue_free()
	shots.clear()
	for c in coin_layer.get_children():
		c.queue_free()
	for c in fx_layer.get_children():
		c.queue_free()
	if player != null and is_instance_valid(player):
		player.queue_free()
		player = null
	for pl in allies:
		if is_instance_valid(pl):
			(pl as Node).queue_free()
	allies.clear()
	ally_keys.clear()
	mp_foes.clear()
	walk_cache.clear()
	wave_active = false
	between_timer = 0.0
	boss_left = 0
	mini_left = 0

func _on_player_died() -> void:
	if state == State.GAMEOVER or state == State.VICTORY:
		return
	if mp == 2:
		return  # host decide; chega via force_state
	if mp == 1:
		var p1_up := player != null and is_instance_valid(player) and player.is_alive()
		if p1_up or not _living_allies().is_empty():
			say("Um campeão caiu! Revive na próxima onda.")
			return
		if _relay():
			netplay.force_state.rpc(0)
	state = State.GAMEOVER
	var gw := StageData.global_wave(cur_stage, wave_idx)
	var kills_lbl: Label = _find_label(gameover_layer, "Kills")
	if kills_lbl:
		kills_lbl.text = "Inimigos derrotados: %d   •   Onda %d/15 (%s %d/5 • %s)" % [
			kill_count, gw, StageData.stage_name(cur_stage), wave_idx + 1, StageData.diff_name(cur_diff)]
	var lv_lbl := _find_label(gameover_layer, "Level")
	if lv_lbl and player:
		lv_lbl.text = "Nível atingido: %d   •   Gold: %d" % [player.level, player.gold]
	gameover_layer.visible = true
	Sfx.play(self, "defeat")

func _on_victory() -> void:
	if state == State.VICTORY:
		return
	state = State.VICTORY
	wave_active = false
	var vbonus := StageData.essence_for_victory(cur_stage, cur_diff)
	var bank := StageData.add_essence(progress, vbonus)
	var news: Array = StageData.mark_cleared(progress, cur_stage, cur_diff)
	progress = StageData.load_progress()
	var info_lbl := _find_label(victory_layer, "Info")
	if info_lbl and player:
		info_lbl.text = "%s zerou %s no %s!\nKills: %d   •   Nível: %d   •   Gold: %d   •   +%d ◆ (banco: %d)\nTempo: %02d:%02d" % [
			player.champ_name, StageData.stage_name(cur_stage), StageData.diff_name(cur_diff),
			kill_count, player.level, player.gold, vbonus, bank, int(game_time / 60.0), int(game_time) % 60]
	var unl_lbl := _find_label(victory_layer, "Unlocks")
	if unl_lbl:
		if news.is_empty():
			unl_lbl.text = "Tudo aqui já estava liberado. Tente a próxima fase!"
		else:
			unl_lbl.text = "\n".join(news)
	victory_layer.visible = true
	add_shake(8.0)
	Sfx.play(self, "victory")
	if _relay():
		netplay.force_state.rpc(1)

func _complete_wave() -> void:
	wave_killed = maxi(wave_killed, wave_quota)
	wave_active = false
	if wave_idx >= StageData.WAVES_PER_STAGE - 1:
		_on_victory()
		return
	between_timer = BETWEEN_DELAY
	# Respiro entre ondas + cura honesta (TAB = loja).
	for pl in _all_players():
		(pl as Player).heal(int((pl as Player).max_hp * 0.20))
	# Essência ◆ = moeda meta: só de ondas/fases, nunca de kills.
	var bonus := StageData.essence_for_wave(cur_stage, wave_idx, cur_diff)
	var total := StageData.add_essence(progress, bonus)
	_float_text("+%d ◆" % bonus, player.position + Vector2(0, -56), Color(0.55, 0.85, 1), 13)
	say("Onda %d/5 limpa! +%d ◆ (banco: %d) — TAB = loja" % [wave_idx + 1, bonus, total])

## Tem chefão, mini ou elite vivo? (trava o passe automático)
func _tough_alive() -> bool:
	for e in enemies:
		if is_instance_valid(e) and e.is_alive() \
				and (e.is_boss() or e.is_miniboss() or e.is_elite):
			return true
	return false

## Limpa os restantes (fugiram) e completa a onda.
func _free_remaining() -> void:
	var i := enemies.size() - 1
	while i >= 0:
		var e = enemies[i]
		if is_instance_valid(e):
			e.queue_free()
		enemies.remove_at(i)
		i -= 1

## Pulo manual (N / ⏭): vale para a onda atual, chefão incluso.
func _skip_wave() -> void:
	if state != State.PLAY or not wave_active:
		return
	say("⏭ Onda pulada!")
	_free_remaining()
	_show_banner("⏭ ONDA PULADA!")
	_complete_wave()

func _show_banner(txt: String) -> void:
	wave_banner_txt = txt
	wave_banner_t = 2.4

func _find_label(root: Node, name: String) -> Label:
	if root.name == name and root is Label:
		return root
	for c in root.get_children():
		var r := _find_label(c, name)
		if r:
			return r
	return null

# =====================================================================
#  LOOP
# =====================================================================
func _physics_process(delta: float) -> void:
	if state != State.PLAY:
		return
	if player == null or not is_instance_valid(player):
		return
	_update_touch()
	if mp == 2:
		_client_play_tick(delta)
		return
	game_time += delta
	_apply_ally_input()
	if wave_banner_t > 0.0:
		wave_banner_t -= delta

	# ---- Lógica de waves ----
	var alive := 0
	for e in enemies:
		if is_instance_valid(e) and e.is_alive():
			alive += 1
	if wave_active:
		_spawn_timer += delta
		var cap := StageData.alive_cap(cur_stage, cur_diff)
		# Spawn rápido no começo da onda, mais lento no fim (difícil = mais pressão).
		var interval := maxf(0.35, 1.1 - cur_diff * 0.15 - wave_idx * 0.08)
		if wave_idx == StageData.WAVES_PER_STAGE - 1:
			interval *= 0.7  # onda do chefão: reforços chegam mais rápido
		if _spawn_timer >= interval and wave_spawned < wave_quota and alive < cap:
			_spawn_timer = 0.0
			_spawn_next()
		# Onda completa quando matou a cota (inclui o chefão).
		if wave_killed >= wave_quota:
			_complete_wave()
			if state != State.PLAY:
				return
		elif wave_active and wave_killed >= int(wave_quota * 0.9) and not _tough_alive():
			# 90% limpa sem chefão/elite vivo: passa sozinha (anti-trava).
			say("Onda quase limpa — avançando!")
			_free_remaining()
			_complete_wave()
			if state != State.PLAY:
				return
	else:
		# Intervalo entre ondas.
		if wave_killed >= wave_quota and state == State.PLAY:
			between_timer -= delta
			if between_timer <= 0.0:
				_start_wave(wave_idx + 1)

	# IA + ataques dos inimigos (alvo = vivo mais próximo)
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if e.is_alive():
			var tgt := _nearest_alive(e.position)
			if tgt == null:
				continue
			e.ai_update(tgt, delta)
			if e.try_attack(tgt):
				fx_layer.add_child(AttackEffect.new(
					AttackEffect.Type.ENEMY_HIT, tgt.position.x, tgt.position.y))
				add_shake(2.0)
				hud.queue_redraw()
		elif e.death_timer >= 0.0:
			# Cadáver com fade: continua atualizando o sumiço suave.
			var tgt2 := _nearest_alive(e.position)
			e.ai_update(tgt2 if tgt2 != null else player, delta)

	# Separação: ninguém empilha em cima de ninguém (cada um guarda seu espaço).
	var bodies := []
	for e in enemies:
		if is_instance_valid(e) and e.is_alive():
			bodies.append(e)
	for i in bodies.size():
		var a = bodies[i]
		for j in range(i + 1, bodies.size()):
			var b = bodies[j]
			var off: Vector2 = b.position - a.position
			var dd := off.length()
			if dd < 24.0 and dd > 0.01:
				var push: Vector2 = off / dd * (24.0 - dd) * 0.35
				var anx: Vector2 = a.position - push
				if not world.is_solid_at(anx.x, anx.y):
					a.position = anx
				var bnx: Vector2 = b.position + push
				if not world.is_solid_at(bnx.x, bnx.y):
					b.position = bnx

	# remove inimigos mortos com fade terminado
	var i := enemies.size() - 1
	while i >= 0:
		var e = enemies[i]
		if not is_instance_valid(e):
			enemies.remove_at(i)
		elif not e.is_alive() and e.death_timer <= 0.0:
			e.queue_free()
			enemies.remove_at(i)
		i -= 1

	# Projéteis inimigos (só andam em PLAY: ticados aqui, não no _process).
	for sh in shots.duplicate():
		if is_instance_valid(sh):
			sh.shot_tick(delta)
	var si := shots.size() - 1
	while si >= 0:
		if not is_instance_valid(shots[si]):
			shots.remove_at(si)
		si -= 1

	camera.position = _camera_focus()

	# screen shake (críticos, mortes, elites)
	if shake > 0.0:
		shake = maxf(0.0, shake - 60.0 * delta)
		camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	else:
		camera.offset = Vector2.ZERO

	# regenera HUD suavemente
	hud.queue_redraw()

	if mp == 1 and netplay.has_ally():
		_host_net_tick(delta)

## Vivo mais próximo (co-op) ou o jogador.
func _nearest_alive(pos: Vector2) -> Player:
	var best: Player = null
	var best_d := INF
	for pl in _all_players():
		if not (pl as Player).is_alive():
			continue
		var dd := pos.distance_to((pl as Player).position)
		if dd < best_d:
			best_d = dd
			best = pl
	return best

func _all_players() -> Array:
	var out := []
	if player != null and is_instance_valid(player):
		out.append(player)
	for pl in allies:
		if pl != null and is_instance_valid(pl):
			out.append(pl)
	return out

func _living_allies() -> Array:
	var out := []
	for pl in allies:
		if pl != null and is_instance_valid(pl) and (pl as Player).is_alive():
			out.append(pl)
	return out

func _ally_index(pid: int) -> int:
	return ally_peers.find(pid)

func _ally_of(pid: int):
	var i := _ally_index(pid)
	if i < 0 or i >= allies.size():
		return null
	var pl = allies[i]
	if pl == null or not is_instance_valid(pl):
		return null
	return pl

func _coop_size() -> int:
	return _all_players().size()

func _camera_focus() -> Vector2:
	var pts := []
	if player != null and is_instance_valid(player) and player.is_alive():
		pts.append(player.position)
	for pl in allies:
		if pl != null and is_instance_valid(pl) and (pl as Player).is_alive():
			pts.append((pl as Player).position)
	if pts.is_empty():
		return camera.position
	var mid := Vector2.ZERO
	for p in pts:
		mid += p
	return mid / float(pts.size())

# =====================================================================
#  MULTIPLAYER EM JOGO (host simula, client renderiza)
# =====================================================================
func _apply_ally_input() -> void:
	for pid in net_ins.keys():
		var pl = _ally_of(int(pid))
		if pl == null or not (pl as Player).is_alive():
			continue
		var inp: Dictionary = net_ins[pid]
		var mv: Vector2 = inp.get("move", Vector2.ZERO)
		(pl as Player).ext_dir = mv.limit_length(1.0) if mv.length() > 1.0 else mv
		if bool(inp.get("atk", false)):
			_do_basic_attack(pl)
		var sk: Array = inp.get("sk", [])
		for i in mini(5, sk.size()):
			if bool(sk[i]):
				_do_cast(i, pl)
		if bool(inp.get("channel", false)):
			_toggle_channel(pl)
		if bool(inp.get("item", false)):
			_use_first_item(pl)
		if bool(inp.get("skip", false)):
			_skip_wave()
		inp.atk = false
		inp.sk = [false, false, false, false, false]
		inp.channel = false
		inp.item = false
		inp.skip = false

func mp_on_input(pid: int, move: Vector2, atk: bool, sk: Array, channel: bool, item: bool, skip: bool) -> void:
	if not net_ins.has(pid):
		net_ins[pid] = { move = Vector2.ZERO, atk = false,
			sk = [false, false, false, false, false], channel = false, item = false, skip = false }
	var inp: Dictionary = net_ins[pid]
	inp.move = move
	if atk:
		inp.atk = true
	var cur: Array = inp.sk
	for i in mini(5, (sk as Array).size()):
		if bool(sk[i]):
			cur[i] = true
	if channel:
		inp.channel = true
	if item:
		inp.item = true
	if skip:
		inp.skip = true

func _pack_player(pl, key: int = 0) -> Array:
	if pl == null or not is_instance_valid(pl):
		return []
	return [key, pl.position, pl.hp, pl.max_hp, float(pl.mana), pl.max_mana, pl.level,
		pl.xp, pl.gold, pl.facing, pl.moving, pl.walk_phase, pl.channeling,
		pl.is_alive(), pl.attack_cd, pl.champ_name, pl.role]

func _pack_enemies() -> Array:
	var out := []
	for e in enemies:
		if not is_instance_valid(e):
			continue
		out.append([e.net_id, e.type_key, e.level, e.position, e.hp, e.max_hp,
			e.facing, e.moving, e.walk_phase, e.is_alive(), e.death_timer,
			e.is_boss(), e.is_miniboss(), e.is_elite])
	return out

func _pack_coins() -> Array:
	var out := []
	for c in coin_layer.get_children():
		if c is GoldCoin and is_instance_valid(c):
			out.append([(c as Node2D).position.x, (c as Node2D).position.y, (c as GoldCoin).value])
	return out

func _pack_wave() -> Array:
	return [cur_stage, cur_diff, wave_idx, wave_quota, wave_killed, wave_active,
		game_time, kill_count, StageData.essence(progress), between_timer, msg_seq, msg_last]

func _host_net_tick(delta: float) -> void:
	snap_t += delta
	if snap_t >= 0.05:
		snap_t = 0.0
		var plist := [_pack_player(player, 1)]
		for i in allies.size():
			var key := int(ally_peers[i]) if i < ally_peers.size() else -(i + 1)
			plist.append(_pack_player(allies[i], key))
		netplay.snap_players.rpc(plist)
	esnap_t += delta
	if esnap_t >= 0.08:
		esnap_t = 0.0
		netplay.snap_enemies.rpc(_pack_enemies())
		netplay.snap_coins.rpc(_pack_coins())
	wsnap_t += delta
	if wsnap_t >= 0.2:
		wsnap_t = 0.0
		netplay.snap_wave.rpc(_pack_wave())

func _client_play_tick(delta: float) -> void:
	for e in enemies:
		if is_instance_valid(e):
			e.client_tick(delta)
	for sh in shots.duplicate():
		if is_instance_valid(sh):
			sh.shot_tick(delta)
	var si := shots.size() - 1
	while si >= 0:
		if not is_instance_valid(shots[si]):
			shots.remove_at(si)
		si -= 1
	camera.position = _camera_focus()
	if shake > 0.0:
		shake = maxf(0.0, shake - 60.0 * delta)
		camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	else:
		camera.offset = Vector2.ZERO
	_send_input_tick(delta)
	hud.queue_redraw()

func _send_input_tick(delta: float) -> void:
	input_t += delta
	if input_t < 1.0 / 30.0:
		return
	input_t = 0.0
	if player == null or not player.is_alive():
		return
	var mv := Vector2.ZERO
	if GameSettings.held(settings, "move_up"): mv.y -= 1.0
	if GameSettings.held(settings, "move_down"): mv.y += 1.0
	if GameSettings.held(settings, "move_left"): mv.x -= 1.0
	if GameSettings.held(settings, "move_right"): mv.x += 1.0
	if mv.length() > 1.0:
		mv = mv.normalized()
	if touch_ui != null and touch_ui.visible:
		var td := touch_ui.pad_dir()
		if td != Vector2.ZERO:
			mv = td
	var sk := []
	for i in 5:
		sk.append(_edge("skill%d" % (i + 1)))
	netplay.send_input(mv, _edge("attack"), sk, _edge("channel"), _edge("item"), _edge("skip"))

func touch_active() -> bool:
	var m := int(settings.get("touch", 0))
	if m == 1:
		return true
	if m == 2:
		return false
	return DisplayServer.is_touchscreen_available()

func _update_touch() -> void:
	if touch_ui == null:
		return
	var show := touch_active() and state == State.PLAY
	touch_ui.visible = show
	var td := Vector2.ZERO
	if show:
		td = touch_ui.pad_dir()
		touch_ui.player_ref = player
	if player != null and is_instance_valid(player):
		player.touch_move = td
	for pl in allies:
		if pl != null and is_instance_valid(pl):
			(pl as Player).touch_move = td

func touch_button(id: String) -> void:
	if state == State.SHOP:
		if id == "shop" or id == "pause":
			_close_shop()
		return
	if state != State.PLAY:
		return
	if shop.visible:
		if id == "shop" or id == "pause":
			_close_shop()
		return
	match id:
		"attack":
			_do_basic_attack()
		"channel":
			_toggle_channel()
		"item":
			_use_first_item()
		"shop":
			_open_shop()
		"pause":
			if mp != 0:
				say("Sem pausa no multiplayer!")
			else:
				_set_pause(true)
		"skip":
			_skip_wave()
		_:
			if id.begins_with("skill"):
				_do_cast(int(id.trim_prefix("skill")) - 1)

func _edge(action_id: String) -> bool:
	var keys: Dictionary = settings.get("keys", {})
	var now := false
	if keys.has(action_id):
		for code in (keys[action_id] as Array):
			if Input.is_physical_key_pressed(int(code)):
				now = true
				break
	if touch_ui != null and touch_ui.visible and touch_ui.is_down(action_id):
		now = true
	var was := bool(mp_prev.get(action_id, false))
	mp_prev[action_id] = now
	return now and not was

func mp_apply_players(list: Array) -> void:
	# Cada entrada leva a chave do dono (1 = host). O próprio vai para
	# player; o resto vira aliado por chave estável.
	var me := get_tree().get_multiplayer().get_unique_id()
	var self_arr := []
	var want := []
	for item in list:
		if not (item is Array) or (item as Array).size() < 17:
			continue
		var arr: Array = item
		if int(arr[0]) == me:
			self_arr = arr
		else:
			want.append(arr)
	if not self_arr.is_empty():
		_apply_psnap(player, self_arr)
	var new_allies := []
	var new_keys := []
	for w in want:
		var key := int(w[0])
		var found = null
		for j in allies.size():
			if j < ally_keys.size() and int(ally_keys[j]) == key \
					and is_instance_valid(allies[j]):
				found = allies[j]
				break
		if found == null:
			found = _spawn_client_ally(w)
		if found != null:
			new_allies.append(found)
			new_keys.append(key)
			_apply_psnap(found, w)
	for old in allies:
		if not new_allies.has(old) and is_instance_valid(old):
			old.queue_free()
	allies = new_allies
	ally_keys = new_keys

func _spawn_client_ally(w: Array):
	var obj = PlayerScript.new()
	obj.world = world
	obj.setup(str(w[15]), str(w[16]), [])
	obj.controlled = false
	obj.position = w[1]
	entities.add_child(obj)
	return obj

func _apply_psnap(pl: Player, arr: Array) -> void:
	if pl == null or not is_instance_valid(pl) or arr.size() < 17:
		return
	var before: Vector2 = pl.position
	pl.position = arr[1]
	pl.hp = int(arr[2])
	pl.max_hp = int(arr[3])
	pl.mana = float(arr[4])
	pl.max_mana = int(arr[5])
	pl.level = int(arr[6])
	pl.xp = int(arr[7])
	pl.gold = int(arr[8])
	pl.facing = int(arr[9])
	pl.moving = bool(arr[10])
	pl.walk_phase = float(arr[11])
	pl.channeling = bool(arr[12])
	pl.attack_cd = float(arr[14])
	pl.queue_redraw()
	if before.distance_to(pl.position) > 2.0 and pl.is_alive():
		pl.trail.append({ p = pl.position, life = Player.TRAIL_LIFE })
	var ti := pl.trail.size() - 1
	while ti >= 0:
		pl.trail[ti].life -= 0.08
		if pl.trail[ti].life <= 0.0:
			pl.trail.remove_at(ti)
		ti -= 1
	while pl.trail.size() > Player.trail_cap():
		pl.trail.pop_front()

func mp_apply_enemies(list: Array) -> void:
	var seen := {}
	for item in list:
		if not (item is Array) or (item as Array).size() < 14:
			continue
		var arr: Array = item
		var nid := int(arr[0])
		seen[nid] = true
		var e = mp_foes.get(nid, null)
		if e == null or not is_instance_valid(e):
			e = EnemyScript.new()
			e.net_id = nid
			e.world = world
			e.stage_idx = cur_stage
			e.setup(str(arr[1]), int(arr[2]))
			entities.add_child(e)
			enemies.append(e)
			mp_foes[nid] = e
		e.position = arr[3]
		e.hp = int(arr[4])
		e.max_hp = int(arr[5])
		e.facing = int(arr[6])
		e.moving = bool(arr[7])
		e.walk_phase = float(arr[8])
		e.death_timer = float(arr[10])
		e.is_boss_flag = bool(arr[11])
		e.is_miniboss_flag = bool(arr[12])
		e.is_elite = bool(arr[13])
		e.dead = not bool(arr[9])
		e.queue_redraw()
	for nid in mp_foes.keys():
		if not seen.has(nid):
			var old = mp_foes[nid]
			if is_instance_valid(old):
				old.queue_free()
				enemies.erase(old)
			mp_foes.erase(nid)

func mp_apply_coins(list: Array) -> void:
	var nodes := []
	for c in coin_layer.get_children():
		if c is GoldCoin and is_instance_valid(c):
			nodes.append(c)
	var used := {}
	for item in list:
		if not (item is Array) or (item as Array).size() < 3:
			continue
		var arr: Array = item
		var pos := Vector2(float(arr[0]), float(arr[1]))
		var best = null
		var best_d := 40.0
		for idx in nodes.size():
			if used.has(idx):
				continue
			var dd: float = (nodes[idx] as Node2D).position.distance_to(pos)
			if dd < best_d:
				best_d = dd
				best = idx
		if best == null:
			var coin = CoinScript.new()
			coin_layer.add_child(coin)
			coin.setup(1, pos, null)
			coin.frozen = true
			coin.value = int(arr[2])
			coin.position = pos
		else:
			used[best] = true
			(nodes[best] as Node2D).position = pos
			(nodes[best] as GoldCoin).value = int(arr[2])
	for idx in nodes.size():
		if not used.has(idx):
			(nodes[idx] as Node2D).queue_free()

func mp_apply_wave(arr: Array) -> void:
	if arr.size() < 12:
		return
	cur_stage = int(arr[0])
	cur_diff = int(arr[1])
	wave_idx = int(arr[2])
	wave_quota = int(arr[3])
	wave_killed = int(arr[4])
	wave_active = bool(arr[5])
	game_time = float(arr[6])
	kill_count = int(arr[7])
	progress["essence"] = int(arr[8])
	between_timer = float(arr[9])
	var seq := int(arr[10])
	if seq > msg_seen:
		msg_seen = seq
		say(str(arr[11]))

func mp_apply_shot(from: Vector2, dir: Vector2, speed: float, dmg: int, col: Color) -> void:
	var shot := Projectile.new()
	fx_layer.add_child(shot)
	shot.setup(from, dir, speed, dmg, col, world, player)
	shot.harmless = true
	shots.append(shot)
	Sfx.play(self, "shoot", -10.0)

func mp_apply_fx(fx_type: int, x: float, y: float, s: float) -> void:
	fx_layer.add_child(AttackEffect.new(fx_type, x, y, 0.0, s))

func mp_apply_float(txt: String, x: float, y: float, col: Color, size: int) -> void:
	_float_text(txt, Vector2(x, y), col, size)

func mp_on_begin(seed_value: int, stage: int, diff: int, host_champ: int) -> void:
	mp_seed = seed_value
	start_game(mp_own_champ, stage, diff, seed_value, [host_champ])

func mp_on_force_state(s: int) -> void:
	if s == 0:
		_show_gameover_client()
	elif s == 1:
		_show_victory_client()

func mp_on_to_menu() -> void:
	_enter_menu()

func _show_gameover_client() -> void:
	state = State.GAMEOVER
	_hide_all()
	var gw := StageData.global_wave(cur_stage, wave_idx)
	var kills_lbl: Label = _find_label(gameover_layer, "Kills")
	if kills_lbl:
		kills_lbl.text = "Inimigos derrotados: %d   •   Onda %d/15" % [kill_count, gw]
	var lv_lbl := _find_label(gameover_layer, "Level")
	if lv_lbl and player:
		lv_lbl.text = "Nível atingido: %d   •   Gold: %d" % [player.level, player.gold]
	gameover_layer.visible = true
	Sfx.play(self, "defeat")

func _show_victory_client() -> void:
	state = State.VICTORY
	_hide_all()
	var info_lbl := _find_label(victory_layer, "Info")
	if info_lbl and player:
		info_lbl.text = "%s zerou %s no %s!\nKills: %d   •   Nível: %d   •   Gold: %d\nTempo: %02d:%02d" % [
			player.champ_name, StageData.stage_name(cur_stage), StageData.diff_name(cur_diff),
			kill_count, player.level, player.gold, int(game_time / 60.0), int(game_time) % 60]
	var unl_lbl := _find_label(victory_layer, "Unlocks")
	if unl_lbl:
		unl_lbl.text = "Progresso salvo no host!"
	victory_layer.visible = true
	Sfx.play(self, "victory")

# =====================================================================
#  INPUT
# =====================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var ke := event as InputEventKey
		var key := ke.physical_keycode
		if key == KEY_NONE:
			key = ke.keycode

		match state:
			State.MENU:
				if menu_ui.handle_key(key):
					get_viewport().set_input_as_handled()
			State.SETTINGS:
				if settings_ui.handle_key(key):
					get_viewport().set_input_as_handled()
			State.MULTI:
				if key == KEY_ESCAPE:
					_mp_lobby_back()
				get_viewport().set_input_as_handled()
			State.PROFILE:
				if key == KEY_ESCAPE:
					_enter_menu()
				get_viewport().set_input_as_handled()
			State.CHAMP:
				if select_ui.handle_key(key):
					get_viewport().set_input_as_handled()
			State.STAGE:
				if stage_ui.handle_key(key):
					get_viewport().set_input_as_handled()
			State.MENUSHOP:
				if menushop_ui.handle_key(key):
					get_viewport().set_input_as_handled()
			State.GAMEOVER, State.VICTORY:
				if key == KEY_ENTER or key == KEY_KP_ENTER:
					_enter_menu()
				elif key == KEY_R and mp != 2:
					start_game()
				get_viewport().set_input_as_handled()
			State.SHOP:
				shop.handle_key(key)
				if key == KEY_TAB or key == KEY_ESCAPE \
						or GameSettings.match_key(settings, "shop", key) \
						or GameSettings.match_key(settings, "pause", key):
					_close_shop()
				get_viewport().set_input_as_handled()
			State.PAUSE:
				if key == KEY_ESCAPE or GameSettings.match_key(settings, "pause", key):
					_set_pause(false)
				get_viewport().set_input_as_handled()
			State.PLAY:
				if shop.visible:
					# Loja aberta no multiplayer: teclas vão para ela, sem lutar.
					shop.handle_key(key)
					if key == KEY_TAB or key == KEY_ESCAPE \
							or GameSettings.match_key(settings, "shop", key):
						_close_shop()
					get_viewport().set_input_as_handled()
					return
				if GameSettings.match_key(settings, "shop", key):
					_open_shop()
					get_viewport().set_input_as_handled()
				elif GameSettings.match_key(settings, "pause", key) or key == KEY_ESCAPE:
					if mp != 0:
						say("Sem pausa no multiplayer!")
					else:
						_set_pause(true)
					get_viewport().set_input_as_handled()
				elif GameSettings.match_key(settings, "skip", key):
					_skip_wave()
					get_viewport().set_input_as_handled()
				elif GameSettings.match_key(settings, "attack", key):
					_do_basic_attack()
					get_viewport().set_input_as_handled()
				elif GameSettings.match_key(settings, "skill1", key):
					_do_cast(0)
				elif GameSettings.match_key(settings, "skill2", key):
					_do_cast(1)
				elif GameSettings.match_key(settings, "skill3", key):
					_do_cast(2)
				elif GameSettings.match_key(settings, "skill4", key):
					_do_cast(3)
				elif GameSettings.match_key(settings, "skill5", key):
					_do_cast(4)
				elif GameSettings.match_key(settings, "channel", key):
					_toggle_channel()
				elif GameSettings.match_key(settings, "item", key):
					_use_first_item()

func _open_shop() -> void:
	if player and player.channeling:
		player.channeling = false
	Sfx.play(self, "click")
	if mp != 0:
		# No multiplayer o jogo continua rolando (sem pausa).
		shop.open()
		say("Loja aberta — o jogo continua! TAB fecha.")
		return
	state = State.SHOP
	_set_ally_controlled(false)
	shop.open()

func _close_shop() -> void:
	shop.close()
	if mp == 0:
		state = State.PLAY
		_set_ally_controlled(true)

## Trava/destrava o movimento com a loja aberta (solo pausa o mundo).
func _set_ally_controlled(v: bool) -> void:
	if player != null and is_instance_valid(player):
		player.controlled = v
	for pl in allies:
		if pl != null and is_instance_valid(pl):
			(pl as Player).controlled = v

func _set_pause(v: bool) -> void:
	pause_layer.visible = v
	state = State.PAUSE if v else State.PLAY
	if mp == 1:
		say("⏸ Host pausou." if v else "▶ Host continuou!")
		if _relay():
			_host_net_tick(999.0)

func _toggle_channel(pl: Player = null) -> void:
	if mp == 2 and pl == null:
		return
	var q := pl if pl != null else player
	if q == null:
		return
	var started := q.toggle_channel()
	if started:
		say("Canalizando mana... (fique parado!) Pressione E para sair.")
	elif q.channeling == false and q.mana >= q.max_mana:
		say("Mana já está cheia!")
	else:
		say("Canalização cancelada.")
	q.queue_redraw()

func _do_basic_attack(pl: Player = null) -> void:
	if mp == 2 and pl == null:
		return
	var q := pl if pl != null else player
	if q == null:
		return
	var result = q.basic_attack(enemies)
	if result == null:
		if q.attack_cd <= 0.0 and not q.channeling:
			say("Nenhum alvo no alcance! (%dpx)" % q.attack_range)
		return
	var target = result.target
	var pos: Vector2 = target.position
	# Efeito do personagem + estrela de critico por cima (antes: slash generico).
	_spawn_role_fx(pos, SkillIcon.basic_effect_for(q.role), 0.85)
	if result.crit:
		_spawn_role_fx(pos, AttackEffect.Type.CRIT, 1.0)
		add_shake(6.0)
	Sfx.play(self, "hit", -8.0)
	_float_text(str(result.dmg), pos + Vector2(0, -30),
		Color(1, 0.85, 0.2) if result.crit else Color(1, 1, 0.5), 15 if result.crit else 12)
	if not target.is_alive():
		_on_enemy_killed(target)

func _do_cast(index: int, pl: Player = null) -> void:
	if mp == 2 and pl == null:
		return
	var q := pl if pl != null else player
	if q == null:
		return
	if index >= q.skills.size():
		say("Slot %d bloqueado — desbloqueie skills no menu (◆)!" % (index + 1))
		return
	var result: Dictionary = q.cast_skill(index, enemies)
	if not result.get("ok", false):
		say(result.get("reason", "Sem mana / em cooldown!"))
		return
	if result.kind == "heal":
		_spawn_heal(q.position)
		_spawn_skill_vfx(q.role, _slot_vfx(index), q.position, index >= 4)
		_float_text("+%d" % result.amount, q.position + Vector2(0, -36),
			Color(0.4, 1, 0.5), 14)
		return
	var target = result.target
	# Efeito do personagem (antes: burst generico por kind). Ultimate maior.
	var fx_type: int = SkillIcon.effect_for(q.role, str(result.kind), index)
	_spawn_role_fx(target.position, fx_type, 1.25 if index >= 4 else 1.0)
	_spawn_skill_vfx(q.role, _slot_vfx(index), target.position, index >= 4)
	add_shake(3.0)
	if index >= 4:
		add_shake(5.0)
	_float_text(str(result.dmg), target.position + Vector2(0, -30), Color(0.5, 0.9, 1), 14)
	say("%s %s! −%d" % [SkillIcon.glyph(q.role, str(result.kind), index), result.name, result.dmg])
	if not target.is_alive():
		_on_enemy_killed(target)

func try_buy_upgrade(idx: int, pl: Player = null) -> void:
	if mp == 2 and pl == null:
		netplay.send_buy_upgrade(idx)
		return
	var q := pl if pl != null else player
	if q == null:
		return
	if idx < 0 or idx >= ChampData.UPGRADE_DESCS.size():
		return
	if q.buy_upgrade(idx):
		say("Comprado: %s" % ChampData.UPGRADE_DESCS[idx])
		Sfx.play(self, "buy")
		_spawn_heal(q.position)
	else:
		say("Gold insuficiente!")
		Sfx.play(self, "error")

func _use_first_item(pl: Player = null) -> void:
	if mp == 2 and pl == null:
		return
	var q := pl if pl != null else player
	if q == null or q.inventory.is_empty():
		say("Inventário vazio! Compre itens na loja (TAB).")
		return
	# usa o primeiro consumível (equip vai para equipar via loja/inventário)
	var used := false
	for i in q.inventory.size():
		var item: Item = q.inventory[i]
		if item is Equipment:
			continue
		if q.use_item(i):
			say("Usou: %s" % item.name)
			Sfx.play(self, "potion")
			_spawn_heal(q.position)
			_float_text(item.name, q.position + Vector2(0, -40),
				Color(0.5, 0.9, 1), 13)
			used = true
			break
	if not used:
		# só equipamentos — equipa o primeiro
		if q.equip_item(0):
			var eq_name := "item"
			if q.weapon:
				eq_name = q.weapon.name
			elif q.armor:
				eq_name = q.armor.name
			say("Equipou: %s" % eq_name)
		else:
			say("Nada para usar agora.")

## Loja da run: client pede, host aplica. Idas vindas da shop_ui.
func mp_buy_item(idx: int) -> void:
	if mp == 2:
		netplay.send_buy_item(idx)
		return

func _clone_shop_item(template: Item) -> Item:
	if template is HealthPotion:
		return HealthPotion.new(template.type, template.heal_amount)
	elif template is ManaPotion:
		return ManaPotion.new(template.type, template.mana_amount)
	elif template is Elixir:
		return Elixir.new(template.type, template.hp_restore, template.mp_restore)
	elif template is Equipment:
		return Equipment.new(template.type, template.stat_type, template.bonus_value)
	return null

func mp_on_buy_upgrade(pid: int, idx: int) -> void:
	var pl = _ally_of(pid)
	if pl != null:
		try_buy_upgrade(idx, pl)

func mp_on_buy_item(pid: int, idx: int) -> void:
	var pl = _ally_of(pid)
	if pl == null:
		return
	if shop._shop_items == null or idx < 0 or idx >= shop._shop_items.size():
		return
	var clone := _clone_shop_item(shop._shop_items[idx])
	if clone == null:
		return
	if (pl as Player).buy_item(clone):
		say("%s comprou: %s" % [(pl as Player).champ_name, clone.name])
		Sfx.play(self, "buy")
	else:
		say("%s sem gold!" % (pl as Player).champ_name)
		Sfx.play(self, "error")

# =====================================================================
#  MORTE DE INIMIGO → GOLD DROP + PROGRESSO DA ONDA
# =====================================================================
func _on_enemy_killed(e) -> void:
	kill_count += 1
	wave_killed += 1
	if player:
		player.gain_exp(e.exp_reward)
	for pl in allies:
		if pl != null and is_instance_valid(pl):
			(pl as Player).gain_exp(e.exp_reward)
	_spawn_hit_burst(e.position)
	# chefões balançam muito a tela
	if e.is_boss():
		add_shake(12.0)
		say("★ BOSS derrotado! +%d XP • +%d gold ★" % [e.exp_reward, e.gold_reward])
	elif e.is_miniboss():
		add_shake(9.0)
		say("👹 MINI-BOSS derrotado! +%d XP • +%d gold" % [e.exp_reward, e.gold_reward])
	elif e.is_elite:
		add_shake(7.0)
		say("◆ ELITE caiu! +%d XP" % e.exp_reward)
	else:
		add_shake(4.0)

	# divide o gold em moedas (chefões geram chuva de moedas)
	var total: int = e.gold_reward
	var coins := clampi(int(total / 12.0) + 1, 1, 10)
	var each := maxi(1, int(total / float(coins)))
	var rest := total - each * (coins - 1)
	for i in coins:
		var v := each if i < coins - 1 else maxi(1, rest)
		if v <= 0:
			continue
		var coin = CoinScript.new()
		coin_layer.add_child(coin)
		var tp := _nearest_alive(e.position)
		if tp == null:
			tp = player
		coin.setup(v, e.position, tp)
		coin.collected.connect(func(amount):
			if tp != null and is_instance_valid(tp):
				tp.add_gold(amount)
				Sfx.play(self, "coin", -4.0)
				_float_text("+%d ⬤" % amount, tp.position + Vector2(0, -40),
					Color(1, 0.85, 0.25), 13)
		)
	# EXP flutuante
	_float_text("+%d XP" % e.exp_reward, e.position + Vector2(0, -46), Color(0.8, 0.7, 1), 12)
	# Progresso da onda
	if wave_active:
		var left := maxi(0, wave_quota - wave_killed)
		if left > 0 and left % 5 == 0:
			say("Faltam %d na onda %d/5!" % [left, wave_idx + 1])

# =====================================================================
#  SPAWN / FX
# =====================================================================
func _spawn_next() -> void:
	if world == null or player == null or wave_spawned >= wave_quota:
		return
	# Ordem de entrada: chefões primeiro, depois mini-bosses, depois a massa.
	if boss_left > 0:
		boss_left -= 1
		_spawn_boss()
		return
	if mini_left > 0:
		mini_left -= 1
		_spawn_miniboss()
		return
	var is_last := wave_idx == StageData.WAVES_PER_STAGE - 1
	# Elites ficam mais comuns no fim da fase e nas dificuldades altas.
	var elite_chance := 0.05 + wave_idx * 0.015 + cur_diff * 0.05
	if is_last:
		elite_chance += 0.08
	_spawn_minion(randf() < elite_chance)

func _spawn_boss() -> void:
	var pos := _pick_spawn_pos()
	if pos == Vector2.INF:
		# Sem lugar: devolve a ficha para tentar de novo no próximo tick.
		boss_left += 1
		return
	var m := _diff_mults()
	# Chefão tankudo de verdade + escala extra com a dificuldade:
	# no IMPOSSÍVEL ele vem com muito mais vida e mais rápido.
	m["hp"] = float(m.get("hp", 1.0)) * 2.6 * (1.0 + cur_diff * 0.2)
	m["atk"] = float(m.get("atk", 1.0)) * 1.4 * (1.0 + cur_diff * 0.1)
	m["df"] = float(m.get("df", 1.0)) * 1.3
	m["gold"] = float(m.get("gold", 1.0)) * 3.0
	m["exp"] = float(m.get("exp", 1.0)) * 3.0
	m["speed"] = float(m.get("speed", 1.0)) * (1.1 + cur_diff * 0.1)
	m["boss"] = true
	var lvl := maxi(2, _wave_level() + 1)
	var e = EnemyScript.new()
	e.name = "Boss"
	e.net_id = net_id_counter
	net_id_counter += 1
	e.world = world
	e.stage_idx = cur_stage
	e.setup(StageData.boss_type(cur_stage), lvl, m)
	e.position = pos
	e.died.connect(_on_enemy_killed)
	e.shoot.connect(_on_enemy_shoot)
	entities.add_child(e)
	enemies.append(e)
	wave_spawned += 1
	say("★★ %s Lv.%d apareceu! ★★" % [e.type_name, lvl])
	add_shake(8.0)

## Mini-boss: um brutamontes (Golem/Jungle) com 2.4x HP. Aparece no meio
## da run e ao lado do chefão na onda final. Nas dificuldades altas vem
## em dupla, com mais vida e mais rápido.
func _spawn_miniboss() -> void:
	var pos := _pick_spawn_pos()
	if pos == Vector2.INF:
		mini_left += 1
		return
	var m := _diff_mults()
	m["hp"] = float(m.get("hp", 1.0)) * 2.0 * (1.0 + cur_diff * 0.15)
	m["atk"] = float(m.get("atk", 1.0)) * 1.35 * (1.0 + cur_diff * 0.08)
	m["df"] = float(m.get("df", 1.0)) * 1.2
	m["gold"] = float(m.get("gold", 1.0)) * 2.5
	m["exp"] = float(m.get("exp", 1.0)) * 2.5
	m["speed"] = float(m.get("speed", 1.0)) * 1.05
	m["miniboss"] = true
	var is_last := wave_idx == StageData.WAVES_PER_STAGE - 1
	var lvl := maxi(2, _wave_level() + (1 if is_last else 0))
	var pool := ["GOLEM", "JUNGLE"]
	var e = EnemyScript.new()
	e.name = "MiniBoss"
	e.net_id = net_id_counter
	net_id_counter += 1
	e.world = world
	e.stage_idx = cur_stage
	e.setup(pool[randi() % pool.size()], lvl, m)
	e.position = pos
	e.died.connect(_on_enemy_killed)
	e.shoot.connect(_on_enemy_shoot)
	entities.add_child(e)
	enemies.append(e)
	wave_spawned += 1
	say("👹 MINI-BOSS %s Lv.%d apareceu!" % [e.type_name, lvl])
	add_shake(6.0)

func _spawn_minion(force_elite: bool = false) -> void:
	var pos := _pick_spawn_pos()
	if pos == Vector2.INF:
		return
	var m := _diff_mults()
	if force_elite:
		m["hp"] = float(m.get("hp", 1.0)) * 1.8
		m["atk"] = float(m.get("atk", 1.0)) * 1.25
		m["gold"] = float(m.get("gold", 1.0)) * 2.0
		m["exp"] = float(m.get("exp", 1.0)) * 1.5
		m["elite"] = true
	var lvl := _wave_level()
	var e = EnemyScript.new()
	e.name = "Enemy"
	e.net_id = net_id_counter
	net_id_counter += 1
	e.world = world
	e.stage_idx = cur_stage
	e.setup(EnemyData.random_type(lvl, cur_stage), lvl, m)
	e.position = pos
	e.died.connect(_on_enemy_killed)
	e.shoot.connect(_on_enemy_shoot)
	entities.add_child(e)
	enemies.append(e)
	wave_spawned += 1

func _pick_spawn_pos() -> Vector2:
	if walk_cache.is_empty():
		walk_cache = world.walkable_tiles()
	var walkable := walk_cache
	if walkable.is_empty() or player == null:
		return Vector2.INF
	for attempt in 40:
		var tile: Vector2i = walkable[randi() % walkable.size()]
		var pos := Vector2(tile.x * World.TILE + 16, tile.y * World.TILE + 16)
		if pos.distance_to(player.position) < 220.0:
			continue
		if world.is_solid_at(pos.x, pos.y):
			continue
		return pos
	# Fallback: aceita mais perto se o mapa apertou.
	for attempt in 40:
		var tile: Vector2i = walkable[randi() % walkable.size()]
		var pos := Vector2(tile.x * World.TILE + 16, tile.y * World.TILE + 16)
		if world.is_solid_at(pos.x, pos.y):
			continue
		return pos
	return Vector2.INF

func spawn_random_enemy() -> void:
	# Compat: fora das waves (se algum dia precisar), conta na cota atual.
	if wave_active:
		_spawn_minion(false)
	else:
		_spawn_minion(false)

func add_shake(amount: float) -> void:
	if not GameSettings.shake_enabled(settings):
		return
	shake = minf(14.0, shake + amount)

## Mensagem no HUD (+ fila para o cliente no multiplayer).
func say(text: String) -> void:
	hud.add_message(text)
	if _relay():
		msg_seq += 1
		msg_last = text

## Pode replicar? (host com aliado conectado de verdade).
func _relay() -> bool:
	return mp == 1 and netplay.has_ally()

func _float_text(msg: String, pos: Vector2, col: Color, size: int) -> void:
	if msg == "":
		return
	if _relay():
		netplay.float_txt.rpc(msg, pos.x, pos.y, col, size)
	var ft = FloatingTextScript.new()
	fx_layer.add_child(ft)
	ft.setup(msg, col, pos, size, 1.1)

## Slot 1-2 → q, 3-4 → w, 5 → ultimate (poses/VFX do kit).
func _slot_vfx(index: int) -> String:
	if index >= 4:
		return "ultimate"
	if index >= 2:
		return "skill_w"
	return "skill_q"

## VFX texturizado do kit (silencioso se faltar arquivo: o procedural cobre).
func _spawn_skill_vfx(role: String, kind: String, pos: Vector2, big: bool) -> void:
	var rel := SpriteKit.champ_vfx(role, kind)
	if SpriteKit.tex(rel) == null:
		return
	SpriteFx.spawn(fx_layer, rel, pos, 120.0 if big else 70.0,
		0.4 if big else 0.3, player.flip if player != null else 1.0)

## Efeito de ataque do personagem (tipo vem do SkillIcon, escala por slot).
func _spawn_role_fx(pos: Vector2, fx_type: int, scale_p: float = 1.0) -> void:
	if _relay():
		netplay.fx_spawn.rpc(fx_type, pos.x, pos.y, scale_p)
	fx_layer.add_child(AttackEffect.new(
		fx_type, pos.x, pos.y, randf_range(-0.3, 0.3), scale_p))

func _spawn_heal(pos: Vector2) -> void:
	if _relay():
		netplay.fx_spawn.rpc(AttackEffect.Type.HEAL, pos.x, pos.y, 1.0)
	fx_layer.add_child(AttackEffect.new(AttackEffect.Type.HEAL, pos.x, pos.y))

func _spawn_hit_burst(pos: Vector2) -> void:
	if _relay():
		netplay.fx_spawn.rpc(AttackEffect.Type.ENEMY_HIT, pos.x, pos.y, 1.0)
	fx_layer.add_child(AttackEffect.new(AttackEffect.Type.ENEMY_HIT, pos.x, pos.y))
	var n := 8
	if GameSettings.quality_cache == 1:
		n = 5
	elif GameSettings.quality_cache >= 2:
		n = 3
	for i in n:
		var p := ParticleFx.new()
		fx_layer.add_child(p)
		var a := randf() * TAU
		var sp := randf_range(1.5, 4.5)
		p.setup(pos.x, pos.y, cos(a) * sp, sin(a) * sp, _spark_color())

## Faísca de impacto tingida com a cor do campeão.
func _spark_color() -> Color:
	var base := Color(1, randf_range(0.4, 0.8), 0.25)
	if player == null:
		return base
	return base.lerp(SkillIcon.role_color(player.role), 0.45)

## Inimigo ranged atirou: cria o projétil (dragão-boss cospe 3).
func _on_enemy_shoot(e) -> void:
	if not is_instance_valid(e):
		return
	var tgt := _nearest_alive(e.position)
	if tgt == null:
		return
	var base_dir: Vector2 = (tgt.position - e.position).normalized()
	var n := 3 if (e.type_key == "DRAGON" and e.is_boss()) else 1
	for i in n:
		var ang := 0.0
		if n > 1:
			ang = (i - 1) * 0.18
		var shot := Projectile.new()
		fx_layer.add_child(shot)
		shot.setup(e.position, base_dir.rotated(ang),
			280.0 if n > 1 else 250.0, e.calc_damage(), e.bolt_color(), world, player)
		shot.hit_player.connect(_on_shot_hit)
		shots.append(shot)
	Sfx.play(self, "shoot", -6.0)

func _on_shot_hit(proj) -> void:
	if mp == 2:
		return  # dano é autoridade do host
	var tgt := _nearest_alive(proj.position)
	if tgt == null:
		return
	tgt.take_damage(proj.damage)
	fx_layer.add_child(AttackEffect.new(
		AttackEffect.Type.ENEMY_HIT, tgt.position.x, tgt.position.y))
	add_shake(2.0)
	hud.queue_redraw()
