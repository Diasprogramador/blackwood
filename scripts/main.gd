extends Node2D

## Main do jogo Godot: estados (select → play → pause/shop → gameover),
## spawn, câmera, drop de gold e integração das UIs.
## Port de Main.java (modo gráfico) + GamePanel.java (loop, spawn, input, overlays).

enum State { MENU, SETTINGS, CHAMP, STAGE, MENUSHOP, PLAY, PAUSE, SHOP, GAMEOVER, VICTORY }

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
	menu_ui.shop_pressed.connect(func(): _enter_menushop(State.MENU))
	menu_ui.settings_pressed.connect(_enter_settings)
	menu_ui.exit_pressed.connect(func(): get_tree().quit())
	menu_ui.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	ui_root.add_child(menu_ui)

	settings_ui = SettingsMenu.new()
	settings_ui.name = "SettingsMenu"
	settings_ui.back_pressed.connect(_enter_menu)
	settings_ui.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	ui_root.add_child(settings_ui)

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

	var menu := _overlay_btn("🏠 Menu principal")
	menu.pressed.connect(func(): _enter_menu())
	v.add_child(menu)

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

func _enter_menu() -> void:
	state = State.MENU
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

func _enter_settings() -> void:
	state = State.SETTINGS
	settings = GameSettings.load_data()
	_hide_all()
	settings_ui.visible = true
	settings_ui.build(settings)

func _on_champ_chosen(champ_idx: int) -> void:
	_selected = clampi(champ_idx, 0, ChampData.CHAMPS.size() - 1)
	_enter_stage()

func _on_stage_start(stage_idx: int, diff_idx: int) -> void:
	start_game(_selected, stage_idx, diff_idx)

func start_game(champ_idx: int = -1, stage_idx: int = -1, diff_idx: int = -1) -> void:
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

	world.generate()
	world.apply_stage(cur_stage)
	minimap_tex = world.build_minimap_image()

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
			hud.add_message(msg)
			_float_text(msg, player.position + Vector2(0, -40), Color(1, 0.9, 0.4), 13)
			Sfx.play(self, "levelup")
	)
	entities.add_child(player)
	camera.position = player.position

	kill_count = 0
	game_time = 0.0
	_spawn_timer = 0.0
	wave_idx = 0
	between_timer = 0.0
	hud.clear_messages()
	_hide_all()
	hud.visible = true
	state = State.PLAY

	_start_wave(0)
	var nskills := player.skills.size()
	var atk_key := GameSettings.key_label(settings, "attack")
	var shop_key := GameSettings.key_label(settings, "shop")
	if nskills == 0:
		hud.add_message("Bem-vindo, %s! %s • %s" % [c.nome, StageData.stage_name(cur_stage), StageData.diff_name(cur_diff)])
		hud.add_message("Só ATK por enquanto — ganhe ◆ nas ondas e desbloqueie skills na LOJA!")
	else:
		hud.add_message("Bem-vindo, %s! %s • %s (%d/5 skills)" % [c.nome, StageData.stage_name(cur_stage), StageData.diff_name(cur_diff), nskills])
		hud.add_message("%s = soco | 1-%d = skills | %s = loja" % [atk_key, nskills, shop_key])
	hud.add_message("Mana é curta: cada skill conta! Sobreviva às 5 ondas!")

func _start_wave(idx: int) -> void:
	wave_idx = idx
	wave_quota = StageData.wave_quota(cur_stage, idx, cur_diff)
	wave_spawned = 0
	wave_killed = 0
	wave_active = true
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
		hud.add_message("★ ONDA FINAL %d/15 — BOSS %s + %d MINI-BOSS! ★" % [gw, StageData.boss_type(cur_stage), mini_left])
		add_shake(6.0)
	elif is_mid:
		# Meio da run: mini-boss (2 no HARD+). A cada 5 ondas tem mini-boss.
		mini_left = 1 if cur_diff < 2 else 2
		hud.add_message("👹 ONDA %d/15 (%s %d/5) — MINI-BOSS à vista! — %d inimigos!" % [gw, StageData.stage_name(cur_stage), idx + 1, wave_quota])
		add_shake(4.0)
	else:
		hud.add_message("— ONDA %d/15 (%s %d/5) — %d inimigos!" % [gw, StageData.stage_name(cur_stage), idx + 1, wave_quota])
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
	return {
		"hp": float(dd.get("hp", 1.0)), "atk": float(dd.get("atk", 1.0)),
		"df": float(dd.get("df", 1.0)), "gold": float(dd.get("gold", 1.0)),
		"exp": float(dd.get("exp", 1.0)), "speed": float(dd.get("speed", 1.0)),
	}

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
	wave_active = false
	between_timer = 0.0
	boss_left = 0
	mini_left = 0

