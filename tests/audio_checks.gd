extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var music: MenuMusic = game.get_node("MenuMusic")
	await create_timer(0.2).timeout
	assert(music.playing and music.bus == "Music")
	assert(music.stream.get_length() > 45 and music.stream.get_length() < 47)
	assert(absf(float(music.stream.loop_end)/music.stream.mix_rate-music.stream.get_length()) < 0.01)
	game.state = game.State.PROFILE
	var position := music.get_playback_position()
	await create_timer(0.2).timeout
	assert(music.get_playback_position() >= position, "Login navigation must not restart music")
	Sfx.apply_volumes({"master":80,"music":0,"sfx":90})
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	assert(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")))
	Sfx.apply_volumes({"master":80,"music":70,"sfx":0})
	assert(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")))
	for id in ["click","coin","hit","hurt","tank","assassin","mage","marksman","support","dash","shoot","potion","error","ultimate","levelup","buy","victory","defeat"]:
		var clip := Sfx._sample(id)
		assert(clip != null and clip.get_length() > 0.04)
		Sfx.play(game,id)
	assert(Sfx._voices <= 12)
	await create_timer(2.2).timeout
	assert(Sfx._voices == 0, "Finished effects must release audio players")
	game.state = game.State.PLAY
	await create_timer(1.8).timeout
	assert(not music.playing and music.gain == 0, "Menu score must fade out for gameplay")
	game.state = game.State.PAUSE
	paused = true
	await create_timer(0.1).timeout
	assert(not music.playing)
	paused = false
	game.state = game.State.MENU
	await create_timer(0.2).timeout
	assert(music.playing)
	game.queue_free()
	await process_frame
	assert(Sfx._voices == 0)
	await create_timer(0.2).timeout
	print("AUDIO_CHECKS passed: loop length, login continuity, independent mute, 18 effects, voice cap, cleanup, gameplay fade and menu return")
	quit()
