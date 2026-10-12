class_name TreeProp
extends Node2D

## Árvore realista: tronco com casca em gradiente, raízes, copa em camadas
## com luz/sombra e sombra no chão. Posição = base do tronco.

var variant := 0
var stage_idx := 0
var _scale := 1.0
var cached_texture: Texture2D

func _ready() -> void:
	_scale = 0.85 + hash(position) % 40 / 100.0
	queue_redraw()

## Área coberta pela árvore (copa + tronco), em coord. local do nó.
## A Main usa isto para saber quando o personagem está escondido atrás.
func occluder_rect() -> Rect2:
	var s := _scale
	return Rect2(-32.0 * s, -78.0 * s, 64.0 * s, 86.0 * s)

func _draw() -> void:
	if cached_texture != null:
		draw_texture_rect(cached_texture, Rect2(-48 * _scale, -80 * _scale, 96 * _scale, 96 * _scale), false)
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * _scale)
	BiomeArt.tree(self, stage_idx, variant)
