class_name Enemy
extends Node2D

## Inimigo: stats portados do Enemy.java, IA de perseguição,
## combate corpo a corpo e queda de gold ao morrer.

signal died(enemy: Enemy)

static var A = ArtUtil

const DEATH_TIME := 1.6

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
var speed_mult := 1.0
var is_boss_flag := false
var is_miniboss_flag := false
var is_elite := false
var stage_idx := 0
# Desencalhe: se anda e não sai do lugar, contorna de lado por um tempo.
# Se ficar 3s garrado (lago/mata fechada), busca outra rota livre.
var _stuck_t := 0.0
var _side := 0.0
var _side_t := 0.0
var _detour := Vector2.ZERO
var _detour_t := 0.0
var _has_detour := false
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
	attack = maxi(1, int((int(td.atk) + (level - 1) * 4) * float(mults.get("atk", 1.0))))
	defense = maxi(0, int((int(td.def) + (level - 1) * 2) * float(mults.get("df", 1.0))))
	magic = int(td.mag) + (level - 1) * 2
	gold_reward = maxi(1, int((int(td.gold) + (level - 1) * 3) * float(mults.get("gold", 1.0))))
	exp_reward = maxi(1, int((int(td.exp) + (level - 1) * 3) * float(mults.get("exp", 1.0))))
	speed_mult = float(mults.get("speed", 1.0))
	is_boss_flag = bool(mults.get("boss", false))
	is_miniboss_flag = bool(mults.get("miniboss", false))
	is_elite = bool(mults.get("elite", false))
	base_color = td.color
	dead = false
	death_timer = -1.0
	attack_cd = 0.0
	hit_flash = 0
	facing = 1
	_stuck_t = 0.0
	_side = 0.0
	_side_t = 0.0
	_has_detour = false
	_detour_t = 0.0
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

## Procura um ponto livre (não-sólido) para contornar lago/mata fechada.
## Guarda em _detour e retorna true se achar.
func _pick_detour() -> bool:
	if world == null:
		return false
	for attempt in 14:
		var a := randf() * TAU
		var r := randf_range(140.0, 260.0)
		var cand := position + Vector2(cos(a), sin(a)) * r
		if not world.is_solid_at(cand.x, cand.y):
			_detour = cand
			return true
	return false

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
	moving = d > 40.0 and player.is_alive()

	if absf(to_player.x) > 1.0:
		facing = 1 if to_player.x > 0 else -1

	if moving and world != null:
		var speed := (1.7 + level * 0.07) * 60.0 * speed_mult  # px/s
		if d > 420.0:
			speed *= 1.15  # faro: corre para alcançar a presa distante
		var dir := to_player.normalized()
		if _has_detour:
			# Outra rota: vai até o ponto livre e só então volta a caçar.
			var to_way := _detour - position
			if to_way.length() < 20.0 or _detour_t <= 0.0:
				_has_detour = false
				_stuck_t = 0.0
				_side = 0.0
			else:
				dir = to_way.normalized()
				_detour_t -= delta
		elif _side != 0.0:
			# Desencalhe: contorna o obstáculo de lado em vez de tremer parado.
			var side_v := Vector2(-dir.y, dir.x) * _side
			dir = (dir * 0.35 + side_v * 0.95).normalized()
			_side_t -= delta
			if _side_t <= 0.0:
				_side = 0.0
				_stuck_t = 0.0
		# Velocidade suavizada (acelera/desacelera, sem snap).
		var want := dir * speed
		evel = evel.lerp(want, 1.0 - exp(-8.0 * delta))
		var dist_before := d
		# Regra de fuga: quem está DENTRO do sólido sempre pode sair
		# (mas nunca entrar) — evita paralisia total no lago/mata.
		var cur_solid: bool = world.is_solid_at(position.x, position.y)
		var nx := position.x + evel.x * delta
		if cur_solid or not world.is_solid_at(nx, position.y):
			position.x = nx
		var ny := position.y + evel.y * delta
		if cur_solid or not world.is_solid_at(position.x, ny):
			position.y = ny
		# Andou de verdade? Se quase não se aproximou, está grudado.
		var gained: float = dist_before - position.distance_to(player.position)
		if _has_detour:
			pass  # desvio em andamento: não conta como preso nem solto
		elif gained < speed * delta * 0.25:
			_stuck_t += delta
			if _stuck_t >= 3.0:
				# 3s garrado no lago/mata: abandona e pega outra rota livre.
				if _pick_detour():
					_has_detour = true
					_detour_t = 2.5
					_side = 0.0
				else:
					# Sem ponto livre por perto: tenta de novo em breve.
					_stuck_t = 1.5
					_side = -_side if _side != 0.0 else (1.0 if randf() < 0.5 else -1.0)
					_side_t = 0.9
			elif _stuck_t > 0.5 and _side == 0.0:
				_side = 1.0 if randf() < 0.5 else -1.0
				_side_t = 0.9
		else:
			_stuck_t = 0.0
			_side = 0.0
	elif not moving:
		evel = evel.lerp(Vector2.ZERO, 1.0 - exp(-8.0 * delta))
		_stuck_t = 0.0
		_side = 0.0
		_has_detour = false

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

func _draw() -> void:
	# Sombra no chão (o corpo é o Sprite2D `body`).
	ArtUtil.fill_ellipse(self, 0, 8, sh_w, sh_w * 0.32, Color(0, 0, 0, 0.32))
	if not has_sprites:
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

	if not dead:
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
