class_name Equipment
extends Item

## Port de Equipment.java — equipamento que dá bônus de stat ao equipar.

var stat_type: String
var bonus_value: int

func _init(type_p: Dictionary, stat_type_p: String, bonus_value_p: int) -> void:
	super._init(type_p)
	stat_type = stat_type_p
	bonus_value = bonus_value_p

## No Java o equip só imprimia; aqui o Player.aplicar_equip aplicaria o bônus.
func use(player) -> void:
	if player == null:
		return
	print("  >> %s equipa %s! (+%d %s)" % [
		player.champ_name, name, bonus_value, stat_type,
	])

func get_stat_type() -> String:
	return stat_type

func get_bonus_value() -> int:
	return bonus_value