func _on_player_died() -> void:
	if state == State.GAMEOVER or state == State.VICTORY:
		return
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
	game_time += delta

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
			wave_active = false
			if wave_idx >= StageData.WAVES_PER_STAGE - 1:
				_on_victory()
				return
			between_timer = BETWEEN_DELAY
			# Respiro entre ondas + pequena cura (TAB = loja).
			player.heal(int(player.max_hp * 0.15))
			# Essência ◆ = moeda meta: só de ondas/fases, nunca de kills.
			var bonus := StageData.essence_for_wave(cur_stage, wave_idx, cur_diff)
			var total := StageData.add_essence(progress, bonus)
			_float_text("+%d ◆" % bonus, player.position + Vector2(0, -56), Color(0.55, 0.85, 1), 13)
			hud.add_message("Onda %d/5 limpa! +%d ◆ (banco: %d) — TAB = loja" % [wave_idx + 1, bonus, total])
	else:
		# Intervalo entre ondas.
		if wave_killed >= wave_quota and state == State.PLAY:
			between_timer -= delta
			if between_timer <= 0.0:
				_start_wave(wave_idx + 1)

	# IA + ataques dos inimigos
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if e.is_alive():
			e.ai_update(player, delta)
			if e.try_attack(player):
				fx_layer.add_child(AttackEffect.new(
					AttackEffect.Type.ENEMY_HIT, player.position.x, player.position.y))
				add_shake(2.0)
				hud.queue_redraw()
		elif e.death_timer >= 0.0:
			# Cadáver com fade: continua atualizando o sumiço suave.
			e.ai_update(player, delta)

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

	camera.position = player.position if player else camera.position

	# screen shake (críticos, mortes, elites)
	if shake > 0.0:
		shake = maxf(0.0, shake - 60.0 * delta)
		camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	else:
		camera.offset = Vector2.ZERO

	# regenera HUD suavemente
	hud.queue_redraw()

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
				elif key == KEY_R:
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
					return
				if GameSettings.match_key(settings, "shop", key):
					_open_shop()
					get_viewport().set_input_as_handled()
				elif GameSettings.match_key(settings, "pause", key) or key == KEY_ESCAPE:
					_set_pause(true)
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
	state = State.SHOP
	shop.open()

func _close_shop() -> void:
	shop.close()
	state = State.PLAY

func _set_pause(v: bool) -> void:
	pause_layer.visible = v
	state = State.PAUSE if v else State.PLAY

func _toggle_channel() -> void:
	if player == null:
		return
	var started := player.toggle_channel()
	if started:
		hud.add_message("Canalizando mana... (fique parado!) Pressione E para sair.")
	elif player.channeling == false and player.mana >= player.max_mana:
		hud.add_message("Mana já está cheia!")
	else:
		hud.add_message("Canalização cancelada.")
	player.queue_redraw()

func _do_basic_attack() -> void:
	if player == null:
		return
	var result = player.basic_attack(enemies)
	if result == null:
		if player.attack_cd <= 0.0 and not player.channeling:
			hud.add_message("Nenhum alvo no alcance! (%dpx)" % player.attack_range)
		return
	var target = result.target
	var pos: Vector2 = target.position
	# Efeito do personagem + estrela de critico por cima (antes: slash generico).
	_spawn_role_fx(pos, SkillIcon.basic_effect_for(player.role), 0.85)
	if result.crit:
		_spawn_role_fx(pos, AttackEffect.Type.CRIT, 1.0)
		add_shake(6.0)
	Sfx.play(self, "hit", -8.0)
	_float_text(str(result.dmg), pos + Vector2(0, -30),
		Color(1, 0.85, 0.2) if result.crit else Color(1, 1, 0.5), 15 if result.crit else 12)
	if not target.is_alive():
		_on_enemy_killed(target)

