class_name Character
extends RefCounted

## Port de Character.java (classe abstrata) — stats, dano com variância,
## redução por defesa, cura/mana, EXP e barras de texto.
## NOTA: Player e Enemy são Node2D (precisam do _draw) e GDScript tem
## herança única — por isso ambos reimplementam estas fórmulas inline
## (take_damage/calc_damage/heal/restore_mana idênticas às daqui).
## Use esta classe como referência do contrato ou em simulações headless.

var name := ""
var level := 1
var max_hp := 100
var hp := 100
var max_mana := 100
var mana := 100
var attack := 10
var defense := 5
var magic := 5
var xp := 0

func _init(p_name: String = "", p_level: int = 1, p_max_hp: int = 100,
		p_attack: int = 10, p_defense: int = 5, p_magic: int = 5,
		p_max_mana: int = 100) -> void:
	name = p_name
	level = p_level
	max_hp = p_max_hp
	hp = max_hp
	attack = p_attack
	defense = p_defense
	magic = p_magic
	max_mana = p_max_mana
	mana = max_mana
	xp = 0

## Dano físico com variância de ±20% (como no Java: 0.8 + rand*0.4).
func calculate_damage() -> int:
	return int(attack * randf_range(0.8, 1.2))

## Reduz o dano bruto pela defesa. Retorna o dano final aplicado.
func take_damage(raw_damage: int) -> int:
	var reduction := defense / float(defense + 100)
	var final_damage := maxi(1, int(raw_damage * (1.0 - reduction)))
	hp = maxi(0, hp - final_damage)
	return final_damage

func is_alive() -> bool:
	return hp > 0

func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)

func restore_mana(amount: int) -> void:
	mana = mini(max_mana, mana + amount)

## ABSTRATO no Java — cada subclasse define o que acontece ao subir de nível.
## (Player._on_level_up e a ausência em Enemy espelham o onLevelUp.)
func _on_level_up() -> void:
	pass

func gain_exp(amount: int) -> void:
	xp += amount

func exp_to_next() -> int:
	return level * 100

func set_hp(value: int) -> void:
	hp = clampi(value, 0, max_hp)

func set_mana(value: int) -> void:
	mana = clampi(value, 0, max_mana)

func display_status() -> void:
	print("  %-15s Lv.%-3d | HP: %s %d/%d | MP: %s %d/%d" % [
		name, level, generate_bar(hp, max_hp, 20), hp, max_hp,
		generate_bar(mana, max_mana, 20), mana, max_mana,
	])

static func generate_bar(current: int, maximum: int, length: int) -> String:
	var filled := int(current / float(maxi(1, maximum)) * length)
	var bar := "["
	for i in length:
		bar += "#" if i < filled else "-"
	bar += "]"
	return bar

func _to_string() -> String:
	return "%s (Lv.%d) - HP:%d/%d ATK:%d DEF:%d MAG:%d MP:%d/%d" % [
		name, level, hp, max_hp, attack, defense, magic, mana, max_mana,
	]
