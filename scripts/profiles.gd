class_name Profiles
extends Object

## Perfis locais (login offline): cada perfil tem seu save e sua essência.
## Sem servidor: o progresso fica neste aparelho e nunca se perde ao
## trocar de perfil. O perfil "0" usa o save legado original.

const PROFILES_PATH := "user://profiles.cfg"
const LEGACY_SAVE := "user://rpg_league_save.cfg"

static func _load() -> Dictionary:
	var d := { current = "0", profiles = [{ id = "0", name = "Jogador" }] }
	var cfg := ConfigFile.new()
	if cfg.load(PROFILES_PATH) != OK:
		return d
	d.current = str(cfg.get_value("profiles", "current", "0"))
	var arr = cfg.get_value("profiles", "list", [])
	if arr is Array and not (arr as Array).is_empty():
		var clean := []
		for p in (arr as Array):
			if p is Dictionary and (p as Dictionary).has("id"):
				clean.append({ id = str((p as Dictionary).get("id", "0")),
					name = str((p as Dictionary).get("name", "Jogador")) })
		if not clean.is_empty():
			d.profiles = clean
	return d

static func _save(d: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profiles", "current", str(d.get("current", "0")))
	cfg.set_value("profiles", "list", d.get("profiles", []))
	cfg.save(PROFILES_PATH)

## Garante o arquivo (migra o save antigo para o perfil Jogador).
static func ensure() -> Dictionary:
	var d := _load()
	_save(d)
	return d

static func list() -> Array:
	return _load().get("profiles", [])

static func current_id() -> String:
	return str(_load().get("current", "0"))

static func current_name() -> String:
	var cid := current_id()
	for p in list():
		if str((p as Dictionary).get("id", "")) == cid:
			return str((p as Dictionary).get("name", "Jogador"))
	return "Jogador"

static func select(pid: String) -> void:
	var d := _load()
	d.current = pid
	_save(d)

static func create(pname: String) -> String:
	var d := _load()
	var base := pname.strip_edges()
	if base == "":
		base = "Jogador %d" % ((d.get("profiles", []) as Array).size() + 1)
	var nid := str(Time.get_unix_time_from_system())
	while _has_id(d, nid):
		nid += "x"
	(d.get("profiles", []) as Array).append({ id = nid, name = base })
	d.current = nid
	_save(d)
	return nid

static func _has_id(d: Dictionary, pid: String) -> bool:
	for p in (d.get("profiles", []) as Array):
		if str((p as Dictionary).get("id", "")) == pid:
			return true
	return false

static func remove(pid: String) -> bool:
	var d := _load()
	var rows: Array = d.get("profiles", [])
	if rows.size() <= 1:
		return false
	var kept := []
	for p in rows:
		if str((p as Dictionary).get("id", "")) == pid:
			DirAccess.remove_absolute(save_path_for(pid))
		else:
			kept.append(p)
	if kept.size() == rows.size():
		return false
	d.profiles = kept
	if str(d.get("current", "")) == pid:
		d.current = str((kept[0] as Dictionary).get("id", "0"))
	_save(d)
	return true

static func save_path_for(pid: String) -> String:
	if pid == "0":
		return LEGACY_SAVE
	return "user://rpg_league_save_%s.cfg" % pid

static func save_path() -> String:
	return save_path_for(current_id())
