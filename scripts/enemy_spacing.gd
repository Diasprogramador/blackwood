class_name EnemySpacing
extends RefCounted

const CELL := 32.0
const DISTANCE := 24.0

## Only inspect neighboring cells. Each pair is processed once, retaining
## the existing wall checks without quadratic comparisons across the map.
static func separate(bodies: Array, world: World) -> void:
	var grid := {}
	for i in bodies.size():
		var cell := Vector2i(floori(bodies[i].position.x / CELL), floori(bodies[i].position.y / CELL))
		if not grid.has(cell):
			grid[cell] = []
		grid[cell].append(i)
	for i in bodies.size():
		var a = bodies[i]
		var cell := Vector2i(floori(a.position.x / CELL), floori(a.position.y / CELL))
		for y in range(-1, 2):
			for x in range(-1, 2):
				for j in grid.get(cell + Vector2i(x, y), []):
					if j <= i:
						continue
					var b = bodies[j]
					var off: Vector2 = b.position - a.position
					var squared := off.length_squared()
					if squared >= DISTANCE * DISTANCE:
						continue
					var distance := sqrt(squared)
					var direction := off / distance if distance > 0.01 else Vector2.RIGHT
					var push := direction * (DISTANCE - distance) * 0.35
					var next_a: Vector2 = a.position - push
					var next_b: Vector2 = b.position + push
					if MoveHelper.can_enter(world, next_a):
						a.position = next_a
					if MoveHelper.can_enter(world, next_b):
						b.position = next_b
