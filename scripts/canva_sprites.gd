class_name CanvaSprites
extends RefCounted

## Original Canva artwork supplied by the user. Atlas regions and foot
## anchors are metadata only: the source sheet remains unmodified.
const SHEET = preload("res://assets/sprites/original/blackwood_canva.png")
const ROLES := ["tank", "assassin", "mage", "marksman", "support"]
const X := [0, 130, 257, 380, 550]
const Y := [0, 125, 234, 337, 442, 550]
const FEET_X := [[69, 195, 319, 472], [75, 196, 320, 464], [71, 194, 317, 461], [69, 195, 317, 466], [76, 198, 320, 465]]
const FEET_Y := [116, 225, 328, 433, 537]
static var _frames: Dictionary = {}
static var _material: ShaderMaterial

static func frame(role: String, index: int) -> AtlasTexture:
	var row := maxi(0, ROLES.find(role))
	index = clampi(index, 0, 3)
	var key := row * 4 + index
	if not _frames.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		var columns: Array = [0, 130, 257, 369, 550] if row in [2, 4] else X
		atlas.region = Rect2(columns[index], Y[row], columns[index + 1] - columns[index], Y[row + 1] - Y[row])
		atlas.margin = Rect2(Vector2(96 - (FEET_X[row][index] - columns[index]), 150 - (FEET_Y[row] - Y[row])), Vector2(192, 160) - atlas.region.size)
		atlas.filter_clip = true
		_frames[key] = atlas
	return _frames[key]

static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = preload("res://shaders/canva_pixel.gdshader")
	return _material

static func pose_index(pose: String, elapsed: float) -> int:
	if pose == "walk":
		return [0, 1, 0, 2][int(elapsed * 10.0) % 4]
	if pose in ["attack", "skill_q", "skill_w", "ultimate"]:
		return 1 if elapsed < 0.045 else (3 if elapsed < 0.18 else 0)
	return 0
