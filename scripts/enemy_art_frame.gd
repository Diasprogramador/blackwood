class_name EnemyArtFrame
extends Node2D

var type_key := "MINION"
var color := Color.WHITE
var phase := 0.0

func _draw() -> void:
	EnemyArt.draw_enemy(self, type_key, color, false, phase, true)
