class_name DamageSkill
extends Skill

## Port de DamageSkill.java — dano físico escalando com ATK.

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

	# Dano escala com ATK do usuario + baseDamage da skill
	var raw_damage: int = user.attack + base_damage + (level * 5)
	var final_damage: int = target.take_damage(raw_damage)

	current_cooldown = cooldown

	print("  >> %s usa %s em %s! (%d de dano)" % [
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
	base_damage += 8
	mana_cost = int(mana_cost * 1.1)
	print("  >> %s evoluiu para nivel %d! (+8 dano base)" % [name, level])
