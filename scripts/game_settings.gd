class_name GameSettings
extends Object

## Configurações do jogo: volumes, teclas, tela cheia e screen shake.
## Salvas em user://rpg_league_settings.cfg (separado do progresso).

const SAVE_PATH := "user://rpg_league_settings.cfg"

const ACTIONS := [
	{ id = "move_up", label = "Mover: cima", def = [KEY_W, KEY_UP] },
	{ id = "move_down", label = "Mover: baixo", def = [KEY_S, KEY_DOWN] },
	{ id = "move_left", label = "Mover: esquerda", def = [KEY_A, KEY_LEFT] },
	{ id = "move_right", label = "Mover: direita", def = [KEY_D, KEY_RIGHT] },
	{ id = "attack", label = "Ataque básico", def = [KEY_SPACE] },
	{ id = "skill1", label = "Habilidade 1", def = [KEY_1] },
	{ id = "skill2", label = "Habilidade 2", def = [KEY_2] },
	{ id = "skill3", label = "Habilidade 3", def = [KEY_3] },
	{ id = "skill4", label = "Habilidade 4", def = [KEY_4] },
	{ id = "skill5", label = "Habilidade 5", def = [KEY_5] },
	{ id = "channel", label = "Canalizar mana", def = [KEY_E] },
	{ id = "item", label = "Usar item", def = [KEY_Q] },
	{ id = "shop", label = "Abrir loja", def = [KEY_TAB] },
	{ id = "pause", label = "Pausar", def = [KEY_ESCAPE] },
]

static func default_data() -> Dictionary:
	var keys := {}
	for a in ACTIONS:
		keys[a.id] = (a.def as Array).duplicate()
	return {
		"master": 80, "music": 70, "sfx": 90,
		"fullscreen": false, "shake": true,
		"keys": keys,
	}

static func load_data() -> Dictionary:
	var d := default_data()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return d
	d["master"] = clampi(int(cfg.get_value("audio", "master", 80)), 0, 100)
	d["music"] = clampi(int(cfg.get_value("audio", "music", 70)), 0, 100)
	d["sfx"] = clampi(int(cfg.get_value("audio", "sfx", 90)), 0, 100)
	d["fullscreen"] = bool(cfg.get_value("video", "fullscreen", false))
	d["shake"] = bool(cfg.get_value("video", "shake", true))
	var keys: Dictionary = d["keys"]
	for a in ACTIONS:
		var loaded = cfg.get_value("keys", a.id, [])
		if loaded is Array and not (loaded as Array).is_empty():
			var arr: Array = []
			for v in (loaded as Array):
				arr.append(int(v))
			keys[a.id] = arr
	return d

static func save_data(d: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", int(d.get("master", 80)))
	cfg.set_value("audio", "music", int(d.get("music", 70)))
	cfg.set_value("audio", "sfx", int(d.get("sfx", 90)))
	cfg.set_value("video", "fullscreen", bool(d.get("fullscreen", false)))
	cfg.set_value("video", "shake", bool(d.get("shake", true)))
	var keys: Dictionary = d.get("keys", {})
	for a in ACTIONS:
		if keys.has(a.id):
			cfg.set_value("keys", a.id, keys[a.id])
	cfg.save(SAVE_PATH)

static func reset_keys(d: Dictionary) -> void:
	var keys: Dictionary = d.get("keys", {})
	for a in ACTIONS:
		keys[a.id] = (a.def as Array).duplicate()
	save_data(d)

## Verdade se a tecla (física) dispara a ação.
static func match_key(d: Dictionary, action_id: String, keycode: int) -> bool:
	var keys: Dictionary = d.get("keys", {})
	if not keys.has(action_id):
		return false
	return int(keycode) in (keys[action_id] as Array)

## Verdade se QUALQUER tecla da ação está pressionada (movimento).
static func held(d: Dictionary, action_id: String) -> bool:
	var keys: Dictionary = d.get("keys", {})
	if not keys.has(action_id):
		return false
	for code in (keys[action_id] as Array):
		if Input.is_physical_key_pressed(int(code)):
			return true
	return false

## Rótulo curto da primeira tecla da ação ("W", "ESPAÇO", "TAB"...).
static func key_label(d: Dictionary, action_id: String) -> String:
	var keys: Dictionary = d.get("keys", {})
	if not keys.has(action_id) or (keys[action_id] as Array).is_empty():
		return "—"
	return OS.get_keycode_string(int((keys[action_id] as Array)[0]))

static func apply_video(d: Dictionary) -> void:
	if bool(d.get("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

static func shake_enabled(d: Dictionary) -> bool:
	return bool(d.get("shake", true))
