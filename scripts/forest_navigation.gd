class_name ForestNavigation
extends RefCounted

## Shared reverse breadth-first fields: one search per target tile, not per NPC.
var world: World
var fields: Dictionary = {}
const STEPS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

func _init(map: World) -> void:
	world = map

func cell(pos: Vector2) -> Vector2i:
	return Vector2i((pos / World.TILE).floor())

func center(at: Vector2i) -> Vector2:
	return (Vector2(at) + Vector2(0.5, 0.5)) * World.TILE

func clear_segment(a: Vector2, b: Vector2) -> bool:
	var count := maxi(1, int(ceil(a.distance_to(b) / 8.0)))
	for i in range(1, count + 1):
		if not MoveHelper.can_enter(world, a.lerp(b, float(i) / count)):
			return false
	return true

func direction(pos: Vector2, target: Vector2) -> Vector2:
	if pos.distance_squared_to(target) < 160.0 * 160.0 and clear_segment(pos, target):
		return pos.direction_to(target)
	var goal := cell(target)
	if world.is_solid_tile(goal.x, goal.y):
		return Vector2.ZERO
	if not fields.has(goal):
		if fields.size() >= 4:
			fields.erase(fields.keys()[0])
		fields[goal] = _build(goal)
	var costs: Dictionary = fields[goal]
	var here := cell(pos)
	var best := here
	var cost := int(costs.get(here, 999999))
	for step in STEPS:
		var next: Vector2i = here + step
		var candidate := int(costs.get(next, 999999))
		if candidate < cost:
			cost = candidate
			best = next
	if best == here:
		return pos.direction_to(target) if here == goal else Vector2.ZERO
	var waypoint := center(best)
	# Center before turning around a corner, leaving room for the entire body.
	if not clear_segment(pos, waypoint):
		waypoint = center(here)
	return pos.direction_to(waypoint)

func _build(goal: Vector2i) -> Dictionary:
	var costs := {goal: 0}
	var queue: Array[Vector2i] = [goal]
	var index := 0
	while index < queue.size():
		var at := queue[index]
		index += 1
		for step in STEPS:
			var next: Vector2i = at + step
			if costs.has(next) or world.is_solid_tile(next.x, next.y):
				continue
			costs[next] = int(costs[at]) + 1
			queue.append(next)
	return costs
