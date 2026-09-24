class_name InputHandler
extends RefCounted

## Port de InputHandler.java — estado das teclas de movimento (WASD/setas) + E.
## player.gd lê Input.is_physical_key_pressed() direto no _physics_process;
## esta classe espelha a API do Java para lógica headless e testes.
## Dica: chame poll() uma vez por frame para sincronizar com o Input real.

var up := false
var down := false
var left := false
var right := false
var channel := false  # tecla E

func press(keycode: int) -> void:
	match keycode:
		KEY_W, KEY_UP:
			up = true
		KEY_S, KEY_DOWN:
			down = true
		KEY_A, KEY_LEFT:
			left = true
		KEY_D, KEY_RIGHT:
			right = true
		KEY_E:
			channel = true

func release(keycode: int) -> void:
	match keycode:
		KEY_W, KEY_UP:
			up = false
		KEY_S, KEY_DOWN:
			down = false
		KEY_A, KEY_LEFT:
			left = false
		KEY_D, KEY_RIGHT:
			right = false
		KEY_E:
			channel = false

## Lê o estado real do teclado (equivale ao KeyListener do Java).
func poll() -> void:
	up = Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	down = Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	left = Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	right = Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	channel = Input.is_physical_key_pressed(KEY_E)

func direction() -> Vector2:
	var dir := Vector2.ZERO
	if up:
		dir.y -= 1.0
	if down:
		dir.y += 1.0
	if left:
		dir.x -= 1.0
	if right:
		dir.x += 1.0
	return dir.normalized() if dir != Vector2.ZERO else dir

func is_up() -> bool:
	return up

func is_down() -> bool:
	return down

func is_left() -> bool:
	return left

func is_right() -> bool:
	return right

func is_channel() -> bool:
	return channel
