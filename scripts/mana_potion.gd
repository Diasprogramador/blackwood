class_name ManaPotion
extends Item

## Port de ManaPotion.java — restaura MP ao usar.

var mana_amount: int

func _init(type_p: Dictionary, mana_amount_p: int) -> void:
	super._init(type_p)
	mana_amount = mana_amount_p

func use(player) -> void:
	if player == null:
		return
	var before: int = player.mana
	player.restore_mana(mana_amount)
	var restored: int = player.mana - before
	print("  >> %s usa %s e recupera %d MP!" % [player.champ_name, name, restored])
