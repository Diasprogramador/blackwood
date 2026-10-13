class_name Sfx
extends Object

## PCM original pré-renderizado: camadas de impacto, ar e harmônicos.
## Buses: Master (padrão) + Music + SFX. Volumes vêm do GameSettings.

static var _variation := 0

static var _cache := {}
static var _last_played := {}
static var _voices := 0

static func ensure_buses(d: Dictionary) -> void:
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.get_bus_index(bus), "Master")
	apply_volumes(d)

static func apply_volumes(d: Dictionary) -> void:
	_set_bus_vol("Master", int(d.get("master", 80)))
	_set_bus_vol("Music", int(d.get("music", 70)))
	_set_bus_vol("SFX", int(d.get("sfx", 90)))

static func _set_bus_vol(bus: String, v: int) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	if v <= 0:
		AudioServer.set_bus_mute(i, true)
	else:
		AudioServer.set_bus_mute(i, false)
		AudioServer.set_bus_volume_db(i, linear_to_db(clampf(v / 100.0, 0.01, 1.0)))

## Toca um efeito (click, coin, hit, potion, levelup, victory, defeat, buy, error, shoot).
static func play(parent: Node, id: String, vol_db: float = 0.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var now := Time.get_ticks_msec()
	if _voices >= 12 or now - int(_last_played.get(id, -1000)) < 65:
		return
	_last_played[id] = now
	var stream: AudioStreamWAV = _sample(id)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "SFX"
	p.volume_db = vol_db - 8.0
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	if id in ["hit","hurt","tank","assassin","mage","marksman","support","shoot","dash"]:
		_variation = (_variation + 1) % 5
		p.pitch_scale = 0.96 + _variation * 0.02
	parent.add_child(p)
	_voices += 1
	p.tree_exiting.connect(func(): _voices -= 1)
	p.finished.connect(func(): p.queue_free())
	p.play()

static func _sample(id: String) -> AudioStreamWAV:
	if _cache.has(id): return _cache[id]
	var path := "res://assets/audio/%s.wav" % id
	if not ResourceLoader.exists(path): return null
	var stream := load(path) as AudioStreamWAV
	_cache[id] = stream
	return stream
