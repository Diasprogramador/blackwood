class_name EnemyData
extends Object

## Port de EnemyType.java — stats base e recompensas.

const TYPES := {
	"MINION": {
		name = "Minion", hp = 60, atk = 10, def = 4, mag = 2, mana = 30,
		gold = 12, exp = 12, color = Color(0.78, 0.24, 0.24),
	},
	"CASTER": {
		name = "Caster Minion", hp = 45, atk = 8, def = 3, mag = 10, mana = 40,
		gold = 14, exp = 14, color = Color(0.78, 0.55, 0.16),
	},
	"GOLEM": {
		name = "Golem", hp = 130, atk = 14, def = 10, mag = 3, mana = 20,
		gold = 22, exp = 20, color = Color(0.51, 0.51, 0.51),
	},
	"DRAGON": {
		name = "Dragão", hp = 230, atk = 26, def = 14, mag = 15, mana = 80,
		gold = 60, exp = 45, color = Color(0.71, 0.16, 0.16),
	},
	"BARON": {
		name = "Barão Nashor", hp = 420, atk = 38, def = 22, mag = 25, mana = 120,
		gold = 120, exp = 85, color = Color(0.39, 0.16, 0.55),
	},
	"JUNGLE": {
		name = "Jungle Camp", hp = 85, atk = 14, def = 6, mag = 4, mana = 25,
		gold = 16, exp = 14, color = Color(0.24, 0.63, 0.24),
	},
}

const ORDER := ["MINION", "CASTER", "GOLEM", "DRAGON", "BARON", "JUNGLE"]

## Nível mínimo para cada tipo aparecer (evita Barão na onda 1).
const UNLOCK := {
	"MINION": 1, "CASTER": 1, "JUNGLE": 1,
	"GOLEM": 3, "DRAGON": 5, "BARON": 8,
}

static func pool_for_level(lvl: int) -> Array:
	var pool: Array = []
	for key in ORDER:
		if lvl >= int(UNLOCK.get(key, 1)):
			pool.append(key)
	if pool.is_empty():
		pool.append("MINION")
	return pool

static func random_type(lvl: int) -> String:
	var pool := pool_for_level(lvl)
	return str(pool[randi() % pool.size()])