func _do_cast(index: int) -> void:
	if player == null:
		return
	if index >= player.skills.size():
		hud.add_message("Slot %d bloqueado — desbloqueie skills no menu (◆)!" % (index + 1))
		return
	var result: Dictionary = player.cast_skill(index, enemies)
	if not result.get("ok", false):
		hud.add_message(result.get("reason", "Sem mana / em cooldown!"))
		return
	if result.kind == "heal":
		_spawn_heal(player.position)
		_spawn_skill_vfx(player.role, _slot_vfx(index), player.position, index >= 4)
		_float_text("+%d" % result.amount, player.position + Vector2(0, -36),
			Color(0.4, 1, 0.5), 14)
		return
	var target = result.target
	# Efeito do personagem (antes: burst generico por kind). Ultimate maior.
	var fx_type: int = SkillIcon.effect_for(player.role, str(result.kind), index)
	_spawn_role_fx(target.position, fx_type, 1.25 if index >= 4 else 1.0)
	_spawn_skill_vfx(player.role, _slot_vfx(index), target.position, index >= 4)
	add_shake(3.0)
	if index >= 4:
		add_shake(5.0)
	_float_text(str(result.dmg), target.position + Vector2(0, -30), Color(0.5, 0.9, 1), 14)
	hud.add_message("%s %s! −%d" % [SkillIcon.glyph(player.role, str(result.kind), index), result.name, result.dmg])
	if not target.is_alive():
		_on_enemy_killed(target)

func try_buy_upgrade(idx: int) -> void:
	if player == null:
		return
	if player.buy_upgrade(idx):
		hud.add_message("Comprado: %s" % ChampData.UPGRADE_DESCS[idx])
		Sfx.play(self, "buy")
		_spawn_heal(player.position)
	else:
		hud.add_message("Gold insuficiente!")
		Sfx.play(self, "error")

func _use_first_item() -> void:
	if player == null or player.inventory.is_empty():
		hud.add_message("Inventário vazio! Compre itens na loja (TAB).")
		return
	# usa o primeiro consumível (equip vai para equipar via loja/inventário)
	var used := false
	for i in player.inventory.size():
		var item: Item = player.inventory[i]
		if item is Equipment:
			continue
		if player.use_item(i):
			hud.add_message("Usou: %s" % item.name)
			Sfx.play(self, "potion")
			_spawn_heal(player.position)
			_float_text(item.name, player.position + Vector2(0, -40),
				Color(0.5, 0.9, 1), 13)
			used = true
			break
	if not used:
		# só equipamentos — equipa o primeiro
		if player.equip_item(0):
			var eq_name := "item"
			if player.weapon:
				eq_name = player.weapon.name
			elif player.armor:
				eq_name = player.armor.name
			hud.add_message("Equipou: %s" % eq_name)
		else:
			hud.add_message("Nada para usar agora.")

