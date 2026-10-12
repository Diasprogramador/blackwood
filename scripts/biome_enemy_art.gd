class_name BiomeEnemyArt
extends RefCounted

## Eighteen silhouettes rendered into the shared four-pose atlas.
const NAMES := [
	["Carvoeiro de Casca", "Portador de Esporos", "Ancião das Raízes", "Serpe de Galhos", "Coroa de Espinhos", "Corça de Musgo"],
	["Sentinela de Escória", "Acendedor de Piras", "Colosso da Fornalha", "Asa de Cinza", "Rei das Brasas", "Cão de Carvão"],
	["Afogado de Osso", "Faroleiro do Brejo", "Relicário Submerso", "Serpe do Lodo", "Devorador do Brejo", "Rastejante de Conchas"],
]

static func title(kind: String, stage: int) -> String:
	return NAMES[clampi(stage,0,2)][maxi(0,EnemyData.ORDER.find(kind))]

static func shape(n: CanvasItem, coords: Array, color: Color) -> void:
	BiomeArt.poly(n, coords, color)

static func draw_enemy(n: CanvasItem, kind: String, stage: int, phase: float) -> void:
	var p := BiomeArt.palette(stage)
	var step := roundf(sin(phase) * 3)
	match kind:
		"MINION": _soldier(n, stage, p, step)
		"CASTER": _caster(n, stage, p, step)
		"GOLEM": _golem(n, stage, p, step)
		"JUNGLE": _beast(n, stage, p, step)
		"DRAGON": _dragon(n, stage, p, step)
		"BARON": _baron(n, stage, p, step)

static func _legs(n: CanvasItem, p: Array, step: float, wide := 1.0) -> void:
	for side in [-1,1]:
		var x: float = side * 8 * wide
		var y: float = step * side
		shape(n,[x-5,-3,x+5,-3,x+6,12+y,x+10,15+y,x-6,15+y],p[1])
		n.draw_line(Vector2(x-3,3),Vector2(x-3,11+y),p[3],2)

static func _eyes(n: CanvasItem, y: float, p: Array, wide := 5.0) -> void:
	for x in [-wide,wide]:
		n.draw_rect(Rect2(x-3,y-2,6,4),p[0])
		n.draw_rect(Rect2(x-1,y-1,3,2),p[5])

static func _soldier(n: CanvasItem, stage: int, p: Array, step: float) -> void:
	_legs(n,p,step)
	shape(n,[-15,-21,-9,-31,10,-31,16,-21,13,3,-12,3],p[2])
	shape(n,[-14,-25,-21,-20,-20,-4,-13,-6,-10,-20],p[1])
	shape(n,[13,-24,20,-19,22,-5,15,-3,10,-16],p[3])
	# A heavy asymmetrical weapon separates melee silhouettes from casters.
	n.draw_line(Vector2(21,8+step),Vector2(23,-34+step),p[4],4)
	if stage == 0:
		shape(n,[20,-34+step,25,-44+step,34,-39+step,32,-27+step,23,-25+step],p[3])
		shape(n,[-13,-33,-10,-45,1,-49,12,-43,13,-30,1,-24],p[4])
		shape(n,[-13,-40,-23,-45,-25,-55,-19,-48,-10,-46],p[1])
		shape(n,[9,-44,17,-50,16,-57,22,-53,19,-42],p[1])
		n.draw_line(Vector2(0,-46),Vector2(-2,-28),p[1],2)
	elif stage == 1:
		shape(n,[-14,-31,-15,-45,-8,-52,9,-50,16,-38,11,-27],p[3])
		shape(n,[-13,-39,0,-35,13,-39,11,-32,-10,-31],p[0])
		shape(n,[-3,-51,2,-61,6,-49],p[4])
		shape(n,[20,-32+step,23,-49+step,29,-41+step,27,-27+step],p[4])
		n.draw_polyline(PackedVector2Array([Vector2(-7,-22),Vector2(3,-13),Vector2(-4,-3)]),p[4],2)
	else:
		shape(n,[-13,-35,-10,-48,0,-53,12,-46,14,-33,7,-25,-6,-25],p[3])
		shape(n,[-12,-46,-21,-40,-22,-24,-13,-32],p[1])
		shape(n,[19,-32+step,22,-48+step,26,-48+step,28,-32+step,24,-25+step],p[5])
		for y in [-20,-13,-6]:
			n.draw_line(Vector2(-8,y),Vector2(8,y+2),p[3],2)
	_eyes(n,-37,p)
	# Layered breastplate, rivets and a split hem keep small enemies readable.
	shape(n,[-7,-23,7,-23,9,-10,0,-6,-9,-10],p[1])
	for x in [-6,6]:
		n.draw_rect(Rect2(x,-19,2,2),p[4])
	n.draw_line(Vector2(-5,-13),Vector2(4,-12),p[3],1)
	n.draw_rect(Rect2(-10,-3,22,4),p[0])
	shape(n,[-3,-5,3,-5,5,0,0,4,-4,0],p[4])

