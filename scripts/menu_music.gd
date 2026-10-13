class_name MenuMusic
extends AudioStreamPlayer

## One persistent loop shared by login, profile and preparation screens.
## Fades out for a run; it never stacks when navigating back and forth.
var gain := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bus = "Music"
	var track := load("res://assets/audio/bosque_theme.wav").duplicate() as AudioStreamWAV
	track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	track.loop_begin = 0
	track.loop_end = roundi(track.get_length() * track.mix_rate) # Also valid for imported QOA.
	stream = track
	volume_db = -80.0

func _process(delta: float) -> void:
	var main = get_parent()
	var in_menu: bool = main.state in [main.State.MENU, main.State.PROFILE,
		main.State.SETTINGS, main.State.CHAMP, main.State.STAGE, main.State.MENUSHOP, main.State.MULTI]
	if in_menu and not playing: play()
	gain = move_toward(gain, 1.0 if in_menu else 0.0, delta * 0.65)
	volume_db = linear_to_db(maxf(0.0001, gain)) - 12.0
	if not in_menu and gain <= 0.0 and playing: stop()