# =====================================================================
#  MORTE DE INIMIGO → GOLD DROP + PROGRESSO DA ONDA
# =====================================================================
func _on_enemy_killed(e) -> void:
	kill_count += 1
	wave_killed += 1
	if player:
		player.gain_exp(e.exp_reward)
	_spawn_hit_burst(e.position)
	# chefões balançam muito a tela
	if e.is_boss():
		add_shake(12.0)
		hud.add_message("★ BOSS derrotado! +%d XP • +%d gold ★" % [e.exp_reward, e.gold_reward])
	elif e.is_miniboss():
		add_shake(9.0)
		hud.add_message("👹 MINI-BOSS derrotado! +%d XP • +%d gold" % [e.exp_reward, e.gold_reward])
	elif e.is_elite:
		add_shake(7.0)
		hud.add_message("◆ ELITE caiu! +%d XP" % e.exp_reward)
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
		coin.setup(v, e.position, player)
		coin.collected.connect(func(amount):
			if player:
				player.add_gold(amount)
				Sfx.play(self, "coin", -4.0)
				_float_text("+%d ⬤" % amount, player.position + Vector2(0, -40),
					Color(1, 0.85, 0.25), 13)
		)
	# EXP flutuante
	_float_text("+%d XP" % e.exp_reward, e.position + Vector2(0, -46), Color(0.8, 0.7, 1), 12)
	# Progresso da onda
	if wave_active:
		var left := maxi(0, wave_quota - wave_killed)
		if left > 0 and left % 5 == 0:
			hud.add_message("Faltam %d na onda %d/5!" % [left, wave_idx + 1])

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
	var elite_chance := 0.06 + wave_idx * 0.02 + cur_diff * 0.05
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
	m["hp"] = float(m.get("hp", 1.0)) * 3.0 * (1.0 + cur_diff * 0.2)
	m["atk"] = float(m.get("atk", 1.0)) * 1.6 * (1.0 + cur_diff * 0.1)
	m["df"] = float(m.get("df", 1.0)) * 1.3
	m["gold"] = float(m.get("gold", 1.0)) * 3.0
	m["exp"] = float(m.get("exp", 1.0)) * 3.0
	m["speed"] = float(m.get("speed", 1.0)) * (1.1 + cur_diff * 0.1)
	m["boss"] = true
	var lvl := maxi(2, _wave_level() + 1)
	var e = EnemyScript.new()
	e.name = "Boss"
	e.world = world
	e.stage_idx = cur_stage
	e.setup(StageData.boss_type(cur_stage), lvl, m)
	e.position = pos
	e.died.connect(_on_enemy_killed)
	e.shoot.connect(_on_enemy_shoot)
	entities.add_child(e)
	enemies.append(e)
	wave_spawned += 1
	hud.add_message("★★ %s Lv.%d apareceu! ★★" % [e.type_name, lvl])
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
	m["hp"] = float(m.get("hp", 1.0)) * 2.4 * (1.0 + cur_diff * 0.15)
	m["atk"] = float(m.get("atk", 1.0)) * 1.5 * (1.0 + cur_diff * 0.08)
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
	e.world = world
	e.stage_idx = cur_stage
	e.setup(pool[randi() % pool.size()], lvl, m)
	e.position = pos
	e.died.connect(_on_enemy_killed)
	e.shoot.connect(_on_enemy_shoot)
	entities.add_child(e)
	enemies.append(e)
	wave_spawned += 1
	hud.add_message("👹 MINI-BOSS %s Lv.%d apareceu!" % [e.type_name, lvl])
	add_shake(6.0)

func _spawn_minion(force_elite: bool = false) -> void:
	var pos := _pick_spawn_pos()
	if pos == Vector2.INF:
		return
	var m := _diff_mults()
	if force_elite:
		m["hp"] = float(m.get("hp", 1.0)) * 1.8
		m["atk"] = float(m.get("atk", 1.0)) * 1.4
		m["gold"] = float(m.get("gold", 1.0)) * 2.0
		m["exp"] = float(m.get("exp", 1.0)) * 1.5
		m["elite"] = true
	var lvl := _wave_level()
	var e = EnemyScript.new()
	e.name = "Enemy"
	e.world = world
	e.stage_idx = cur_stage
	e.setup(EnemyData.random_type(lvl), lvl, m)
	e.position = pos
	e.died.connect(_on_enemy_killed)
	e.shoot.connect(_on_enemy_shoot)
	entities.add_child(e)
	enemies.append(e)
	wave_spawned += 1

func _pick_spawn_pos() -> Vector2:
	var walkable := world.walkable_tiles()
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

func _float_text(msg: String, pos: Vector2, col: Color, size: int) -> void:
	if msg == "":
		return
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
	fx_layer.add_child(AttackEffect.new(
		fx_type, pos.x, pos.y, randf_range(-0.3, 0.3), scale_p))

func _spawn_heal(pos: Vector2) -> void:
	fx_layer.add_child(AttackEffect.new(AttackEffect.Type.HEAL, pos.x, pos.y))

func _spawn_hit_burst(pos: Vector2) -> void:
	fx_layer.add_child(AttackEffect.new(AttackEffect.Type.ENEMY_HIT, pos.x, pos.y))
	for i in 8:
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
	if player == null or not is_instance_valid(player) or not player.is_alive():
		return
	if not is_instance_valid(e):
		return
	var base_dir: Vector2 = (player.position - e.position).normalized()
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
	if player != null and is_instance_valid(player) and player.is_alive():
		player.take_damage(proj.damage)
		fx_layer.add_child(AttackEffect.new(
			AttackEffect.Type.ENEMY_HIT, player.position.x, player.position.y))
		add_shake(2.0)
		hud.queue_redraw()
