class_name CrystalProp
extends Node2D

## Cristais afogados: fragmentos de jade com brilho espectral.
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
	var glow := Color(0.62, 0.89, 0.81, 0.12 + 0.09 * pulse)

	A.fill_ellipse(self, 0, 4, 12, 4, Color(0, 0, 0, 0.3))
	# halo largo + núcleo: o brilho só aparece no degrau entre os dois.
	A.fill_ellipse(self, 0, -4, 19, 13, Color(0.48, 0.73, 0.69, 0.07 + 0.06 * pulse))
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
			A.mix(Color("9fe2cf"), Color.WHITE, 0.25),
			A.mix(Color("505273"), Color.BLACK, 0.3))
		A.stroke(self, shard, Color(0.87, 0.96, 0.91, 0.7), 1.0)
	A.fill_ellipse(self, -2, -6, 2, 1.2, Color(1, 1, 1, 0.5 + 0.3 * pulse))
