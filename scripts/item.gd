class_name Item
extends RefCounted

## Port de Item.java — classe abstrata base de todos os itens.

var type: Dictionary
var name: String
var description: String
var price: int

func _init(type_p: Dictionary) -> void:
	type = type_p
	name = type_p.get("name", "")
	description = type_p.get("description", "")
	price = int(type_p.get("price", 0))

## Sobrescrito pelas subclasses.
func use(_player) -> void:
	pass

func get_type() -> Dictionary:
	return type

func _to_string() -> String:
	return "%s - %s (Gold: %d)" % [name, description, price]
