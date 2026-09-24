class_name MagicSkill
extends Skill

## Port de MagicSkill.java — dano mágico escalando com MAG.

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

func execute(user, target) -> void:
	if not can_use(user):
		print("  >> Habilidade indisponivel!")
		return
	user.mana -= mana_cost

	# Dano escala com MAG do usuario
	var raw_damage: int = user.magic + base_damage + (level * 6)
	var final_damage: int = target.take_damage(raw_damage)

	current_cooldown = cooldown

	print("  >> %s conjura %s em %s! (%d de dano magico)" % [
		_target_name(user), name, _target_name(target), final_damage,
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
	base_damage += 10
	mana_cost = int(mana_cost * 1.15)
	print("  >> %s evoluiu para nivel %d! (+10 dano magico)" % [name, level])
