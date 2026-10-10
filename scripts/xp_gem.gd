class_name XpGem
extends Node2D

signal collected(amount: int)
var amount := 0
var target: Player

func _ready() -> void:
	add_to_group("xp_gems")
	z_index = World.depth_z(position.y)

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target) or not target.is_alive():
		return
	var distance := position.distance_to(target.position)
	if distance < 130.0:
		position = position.move_toward(target.position, (220.0 + (130.0 - distance) * 4.0) * delta)
		z_index = World.depth_z(position.y)
	if position.distance_squared_to(target.position) <= 14.0 * 14.0:
		set_physics_process(false)
		collected.emit(amount)
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7, Color(0.25, 0.75, 1, 0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -5), Vector2(4, 0), Vector2(0, 5), Vector2(-4, 0)]), Color(0.4, 0.9, 1))
	draw_line(Vector2(0, -3), Vector2(2, 0), Color.WHITE, 1)