static func _caster(n: CanvasItem, stage: int, p: Array, step: float) -> void:
	shape(n,[-10,-25,9,-27,20,12,9,8,2,16,-7,9,-20,13],p[1])
	shape(n,[-5,-22,3,-25,9,8,2,11],p[3])
	n.draw_line(Vector2(22,14),Vector2(22,-44+step),p[4],3)
	shape(n,[14,-12,20,-16,25,-9,21,-3,14,-5],p[3])
	if stage == 0:
		shape(n,[-23,-32,-18,-44,-8,-49,7,-48,19,-40,24,-31],Color("bf805f"))
		shape(n,[-13,-31,-10,-17,10,-17,13,-31],p[4])
		for x in [-13,0,12]:
			n.draw_rect(Rect2(x,-40+(x%3),4,3),p[5])
		shape(n,[22,-51,29,-43,25,-32,18,-32,15,-43],p[2])
		n.draw_circle(Vector2(22,-41),4,p[5])
	elif stage == 1:
		shape(n,[-17,-25,-13,-42,0,-55,14,-42,18,-25,7,-21,-7,-21],p[2])
		shape(n,[-8,-34,0,-39,8,-33,5,-24,-5,-24],p[0])
		shape(n,[15,-43,17,-52,21,-47,24,-60,29,-48,27,-39,20,-36],p[4])
		shape(n,[-10,10,-4,-2,0,8,6,-5,12,10],p[4])
	else:
		shape(n,[-20,-24,-14,-47,0,-53,15,-44,19,-23,7,-29,-8,-28],p[2])
		shape(n,[-9,-35,0,-42,10,-34,5,-21,-5,-21],p[0])
		n.draw_line(Vector2(22,-43+step),Vector2(32,-41+step),p[3],2)
		n.draw_line(Vector2(32,-41+step),Vector2(32,-30+step),p[3],1)
		shape(n,[26,-31+step,38,-31+step,36,-17+step,28,-17+step],p[4])
		n.draw_rect(Rect2(30,-28+step,4,8),p[5])
	for side in [-1,1]:
		n.draw_line(Vector2(side*7,-16),Vector2(side*13,7),p[2],2)
		n.draw_line(Vector2(side*9,-13),Vector2(side*15,7),p[4],1)
	_eyes(n,-28,p,4)
	for y in [-10,-3,4]:
		n.draw_line(Vector2(-7,y),Vector2(-11,y+3),p[4],2)

static func _golem(n: CanvasItem, stage: int, p: Array, step: float) -> void:
	_legs(n,p,step,1.7)
	shape(n,[-25,-31,-14,-42,17,-42,26,-27,21,6,-21,6],p[2])
	for s in [-1,1]:
		shape(n,[s*23,-35,s*36,-29,s*39,-7,s*30,2,s*22,-8],p[1])
		shape(n,[s*23,-35,s*28,-45,s*37,-33,s*32,-26],p[3])
	shape(n,[-14,-37,-13,-55,0,-60,14,-52,14,-37,0,-30],p[3])
	_eyes(n,-45,p,7)
	for side in [-1,1]:
		shape(n,[side*4,-39,side*13,-37,side*12,-33,side*6,-35],p[1])
		for y in [-22,-15,-8]:
			n.draw_line(Vector2(side*27,y),Vector2(side*34,y+1),p[2],2)
	shape(n,[-11,-20,0,-29,12,-19,9,-6,-1,1,-11,-8],p[0])
	shape(n,[-5,-18,1,-23,7,-17,4,-8,-2,-6],p[4])
	if stage == 0:
		for s in [-1,1]:
			n.draw_polyline(PackedVector2Array([Vector2(s*8,-54),Vector2(s*15,-65),Vector2(s*29,-69),Vector2(s*30,-76)]),p[1],4)
			shape(n,[s*18,-43,s*25,-52,s*33,-49,s*27,-39],p[3])
	elif stage == 1:
		shape(n,[-9,-59,-8,-69,4,-68,8,-57],p[1])
		for y in [-26,-18,-10]:
			n.draw_line(Vector2(-8,y),Vector2(8,y),p[4],2)
		n.draw_polyline(PackedVector2Array([Vector2(21,-30),Vector2(15,-16),Vector2(21,-5)]),p[4],2)
	else:
		shape(n,[-7,-56,-5,-74,2,-81,8,-66,5,-55],p[4])
		for s in [-1,1]:
			shape(n,[s*27,-34,s*29,-57,s*37,-46,s*33,-27],p[4])
			n.draw_line(Vector2(s*27,-26),Vector2(s*31,-11),p[5],2)

