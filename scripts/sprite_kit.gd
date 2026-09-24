class_name SpriteKit
extends Object

## Sprites do kit do usuário: loader com cache, âncora dos pés via SpriteMeta
## (bbox pré-computada) e escala por altura-alvo. A arte olha para a ESQUERDA;
## o flip é aplicado por quem usa (body.scale.x negativo = olhando p/ direita).

const ROOT := "res://assets/sprites/"
const CHAMP_BY_ROLE := {
	"tank": "garen", "assassin": "zed", "mage": "ahri",
	"marksman": "ashe", "support": "janna",
}
const PHASE_DIRS := ["phase1-forest", "phase2-burnt", "phase3-void"]
const ENEMY_FILES := {
	"MINION": ["minion_floresta", "minion_chamuscado", "minion_corrompido"],
	"CASTER": ["caster_floresta", "caster_chamuscado", "caster_corrompido"],
	"GOLEM": ["golem_floresta", "golem_chamuscado", "golem_corrompido"],
	"JUNGLE": ["fera_floresta", "fera_chamuscada", "fera_corrompida"],
	"DRAGON": ["dragao_floresta", "dragao_chamuscado", "dragao_vazio"],
	"BARON": ["horror_floresta", "horror_chamuscado", "horror_vazio"],
}
## Elite da fase 2 usa sprite própria.
const ELITE_FILE := "minion_chamuscado_v2"
const CHAMP_H := 68.0
const TARGET_H := {
	"MINION": 46.0, "CASTER": 48.0, "JUNGLE": 56.0,
	"GOLEM": 76.0, "DRAGON": 88.0, "BARON": 104.0,
}

static var _tex := {}

static func tex(rel: String) -> Texture2D:
	if _tex.has(rel):
		return _tex[rel]
	var t: Texture2D = load(ROOT + rel)
	_tex[rel] = t
	return t

static func champ_pose(role: String, pose: String) -> String:
	var folder: String = CHAMP_BY_ROLE.get(role, "garen")
	return "champions/%s/%s_%s.png" % [folder, folder, pose]

static func champ_vfx(role: String, kind: String) -> String:
	var folder: String = CHAMP_BY_ROLE.get(role, "garen")
	return "champions/%s/%s_vfx_%s.png" % [folder, folder, kind]

static func enemy_file(type_key: String, stage: int, elite: bool) -> String:
	var d: String = PHASE_DIRS[clampi(stage, 0, 2)]
	if elite and stage == 1:
		return "enemies/%s/%s.png" % [d, ELITE_FILE]
	var stems: Array = ENEMY_FILES.get(type_key, ENEMY_FILES["MINION"])
	return "enemies/%s/%s.png" % [d, stems[clampi(stage, 0, 2)]]

static func box_of(rel: String) -> Rect2:
	var a: Array = SpriteMeta.BOXES.get(rel, [0, 0, 256, 256])
	return Rect2(a[0], a[1], a[2] - a[0], a[3] - a[1])

static func target_h_for(type_key: String, mini: bool, elite: bool) -> float:
	var h: float = TARGET_H.get(type_key, 48.0)
	if mini:
		h *= 1.12
	elif elite:
		h *= 1.08
	return h

## Escala p/ altura-alvo e ancora os pés (base da bbox) na origem.
## Retorna a escala. Não mexe no sinal do scale (flip é de fora).
static func fit(spr: Sprite2D, rel: String, target_h: float) -> float:
	var t := tex(rel)
	if t == null:
		return 0.0
	spr.texture = t
	spr.centered = true
	var box := box_of(rel)
	var sc: float = target_h / maxf(1.0, box.size.y)
	var tw := float(t.get_width())
	var th := float(t.get_height())
	spr.offset = Vector2(box.get_center().x - tw * 0.5, box.end.y - th * 0.5)
	spr.scale = Vector2(sc, sc)
	return sc

## Só troca a textura reajustando o offset (mantém a escala atual).
static func swap(spr: Sprite2D, rel: String) -> bool:
	var t := tex(rel)
	if t == null:
		return false
	spr.texture = t
	var box := box_of(rel)
	var tw := float(t.get_width())
	var th := float(t.get_height())
	spr.offset = Vector2(box.get_center().x - tw * 0.5, box.end.y - th * 0.5)
	return true

## Centraliza (p/ VFX): ignora a bbox, usa o centro da imagem.
static func fit_center(spr: Sprite2D, rel: String, target_h: float) -> float:
	var t := tex(rel)
	if t == null:
		return 0.0
	spr.texture = t
	spr.centered = true
	spr.offset = Vector2.ZERO
	var sc: float = target_h / maxf(1.0, float(t.get_height()))
	spr.scale = Vector2(sc, sc)
	return sc
