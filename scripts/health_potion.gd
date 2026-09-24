class_name HealthPotion
extends Item

## Port de HealthPotion.java — restaura HP ao usar.

var heal_amount: int

func _init(type_p: Dictionary, heal_amount_p: int) -> void:
	super._init(type_p)
	heal_amount = heal_amount_p

func use(player) -> void:
	if player == null:
		return
	var before: int = player.hp
	player.heal(heal_amount)
	var healed: int = player.hp - before
	print("  >> %s usa %s e recupera %d HP!" % [player.champ_name, name, healed])
