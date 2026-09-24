class_name HealSkill
extends Skill

## Port de HealSkill.java — cura escalando com MAG.

var base_heal: int = 0

func _init(p_name: String, p_description: String, p_mana_cost: int,
		p_base_heal: int, p_cooldown: int) -> void:
	name = p_name
	description = p_description
	mana_cost = p_mana_cost
	base_heal = p_base_heal
	cooldown = p_cooldown
	current_cooldown = 0
	level = 1

func execute(user, target) -> void:
	if not can_use(user):
		print("  >> Habilidade indisponivel!")
		return
	user.mana -= mana_cost

	# Cura escala com MAG + baseHeal
	var heal_amount: int = user.magic + base_heal + (level * 4)
	target.heal(heal_amount)

	current_cooldown = cooldown

	print("  >> %s usa %s em %s! (+%d HP)" % [
		_target_name(user), name, _target_name(target), heal_amount,
	])

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
	base_heal += 8
	mana_cost = int(mana_cost * 1.1)
	print("  >> %s evoluiu para nivel %d! (+8 cura base)" % [name, level])
