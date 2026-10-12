class_name BiomeArt
extends RefCounted

## One palette and shape language per region. All solid art stays on solid tiles.
const PALETTES := [
	[Color("132f2b"), Color("286047"), Color("4b8054"), Color("92af69"), Color("c3a270"), Color("b8efd1")],
	[Color("241f29"), Color("46343a"), Color("74504a"), Color("b67d60"), Color("ff994b"), Color("ffdc8b")],
	[Color("191e38"), Color("313456"), Color("505273"), Color("8992ad"), Color("9fe2cf"), Color("ded4ee")],
]

static func palette(stage: int) -> Array:
	return PALETTES[clampi(stage, 0, 2)]

static func poly(n: CanvasItem, coords: Array, color: Color, outline := true) -> void:
	var pts := PackedVector2Array()
	for i in range(0, coords.size(), 2):
		pts.append(Vector2(coords[i], coords[i + 1]))
	var bounds := Rect2(pts[0],Vector2.ZERO)
	for point in pts:
		bounds = bounds.expand(point)
	var colors := PackedColorArray()
	for point in pts:
		var light := clampf((point.y-bounds.position.y)/maxf(1,bounds.size.y)*0.75 + (point.x-bounds.position.x)/maxf(1,bounds.size.x)*0.25,0,1)
		colors.append(color.lightened(0.22).lerp(color.darkened(0.34),light))
	n.draw_polygon(pts, colors)
	if outline:
		# Bake material grain into the atlas. No random state or per-frame particles.
		if bounds.size.x > 12 and bounds.size.y > 12:
			for i in 18:
				var seed_value := posmod(hash(Vector2i(i+int(bounds.position.x),int(bounds.position.y))),104729)
				var point := bounds.position + Vector2(float(seed_value%97)/97.0,float(seed_value%71)/71.0)*bounds.size
				point = point.floor()
				if Geometry2D.is_point_in_polygon(point,pts) and Geometry2D.is_point_in_polygon(point+Vector2(3,2),pts):
					n.draw_rect(Rect2(point,Vector2(3,1 if i%2 else 2)),color.lightened(0.17) if i%3 else color.darkened(0.2))
		for i in pts.size():
			var from := pts[i]
			var to := pts[(i+1)%pts.size()]
			if from.y < bounds.position.y+bounds.size.y*0.4 and to.y < bounds.position.y+bounds.size.y*0.4:
				n.draw_line(from.lerp(bounds.get_center(),0.08),to.lerp(bounds.get_center(),0.08),color.lightened(0.36),1)
		pts.append(pts[0])
		n.draw_polyline(pts, Color("101d25"), 1.5)

static func tree(n: CanvasItem, stage: int, variant: int) -> void:
	var p := palette(stage)
	ArtUtil.fill_ellipse(n, 4, 4, 23, 7, Color(0.02, 0.04, 0.07, 0.4))
	# Exposed roots give all three regions a shared Blackwood ancestry.
	poly(n, [-17,5,-6,-5,-4,-32,5,-40,7,-8,19,5,8,2,1,7,-6,2], p[1])
	n.draw_line(Vector2(-2, 0), Vector2(1, -42), p[3], 2)
	if stage == 1:
		# Broken forks and open sky replace the leafy silhouette completely.
		poly(n, [-6,0,-8,-28,-21,-38,-26,-57,-19,-49,-16,-39,-7,-35,-10,-64,-3,-72,0,-49,9,-56,12,-69,16,-65,14,-49,4,-37,8,-20,7,2], p[1])
		poly(n, [0,-42,5,-38,3,-19,7,-9,4,0,0,-16,2,-27], p[4], false)
		n.draw_line(Vector2(-19,-43), Vector2(-12,-39), p[3], 2)
		if variant % 3 == 0:
			poly(n, [-13,-18,-19,-21,-18,-25,-10,-23], p[2])
			poly(n, [5,-32,15,-35,17,-31,7,-28], p[4])
	elif stage == 2:
		# Long hanging fronds, hollow faces and spectral seed pods.
		poly(n, [-5,-13,-10,-39,-20,-48,-26,-39,-21,-60,-8,-67,9,-63,22,-49,28,-31,16,-44,7,-41,8,-12,2,-25], p[1])
		for i in 7:
			var x := -23.0 + i * 7
			var y := -47.0 - sin(i * 0.8) * 13
			poly(n, [x,y,x+7,y-5,x+4,y+23+(i%3)*6,x+1,y+12], p[2] if i % 2 == 0 else p[1])
			n.draw_line(Vector2(x+2,y), Vector2(x+2,y+17), Color(p[3],0.4), 1)
		poly(n, [-4,-33,0,-38,5,-32,2,-21], p[0])
		for x in [-16, 16]:
			n.draw_line(Vector2(x,-38),Vector2(x,-22),p[3],1)
			poly(n,[x,-24,x+4,-20,x,-15,x-4,-20],p[4])
	else:
		# Layered angular leaf clusters, rather than identical round blobs.
		for i in 4:
			var x: float = [-12, 11, -2, 1][i]
			var y: float = [-37, -39, -52, -61][i] + variant % 3 * 2
			poly(n, [x-18,y+5,x-23,y-3,x-14,y-13,x-4,y-17,x+8,y-14,x+19,y-6,x+17,y+4,x+4,y+9], p[1] if i < 2 else p[2])
			poly(n, [x-17,y-5,x-9,y-13,x+2,y-13,x+10,y-7,x+3,y-8,x-5,y-5], p[3], false)
		if variant % 3 == 0:
			n.draw_line(Vector2(13,-34),Vector2(12,-14),p[3],1)
			poly(n,[8,-17,16,-17,15,-10,9,-10],p[4])
		for i in 2:
			var x := -11 + i * 16
			n.draw_rect(Rect2(x, -2, 2, 7),p[4])
			poly(n,[x-4,-2,x-2,-6,x+3,-6,x+5,-2],Color("bb7656"))

static func rock(n: CanvasItem, stage: int, variant: int) -> void:
	var p := palette(stage)
	ArtUtil.fill_ellipse(n, 2, 5, 18, 6, Color(0.02,0.04,0.07,0.4))
	if stage == 1:
		poly(n,[-17,4,-13,-18,-5,-30,2,-13,8,-37,16,-19,19,3,4,9],p[1])
		poly(n,[2,-13,8,-37,7,-9,14,1,4,5],p[2],false)
		n.draw_polyline(PackedVector2Array([Vector2(-10,-19),Vector2(-5,-7),Vector2(-9,2)]),p[4],2)
	elif stage == 2:
		for i in 3:
			var x := (i-1)*10
			var h := 26 + (variant+i)%3*7
			poly(n,[x-6,1,x-8,-h*0.6,x,-h,x+7,-h*0.5,x+5,4],p[2])
			poly(n,[x,-h,x+1,1,x+6,-h*0.5],p[4],false)
	else:
		var h := 25 if variant % 2 == 0 else 15
		poly(n,[-17,4,-15,-h+5,-6,-h-5,9,-h,16,-9,17,5,0,9],p[2])
		poly(n,[-15,-h+5,-6,-h-5,9,-h,4,-h+7,-7,-h+9],p[3],false)
		if variant % 2 == 0:
			n.draw_polyline(PackedVector2Array([Vector2(-3,-19),Vector2(3,-14),Vector2(-3,-9),Vector2(3,-4)]),p[5],2)
		else:
			poly(n,[-14,0,-6,-6,3,-3,5,4,-8,6],p[1],false)
