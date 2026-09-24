class_name Elixir
extends Item

## Port de Elixir.java — restaura HP e MP ao usar.

var hp_restore: int
var mp_restore: int

func _init(type_p: Dictionary, hp_restore_p: int, mp_restore_p: int) -> void:
	super._init(type_p)
	hp_restore = hp_restore_p
	mp_restore = mp_restore_p

func use(player) -> void:
	if player == null:
		return
	var hp_before: int = player.hp
	var mp_before: int = player.mana
	player.heal(hp_restore)
	player.restore_mana(mp_restore)
	print("  >> %s usa %s! (+%d HP, +%d MP)" % [
		player.champ_name, name,
		player.hp - hp_before,
		player.mana - mp_before,
	])
