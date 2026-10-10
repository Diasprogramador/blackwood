class_name Enemy
extends Node2D

## Inimigo: stats portados do Enemy.java, IA de perseguição,
## combate corpo a corpo e queda de gold ao morrer.

signal died(enemy: Enemy)
signal shoot(enemy: Enemy)

static var A = ArtUtil

const DEATH_TIME := 1.6
var net_id := -1  # multiplayer: id estável do spawn (host)

var type_key := "MINION"
var type_name := "Minion"
var level := 1
var max_hp := 60
var hp := 60
var attack := 8
var defense := 3
var magic := 2
var gold_reward := 20
var exp_reward := 20
var base_color := Color.RED

var facing := 1
var moving := false
var walk_phase := 0.0
var attack_cd := 0.0
var hit_flash := 0
var death_timer := -1.0
var dead := false
var reward_claimed := false
var speed_mult := 1.0
var is_boss_flag := false
var is_miniboss_flag := false
var is_elite := false
var stage_idx := 0
# Recovery is reserved for invalid spawns; navigation handles obstacles.
var _stuck_t := 0.0
var _side := 0.0
var _side_t := 0.0
var _detour := Vector2.ZERO
var _detour_t := 0.0
var _has_detour := false
# Ataque à distância (CASTER cerca e fuzila, DRAGÃO cospe fogo).
const RANGED_TYPES := ["CASTER", "DRAGON"]
var shoot_cd := 0.0
var charge_t := 0.0
var _strafe := 1.0
# Sprite do kit + cinemática suavizada (sem snaps).
var body: Sprite2D = null
var evel := Vector2.ZERO
var flip := 1.0
var spr_scale := 1.0
var has_sprites := false
var lunge_t := 0.0
var squash := 0.0
var lean := 0.0
var bob_t := 0.0
var sh_w := 14.0

var world: World

func setup(type_key_p: String, lvl: int, mults: Dictionary = {}) -> void:
	type_key = type_key_p
	level = lvl
	var td: Dictionary = EnemyData.TYPES[type_key]
	type_name = td.name
	# Escala por nível: combate sobe rápido, economia sobe devagar (balance).
	max_hp = maxi(1, int((int(td.hp) + (level - 1) * 18) * float(mults.get("hp", 1.0))))
	hp = max_hp
	attack = maxi(1, int((int(td.atk) + (level - 1) * 2) * float(mults.get("atk", 1.0))))
	defense = maxi(0, int((int(td.def) + (level - 1) * 1) * float(mults.get("df", 1.0))))
	magic = int(td.mag) + (level - 1) * 2
	gold_reward = maxi(1, int((int(td.gold) + (level - 1) * 3) * float(mults.get("gold", 1.0))))
	exp_reward = maxi(1, int((int(td.exp) + (level - 1) * 3) * float(mults.get("exp", 1.0))))
	speed_mult = float(mults.get("speed", 1.0))
	is_boss_flag = bool(mults.get("boss", false))
	is_miniboss_flag = bool(mults.get("miniboss", false))
	is_elite = bool(mults.get("elite", false))
	base_color = td.color
	# Fauna da fase: cor e nome mudam com o tema (chefões mantêm o nome).
	if stage_idx == 1:
		base_color = (td.color as Color).lerp(Color(1, 0.55, 0.25), 0.3)
		if not is_boss():
			type_name = "%s Chamuscado" % type_name
	elif stage_idx == 2:
		base_color = (td.color as Color).lerp(Color(0.7, 0.4, 1), 0.3)
		if not is_boss():
			type_name = "%s Corrompido" % type_name
	dead = false
	reward_claimed = false
	death_timer = -1.0
	attack_cd = 0.0
	hit_flash = 0
	facing = 1
	_stuck_t = 0.0
	_side = 0.0
	_side_t = 0.0
	_has_detour = false
	_detour_t = 0.0
	shoot_cd = randf_range(1.0, 2.0)
	charge_t = 0.0
	_strafe = 1.0 if randf() < 0.5 else -1.0
	lunge_t = 0.0
	squash = 0.0
	lean = 0.0
	evel = Vector2.ZERO
	flip = 1.0
	scale = Vector2.ONE
	modulate = Color.WHITE
	# Sprite do kit (fallback procedural se faltar arquivo).
	_ensure_body()
	var rel := SpriteKit.enemy_file(type_key, stage_idx, is_elite and not is_boss() and not is_miniboss())
	has_sprites = SpriteKit.tex(rel) != null
	if has_sprites:
		spr_scale = SpriteKit.fit(body, rel, SpriteKit.target_h_for(type_key, is_miniboss(), is_elite))
		body.modulate = Color.WHITE
		body.rotation = 0.0
		body.position = Vector2.ZERO
		sh_w = 30.0 if is_boss() else (26.0 if is_miniboss() else (22.0 if is_elite else (20.0 if type_key == "GOLEM" else 14.0)))
	queue_redraw()