static func _beast(n: CanvasItem, stage: int, p: Array, step: float) -> void:
	for i in 4:
		var x := -19+i*12
		var y := step if i%2 == 0 else -step
		shape(n,[x,-5,x+5,-4,x+7,12+y,x-2,13+y],p[1])
	shape(n,[-25,-10,-17,-28,11,-30,25,-20,27,-5,13,3,-15,1],p[2])
	shape(n,[10,-25,18,-40,31,-35,37,-21,32,-12,19,-13],p[3])
	n.draw_rect(Rect2(25,-29,7,4),p[0])
	n.draw_rect(Rect2(28,-28,4,2),p[5])
	if stage == 0:
		for x in [17,27]:
			n.draw_polyline(PackedVector2Array([Vector2(x,-36),Vector2(x-4,-49),Vector2(x+2,-59)]),p[4],3)
			n.draw_line(Vector2(x-3,-45),Vector2(x-12,-50),p[4],2)
		shape(n,[-21,-23,-15,-36,-7,-29,0,-39,8,-29,15,-28],p[3])
	elif stage == 1:
		shape(n,[-24,-14,-34,-22,-40,-35,-28,-27,-17,-23],p[1])
		for x in [-17,-5,7]:
			shape(n,[x,-27,x+2,-43,x+9,-31,x+8,-24],p[4])
		n.draw_line(Vector2(23,-18),Vector2(34,-19),p[5],3)
	else:
		for s in [-1,1]:
			shape(n,[s*20,-8,s*36,-17,s*45,-10,s*44,0,s*38,-6,s*26,6],p[3])
		shape(n,[-14,-26,-9,-42,0,-47,16,-35,18,-23,2,-17],p[3])
		n.draw_polyline(PackedVector2Array([Vector2(-5,-39),Vector2(7,-32),Vector2(3,-25)]),p[4],2)

static func _dragon(n: CanvasItem, stage: int, p: Array, step: float) -> void:
	for s in [-1,1]:
		shape(n,[s*8,-22,s*24,-59-step,s*57,-39-step,s*47,-19,s*34,-29,s*26,-11],p[1])
		n.draw_polyline(PackedVector2Array([Vector2(s*10,-23),Vector2(s*24,-59-step),Vector2(s*47,-22)]),p[4],2)
		if stage == 2:
			for i in 3:
				n.draw_line(Vector2(s*(27+i*7),-37),Vector2(s*(30+i*7),-12+i*3),p[4],2)
	shape(n,[-11,-34,10,-35,18,-12,12,9,-10,12,-20,2,-27,13,-34,6,-16,-5],p[2])
	shape(n,[-10,-35,-4,-52,14,-57,26,-43,20,-30,4,-27],p[3])
	shape(n,[5,-51,4,-66,12,-56,20,-62,20,-50],p[4])
	n.draw_rect(Rect2(11,-44,8,4),p[0])
	n.draw_rect(Rect2(14,-43,4,2),p[5])
	for side in [-1,1]:
		shape(n,[side*10,0,side*16,8,side*19,16,side*6,17],p[1])
		for claw in 3:
			n.draw_line(Vector2(side*(8+claw*4),13),Vector2(side*(9+claw*4),18),p[5],2)
	for y in [-23,-14,-5]:
		n.draw_line(Vector2(-6,y),Vector2(8,y-2),p[4],3)
	if stage == 0:
		shape(n,[-5,-58,-17,-63,-24,-76,-15,-68,0,-65],p[1])
	elif stage == 1:
		shape(n,[22,-35,34,-32,42,-21,30,-26,25,-23],p[4])
	else:
		shape(n,[-5,-34,-18,-45,-27,-41,-19,-34,-26,-29,-12,-27],p[4])

static func _baron(n: CanvasItem, stage: int, p: Array, step: float) -> void:
	for s in [-1,1]:
		shape(n,[s*14,-11,s*35,-28+step*s,s*50,-18+step*s,s*54,4+step*s,s*46,15+step*s,s*40,1+step*s,s*33,-3,s*23,14],p[1])
		shape(n,[s*31,-24+step*s,s*44,-38+step*s,s*48,-27+step*s,s*53,-30+step*s,s*48,-16+step*s],p[3])
	shape(n,[-28,-26,-18,-49,12,-54,31,-29,28,9,13,21,-14,21,-31,7],p[2])
	shape(n,[-21,-34,-17,-61,0,-70,22,-57,22,-33,9,-21,-9,-21],p[3])
	for s in [-1,1]:
		shape(n,[s*13,-59,s*27,-74,s*35,-72,s*30,-55,s*19,-44],p[4])
	_eyes(n,-43,p,10)
	shape(n,[-12,-29,0,-34,14,-28,9,-13,0,-7,-11,-15],p[0])
	for x in [-7,0,7]:
		shape(n,[x-2,-28,x+2,-28,x,-18],p[5])
	if stage == 0:
		for x in [-18,0,18]:
			shape(n,[x-5,-59,x-10,-83,x,-74,x+7,-86,x+6,-62],p[1])
	elif stage == 1:
		for x in [-13,0,13]:
			shape(n,[x-5,4,x-3,-9,x+3,-4,x+7,-15,x+7,6],p[4])
	else:
		for x in [-19,19]:
			n.draw_line(Vector2(x,-55),Vector2(x*2,-69+step),p[4],2)
			n.draw_circle(Vector2(x*2,-69+step),4,p[5])
		for y in [-7,0,7]:
			n.draw_line(Vector2(-16,y),Vector2(17,y+2),p[3],2)
