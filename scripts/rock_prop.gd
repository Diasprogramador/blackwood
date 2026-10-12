class_name RockProp
extends Node2D

## Pedra realista: facetas com gradiente, fendas, musgo e grama na base.
## Posição = centro da pedra (pé no chão levemente abaixo).

var variant := 0
var stage_idx := 0
var cached_texture: Texture2D

func _ready() -> void:
	queue_redraw()

## Área coberta pela pedra, em coord. local do nó (ver TreeProp.occluder_rect).
func occluder_rect() -> Rect2:
	return Rect2(-20, -42, 40, 52)

func _draw() -> void:
	if cached_texture != null:
		draw_texture(cached_texture, Vector2(-48, -80))
		return
	BiomeArt.rock(self, stage_idx, variant)
