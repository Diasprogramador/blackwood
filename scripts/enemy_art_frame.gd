class_name EnemyArtFrame
extends Node2D

var type_key := "MINION"
var phase := 0.0
var stage_idx := 0

func _draw() -> void:
	BiomeEnemyArt.draw_enemy(self, type_key, stage_idx, phase)
