class_name SpriteFx
extends Node2D

## Efeito texturizado de um tiro só: nasce, cresce, sobe um pouco e some.

var _t := 0.0
var _dur := 0.3
var _spr: Sprite2D = null
var _grow := 0.7
var _rise := -16.0
var _base := 1.0
var _flip := 1.0

static func spawn(parent: Node, rel: String, pos: Vector2, height: float,
		dur: float = 0.3, flip: float = 1.0, grow: float = 0.7) -> void:
	var t := SpriteKit.tex(rel)
	if t == null or parent == null or not is_instance_valid(parent):
		return
	var fx := SpriteFx.new()
	fx._dur = maxf(0.05, dur)
	fx._grow = grow
	fx._flip = signf(flip) if flip != 0.0 else 1.0
	fx.z_index = 25
	var spr := Sprite2D.new()
	spr.centered = true
	fx.add_child(spr)
	fx._spr = spr
	parent.add_child(fx)
	fx.position = pos
	fx._base = SpriteKit.fit_center(spr, rel, height)

func _process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / _dur, 0.0, 1.0)
	if _spr:
		var s: float = _base * (1.0 + _grow * k)
		_spr.scale = Vector2(_flip * s, s)
		_spr.position = Vector2(0, _rise * k)
		_spr.modulate = Color(1, 1, 1, 1.0 - k)
	if k >= 1.0:
		queue_free()
