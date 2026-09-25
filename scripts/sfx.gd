class_name Sfx
extends Object

## Efeitos sonoros procedurais (sem assets): tons gerados em código.
## Buses: Master (padrão) + Music + SFX. Volumes vêm do GameSettings.

const RATE := 22050

static var _cache := {}

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
	if parent == null:
		return
	var stream: AudioStreamWAV = _sample(id)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "SFX"
	p.volume_db = vol_db
	parent.add_child(p)
	p.finished.connect(func(): p.queue_free())
	p.play()

static func _sample(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	var s: AudioStreamWAV = null
	match id:
		"click": s = _sweep(700.0, 900.0, 0.07, 0.5)
		"coin": s = _sweep(1200.0, 1800.0, 0.12, 0.45)
		"hit": s = _noise_hit(0.12)
		"potion": s = _sweep(420.0, 640.0, 0.18, 0.4)
		"levelup": s = _arp([523.0, 659.0, 784.0, 1046.0], 0.09, 0.45)
		"victory": s = _arp([523.0, 659.0, 784.0, 1046.0, 1318.0], 0.14, 0.5)
		"defeat": s = _arp([392.0, 330.0, 262.0, 196.0], 0.18, 0.5)
		"buy": s = _arp([880.0, 1174.0], 0.08, 0.45)
		"error": s = _sweep(220.0, 160.0, 0.15, 0.5)
		"shoot": s = _sweep(900.0, 300.0, 0.12, 0.4)
	if s:
		_cache[id] = s
	return s

static func _mk(samples: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_8_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = samples
	return w

static func _sweep(f0: float, f1: float, dur: float, vol: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(maxi(1, n))
		var f := lerpf(f0, f1, t)
		phase += TAU * f / RATE
		var env := sin(PI * t)  # ataque + decay suaves
		bytes[i] = int(128 + 120 * vol * env * sin(phase))
	return _mk(bytes)

static func _arp(freqs: Array, note_dur: float, vol: float) -> AudioStreamWAV:
	var per := int(RATE * note_dur)
	var bytes := PackedByteArray()
	bytes.resize(per * freqs.size())
	var phase := 0.0
	for k in freqs.size():
		for i in per:
			var t := float(i) / float(per)
			phase += TAU * float(freqs[k]) / RATE
			var env := sin(PI * minf(1.0, t * 1.15))
			bytes[k * per + i] = int(128 + 120 * vol * env * sin(phase))
	return _mk(bytes)

static func _noise_hit(dur: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in n:
		var t := float(i) / float(maxi(1, n))
		var env := (1.0 - t) * (1.0 - t)
		bytes[i] = int(128 + 110 * 0.6 * env * (rng.randf() * 2.0 - 1.0))
	return _mk(bytes)
