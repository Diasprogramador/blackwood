class_name AreaDamageSkill
extends Skill

## Port de AreaDamageSkill.java — dano em área a vários alvos.

var base_damage: int = 0

func _init(p_name: String, p_description: String, p_mana_cost: int,
		p_base_damage: int, p_cooldown: int) -> void:
	name = p_name
	description = p_description
	mana_cost = p_mana_cost
	base_damage = p_base_damage
	cooldown = p_cooldown
	current_cooldown = 0
	level = 1

func execute(_user, _target) -> void:
	print("  >> Use execute_area(user, targets) para area!")

## Sobrecarga: atinge múltiplos alvos (como no Java).
func execute_area(user, targets: Array) -> void:
	if not can_use(user):
		print("  >> Habilidade indisponivel!")
		return
	user.mana -= mana_cost

	var raw_damage: int = user.magic + base_damage + (level * 7)

	print("  >> %s conjura %s atingindo %d alvos!" % [
		_target_name(user), name, targets.size(),
	])

	for target in targets:
		if target.is_alive():
			var final_damage: int = target.take_damage(raw_damage)
			var tname := _target_name(target)
			print("     -> %s recebe %d de dano!" % [tname, final_damage])

	current_cooldown = cooldown

func _target_name(c) -> String:
	if c == null:
		return "?"
	if "champ_name" in c:
		return c.champ_name
	if "type_name" in c:
		return c.type_name
	return str(c)

func level_up() -> void:
	super.level_up()
	base_damage += 12
	mana_cost = int(mana_cost * 1.2)
	print("  >> %s evoluiu para nivel %d! (+12 dano base)" % [name, level])
