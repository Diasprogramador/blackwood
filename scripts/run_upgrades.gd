class_name RunUpgrades
extends RefCounted

const OPTIONS := [
	{ id = "power", title = "Fúria da floresta", description = "+4 de ataque e magia.", limit = 12 },
	{ id = "haste", title = "Ritmo de caça", description = "+20% de velocidade do ataque básico.", limit = 6 },
	{ id = "speed", title = "Passos do vento", description = "+12% de velocidade de movimento.", limit = 4 },
	{ id = "strikes", title = "Golpe ramificado", description = "O básico atinge mais um inimigo no alcance.", limit = 3 },
	{ id = "aura", title = "Círculo de espinhos", description = "Uma aura causa dano periódico ao seu redor.\nAcumular aumenta dano e alcance.", limit = 4 },
	{ id = "vitality", title = "Casca viva", description = "+25 de vida máxima e recupera 25 HP.", limit = 8 },
]

static func offer(player: Player) -> Array:
	var pool: Array = []
	for option in OPTIONS:
		if int(player.run_upgrade_counts.get(option.id, 0)) < int(option.limit):
			pool.append(option)
	pool.shuffle()
	return pool.slice(0, mini(3, pool.size()))

static func apply(player: Player, id: String) -> bool:
	var definition: Dictionary = {}
	for option in OPTIONS:
		if option.id == id:
			definition = option
			break
	if definition.is_empty() or int(player.run_upgrade_counts.get(id, 0)) >= int(definition.limit):
		return false
	player.run_upgrade_counts[id] = int(player.run_upgrade_counts.get(id, 0)) + 1
	match id:
		"power":
			player.attack += 4
			player.magic += 4
		"haste": player.attack_speed_mult += 0.2
		"speed": player.move_speed_mult += 0.12
		"strikes": player.strike_count += 1
		"aura": player.aura_rank += 1
		"vitality":
			player.max_hp += 25
			player.heal(25)
	player.queue_redraw()
	return true
