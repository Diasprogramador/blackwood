class_name CrystalProp
extends Node2D

## Cristal do Vazio: shards violetas com brilho pulsante.
## Decorativo (não bloqueia). Posição = base do prop.

var variant := 0
var _t := 0.0

func _ready() -> void:
	queue_redraw()

## O pulso leva ~2s: repintar a 12Hz mantém o brilho vivo e corta o custo
## dezenas de cristais que hoje repintavam a 60Hz cada.
func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _t < 0.083:
		return
	_t = 0.0
	queue_redraw()

func _draw() -> void:
	var A := ArtUtil
	var v := variant % 3
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.003 + variant * 1.7)
	var glow := Color(0.65, 0.35, 1, 0.16 + 0.12 * pulse)

	A.fill_ellipse(self, 0, 4, 12, 4, Color(0, 0, 0, 0.3))
	# halo largo + núcleo: o brilho só aparece no degrau entre os dois.
	A.fill_ellipse(self, 0, -4, 19, 13, Color(0.6, 0.3, 1, 0.12 + 0.10 * pulse))
	A.fill_ellipse(self, 0, -4, 11, 9, glow)
	var hs := [13.0, 10.0, 7.0]
	for i in 3:
		var h: float = hs[(v + i) % 3]
		var ox := (i - 1) * 6.0
		var lean := (v - 1) * 2.0 + (i - 1) * 1.5
		var shard := PackedVector2Array([
			Vector2(ox - 3.5, 4), Vector2(ox + 3.5, 4),
			Vector2(ox + lean, -h),
		])
		A.shade_poly(self, shard,
			A.mix(Color(0.75, 0.55, 1), Color.WHITE, 0.25),
			A.mix(Color(0.45, 0.2, 0.8), Color.BLACK, 0.3))
		A.stroke(self, shard, Color(0.9, 0.8, 1, 0.7), 1.0)
	A.fill_ellipse(self, -2, -6, 2, 1.2, Color(1, 1, 1, 0.5 + 0.3 * pulse))
