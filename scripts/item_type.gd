class_name ItemType
extends Object

## Port de ItemType.java — metadados de cada tipo de item da loja.

const HEALTH_POTION := {
	key = "HEALTH_POTION",
	name = "Poção de Vida",
	description = "Restaura 100 HP",
	price = 50,
}
const MANA_POTION := {
	key = "MANA_POTION",
	name = "Poção de Mana",
	description = "Restaura 80 MP",
	price = 40,
}
const ATTACK_BOOTS := {
	key = "ATTACK_BOOTS",
	name = "Botas de Ataque",
	description = "+5 ATK",
	price = 120,
}
const DEFENSE_ARMOR := {
	key = "DEFENSE_ARMOR",
	name = "Armadura Reforçada",
	description = "+8 DEF",
	price = 150,
}
const MAGIC_ROBE := {
	key = "MAGIC_ROBE",
	name = "Talisã Arcano",
	description = "+7 MAG",
	price = 130,
}
const ELIXIR := {
	key = "ELIXIR",
	name = "Elixir Supremo",
	description = "Restaura 200 HP e 150 MP",
	price = 200,
}

const ALL := [
	HEALTH_POTION, MANA_POTION, ATTACK_BOOTS,
	DEFENSE_ARMOR, MAGIC_ROBE, ELIXIR,
]

static func by_key(key: String) -> Dictionary:
	for t in ALL:
		if t.key == key:
			return t
	return {}
