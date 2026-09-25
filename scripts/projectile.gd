class_name Projectile
extends Node2D

## Projétil inimigo (casters e dragão): voa reto com rabinho, morre na
## parede e acerta o jogador. Ticado pelo main (só anda em PLAY).

signal hit_player(proj: Projectile)

var vel := Vector2.ZERO
var damage := 5
var radius := 8.0
var life := 2.5
var col := Color(1, 0.5, 0.2)
var world: World
var dead := false
var tick := 0.0
var trail: Array = []

var _player: Player

func setup(from: Vector2, dir: Vector2, speed: float, dmg: int,
		color: Color, w: World, target: Player) -> void:
	position = from
	vel = dir.normalized() * speed
	damage = dmg
	radius = 8.0 if dmg < 30 else 11.0
	col = color
	world = w
	_player = target
	z_index = 6

func shot_tick(d: float) -> void:
	if dead:
		return
	tick += d
	life -= d
	position += vel * d
	trail.append(position)
	while trail.size() > 8:
		trail.pop_front()
	if life <= 0.0:
		_fizzle()
		return
	if world != null and world.is_solid_at(position.x, position.y):
		_fizzle()
		return
	if _player != null and is_instance_valid(_player) and _player.is_alive():
		if position.distance_to(_player.position) < radius + 10.0:
			dead = true
			hit_player.emit(self)
			queue_free()

func _fizzle() -> void:
	dead = true
	queue_free()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# rabinho
	var n := trail.size()
	for i in n:
		var p: Vector2 = trail[i] - position
		var k := float(i + 1) / float(maxi(1, n))
		draw_circle(p, radius * 0.45 * k, Color(col, 0.25 * k))
	# brilho + núcleo + faísca
	var pulse := 0.8 + 0.2 * sin(tick * 18.0)
	draw_circle(Vector2.ZERO, radius * 1.5 * pulse, Color(col, 0.25))
	draw_circle(Vector2.ZERO, radius * pulse, col)
	draw_circle(Vector2(-radius * 0.25, -radius * 0.25), radius * 0.35, Color(1, 1, 1, 0.9))
