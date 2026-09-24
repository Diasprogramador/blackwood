class_name GameCamera
extends RefCounted

## Port de Camera.java — follow com interpolação + center_on.
## No jogo real main.gd usa Camera2D com position_smoothing_enabled
## (mesmo efeito, acelerado pela GPU); esta classe serve para lógica
## headless e como referência da matemática original (lerp 0.08).

const LERP := 0.08

var screen_w := 960
var screen_h := 640
var x := 0.0
var y := 0.0

func _init(p_screen_w: int = 960, p_screen_h: int = 640) -> void:
	screen_w = p_screen_w
	screen_h = p_screen_h

func follow(target_x: float, target_y: float) -> void:
	var desired_x := target_x - screen_w / 2.0
	var desired_y := target_y - screen_h / 2.0
	x += (desired_x - x) * LERP
	y += (desired_y - y) * LERP

func center_on(target_x: float, target_y: float) -> void:
	x = target_x - screen_w / 2.0
	y = target_y - screen_h / 2.0

func get_position() -> Vector2:
	return Vector2(x, y)