func _ensure_body() -> void:
	if body != null and is_instance_valid(body):
		return
	body = Sprite2D.new()
	body.name = "Body"
	body.centered = true
	add_child(body)

func is_alive() -> bool:
	return not dead

func is_boss() -> bool:
	return is_boss_flag or type_key == "DRAGON" or type_key == "BARON"

func is_miniboss() -> bool:
	return is_miniboss_flag and not is_boss()

func is_ranged() -> bool:
	return type_key in RANGED_TYPES

func prefer_range() -> float:
	return 230.0 if type_key == "DRAGON" else 200.0

func shoot_reach() -> float:
	return 340.0 if type_key == "DRAGON" else 300.0

func bolt_color() -> Color:
	if type_key == "DRAGON":
		return Color(1, 0.45, 0.1)
	return Color(0.85, 0.4, 1)

## Chamado pela Main a cada frame enquanto joga.
func ai_update(player: Player, delta: float) -> void:
	if dead:
		# Morte suave: tomba de lado, afunda e some com fade (não some de repente).
		if death_timer >= 0.0:
			death_timer -= delta
			var a := clampf(death_timer / DEATH_TIME, 0.0, 1.0)
			modulate = Color(1, 1, 1, a)
			position.y += 8.0 * delta
			if body != null and has_sprites:
				body.rotation = lerpf(body.rotation, 1.5 * float(facing), 1.0 - exp(-6.0 * delta))
			queue_redraw()
		return

	if attack_cd > 0.0:
		attack_cd -= delta
	if hit_flash > 0:
		hit_flash -= 1
		queue_redraw()

	var to_player := player.position - position
	var d := to_player.length()
	# Caçada global: sem limite de distância — se você está vivo, eles vêm.
	# (Antes paravam a 420px; agora atravessam o mapa atrás de você.)
	moving = player.is_alive() and (d > 40.0 or (world != null and not world.navigation.clear_segment(position, player.position)))

	if absf(to_player.x) > 1.0:
		facing = 1 if to_player.x > 0 else -1

	if moving and world != null:
		var spd_mult := 1.0
		var speed := (1.7 + level * 0.07) * 60.0 * speed_mult * spd_mult  # px/s
		if d > 420.0:
			speed *= 1.15  # faro: corre para alcançar a presa distante
		var dir := world.navigation.direction(position, player.position)
		if is_ranged() and d < prefer_range() * 1.4 and world.navigation.clear_segment(position, player.position):
			var radial := to_player.normalized()
			var orbit := radial.orthogonal() * _strafe
			if d < prefer_range() * 0.7:
				orbit = (-radial + orbit * 0.5).normalized()
			if world.navigation.clear_segment(position, position + orbit * 48.0):
				dir = orbit
				speed *= 0.6
		var before := position
		evel = dir * speed
		position = MoveHelper.slide_step(world, position, evel * minf(delta, 0.05))
		if absf(position.x - before.x) > 0.01:
			facing = 1 if position.x > before.x else -1
		# Only invalid spawns need recovery; valid enemies follow connected routes.
		if not MoveHelper.can_enter(world, position):
			_stuck_t += delta
			if _stuck_t > 0.4:
				var free := MoveHelper.find_free(world, position)
				if free != Vector2.INF:
					position = free
				_stuck_t = 0.0
		else:
			_stuck_t = 0.0
	elif not moving:
		evel = evel.lerp(Vector2.ZERO, 1.0 - exp(-8.0 * delta))
		_stuck_t = 0.0
		_side = 0.0
		_has_detour = false

	# Tiro à distância (independe de estar andando).
	if not dead and world != null and player != null and is_instance_valid(player) \
			and is_ranged() and player.is_alive():
		if shoot_cd > 0.0:
			shoot_cd -= delta
		if charge_t > 0.0:
			charge_t -= delta
			if charge_t <= 0.0:
				charge_t = 0.0
				shoot.emit(self)
		elif shoot_cd <= 0.0:
			var dd := position.distance_to(player.position)
			if dd < shoot_reach() and dd > 50.0:
				charge_t = 0.5
				shoot_cd = randf_range(2.0, 2.6) if is_boss() else randf_range(2.4, 3.2)

	_update_body(delta)

	walk_phase += (6.0 if moving else 0.5) * delta
	if moving or hit_flash > 0:
		queue_redraw()

