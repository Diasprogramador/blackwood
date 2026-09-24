class_name Skill
extends RefCounted

## Port de Skill.java (interface) — contrato comum de todas as habilidades.

var name: String = ""
var description: String = ""
var mana_cost: int = 0
var cooldown: int = 0
var current_cooldown: int = 0
var level: int = 1

func get_name() -> String:
	return name

func get_description() -> String:
	return description

func get_mana_cost() -> int:
	return mana_cost

func get_cooldown() -> int:
	return cooldown

func get_current_cooldown() -> int:
	return current_cooldown

func get_level() -> int:
	return level

func can_use(user) -> bool:
	if user == null:
		return false
	return user.mana >= mana_cost and current_cooldown == 0

## Sobrescrito pelas subclasses.
func execute(_user, _target) -> void:
	pass

func reduce_cooldown() -> void:
	if current_cooldown > 0:
		current_cooldown -= 1

func reset_cooldown() -> void:
	current_cooldown = 0

func level_up() -> void:
	level += 1
