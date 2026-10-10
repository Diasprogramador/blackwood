class_name StrikeTrail
extends Node2D

## Short, bounded attack cues. Damage remains authoritative and immediate.
static var live := 0
var destination := Vector2.ZERO
var role := "tank"
var age := 0.0
var duration := 0.24

func _init(origin := Vector2.ZERO, target := Vector2.ZERO, family := "tank") -> void:
	position = origin
	destination = target - origin
	role = family
	z_index = 15

func _ready() -> void:
	live += 1

func _exit_tree() -> void:
	live -= 1

func _process(delta: float) -> void:
	age += delta
	if age >= duration:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var t := clampf(age / duration, 0, 1)
	var palette: Array = AttackEffect.PAL[AttackEffect.role_index(role)]
	var color := Color(palette[0], 1.0 - t)
	var light := Color(palette[2], 1.0 - t)
	var dir := destination.normalized()
	if role in ["tank", "assassin"]:
		var r := minf(64.0, destination.length())
		var a := dir.angle() - 1.2 + t * 1.8
		draw_arc(Vector2.ZERO, r, a, a + 1.8, 12, Color(palette[1], 1 - t), 12)
		draw_arc(Vector2.ZERO, r, a, a + 1.8, 12, color, 7)
		draw_arc(Vector2.ZERO, r + 3, a + 0.4, a + 1.8, 10, light, 2)
	else:
		var tip := destination * minf(1.0, t * 2.5)
		var tail := destination * maxf(0, t * 2.5 - 0.5)
		draw_line(tail, tip, color, 6)
		draw_line(tail, tip, light, 2)
		if role == "marksman":
			draw_colored_polygon(PackedVector2Array([tip + dir * 9, tip - dir * 7 + dir.orthogonal() * 6, tip - dir * 7 - dir.orthogonal() * 6]), light)
		else:
			for i in 4:
				var p := tip + Vector2.from_angle(i * TAU / 4 + t * 4) * 8
				draw_rect(Rect2(p - Vector2.ONE * 2, Vector2.ONE * 4), light)