## Sprite: bob, inclinação, lunge e flip — tudo interpolado.
func _update_body(delta: float) -> void:
	if body == null or not has_sprites:
		return
	flip = move_toward(flip, float(facing), delta / 0.12)
	squash = maxf(0.0, squash - delta * 5.0)
	if lunge_t > 0.0:
		lunge_t = maxf(0.0, lunge_t - delta)
	var spd := evel.length()
	bob_t += delta * (4.0 + spd * 0.05)
	var bob := sin(bob_t) * minf(2.5, 0.8 + spd * 0.008) if moving else sin(bob_t * 0.5) * 1.0
	lean = lerpf(lean, clampf(evel.x * 0.0004, -0.10, 0.10), 1.0 - exp(-8.0 * delta))
	var lunge := 8.0 * (lunge_t / 0.2) if lunge_t > 0.0 else 0.0
	var kx := 0.18 * squash
	var ky := -0.14 * squash
	body.position = Vector2(lunge * flip, bob)
	body.rotation = lean
	body.scale = Vector2(-flip * spr_scale * (1.0 + kx), spr_scale * (1.0 + ky))
	if hit_flash > 0:
		body.modulate = Color(1, 0.45, 0.45)
	else:
		body.modulate = Color.WHITE

## Tenta atacar o jogador (chamado pela Main).
func try_attack(player: Player) -> bool:
	if dead or attack_cd > 0.0 or not player.is_alive():
		return false
	if position.distance_to(player.position) >= 44.0:
		return false
	if world != null and not world.navigation.clear_segment(position, player.position):
		return false
	var raw: int
	if hp < max_hp / 2.0:
		raw = int(calc_damage() * 1.5)
	else:
		raw = calc_damage()
	player.take_damage(raw)
	attack_cd = 0.7
	lunge_t = 0.2
	squash = 0.8
	return true

func calc_damage() -> int:
	return int(attack * randf_range(0.85, 1.25))

func take_damage(raw: int) -> int:
	if dead:
		return 0
	var reduction := defense / float(defense + 100)
	var final_d := maxi(1, int(raw * (1.0 - reduction)))
	hp = maxi(0, hp - final_d)
	hit_flash = 12
	squash = 1.0
	queue_redraw()
	if hp <= 0:
		dead = true
		death_timer = DEATH_TIME
		died.emit(self)
	return final_d

func _process(_delta: float) -> void:
	pass

## Client multiplayer: só anima (posição/HP vêm do host).
func client_tick(delta: float) -> void:
	if dead:
		if death_timer >= 0.0:
			death_timer -= delta
			var a := clampf(death_timer / DEATH_TIME, 0.0, 1.0)
			modulate = Color(1, 1, 1, a)
			position.y += 8.0 * delta
			queue_redraw()
		return
	walk_phase += (6.0 if moving else 0.5) * delta
	if hit_flash > 0:
		hit_flash -= 1
	if moving or hit_flash > 0:
		queue_redraw()

func _draw() -> void:
	# Sombra no chão (o corpo é o Sprite2D `body`).
	ArtUtil.fill_ellipse(self, 0, 8, sh_w, sh_w * 0.32, Color(0, 0, 0, 0.32))
	# Telegraph do tiro: brilho crescendo na direção do player.
	if charge_t > 0.0 and not dead:
		var k := 1.0 - charge_t / 0.5
		var bc := bolt_color()
		var at := Vector2(facing * 16.0, -8.0)
		draw_circle(at, 5.0 + k * 9.0, Color(bc, 0.35 + 0.4 * k))
		draw_arc(at, 12.0 + k * 8.0, 0, TAU, 16, Color(bc, 0.7), 2.0)
	if not has_sprites:
		var frames: Array = world.enemy_textures.get("%s:%d" % [type_key, stage_idx], []) if world != null else []
		if not frames.is_empty():
			var frame := posmod(int(walk_phase * 4.0 / TAU), 4) if moving else 0
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(facing), 1))
			draw_texture(frames[frame], Vector2(-96, -96), Color(1, 0.45, 0.45) if hit_flash > 0 else Color.WHITE)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_hud(self)
			return
		# Fallback procedural (espelha via transform p/ não espelhar o HUD).
		if facing < 0:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
			EnemyArt.draw_enemy(self, type_key, base_color, hit_flash > 0, walk_phase, moving)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			EnemyArt.draw_enemy(self, type_key, base_color, hit_flash > 0, walk_phase, moving)
	draw_hud(self)

func draw_hud(node: CanvasItem) -> void:
	if dead:
		return
	var boss := is_boss()
	var is_mini := is_miniboss()
	if not boss and not is_mini and not is_elite and hp == max_hp:
		return
	var big := boss or is_mini or type_key == "GOLEM"
	var y := -48.0 if (boss or is_mini) else (-44.0 if big else -30.0)
	var w := 58.0 if boss else (48.0 if is_mini else (40.0 if is_elite else 28.0))
	node.draw_rect(Rect2(-w / 2 - 1, y - 1, w + 2, 6), Color(0, 0, 0, 0.65))
	node.draw_rect(Rect2(-w / 2, y, w, 4), Color(0.25, 0.1, 0.1))
	var ratio := clampf(hp / float(maxi(1, max_hp)), 0.0, 1.0)
	var bar_col := Color(0.9, 0.2, 0.2)
	if boss:
		bar_col = Color(0.75, 0.2, 0.9) if ratio > 0.3 else Color(0.95, 0.15, 0.25)
	elif is_mini:
		bar_col = Color(1.0, 0.35, 0.1) if ratio > 0.3 else Color(0.95, 0.15, 0.2)
	elif is_elite:
		bar_col = Color(1.0, 0.55, 0.15)
	elif ratio > 0.5:
		bar_col = Color(0.25, 0.8, 0.3)
	elif ratio > 0.25:
		bar_col = Color(0.95, 0.8, 0.2)
	node.draw_rect(Rect2(-w / 2, y, w * ratio, 4), bar_col)
	var border := Color(1, 0.85, 0.3) if boss else (Color(1, 0.4, 0.15) if is_mini else (Color(1, 0.6, 0.2) if is_elite else Color(0, 0, 0, 0.8)))
	node.draw_rect(Rect2(-w / 2, y, w, 4), border, false, 1.5 if (boss or is_mini) else 1.0)

	if not dead and (boss or is_mini or is_elite):
		var label := ""
		if boss:
			label = "★ BOSS Lv.%d %s ★" % [level, type_name]
		elif is_mini:
			label = "👹 MINI-BOSS Lv.%d %s" % [level, type_name]
		elif is_elite:
			label = "◆ ELITE Lv.%d %s" % [level, type_name]
		else:
			label = "%s Lv.%d" % [type_name, level]
		var font := ThemeDB.fallback_font
		var fsize := 11 if (boss or is_mini) else 10
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		var ty := y - 6
		var txt_col := Color(1, 0.85, 0.35) if boss else (Color(1, 0.5, 0.25) if is_mini else (Color(1, 0.7, 0.35) if is_elite else Color(0.85, 0.85, 0.88)))
		node.draw_string(font, Vector2(-tw / 2 + 1, ty + 1), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(0, 0, 0, 0.8))
		node.draw_string(font, Vector2(-tw / 2, ty), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, txt_col)
