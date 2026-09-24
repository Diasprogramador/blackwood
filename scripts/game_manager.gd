class_name GameManager
extends RefCounted

## Port de GameManager.java — fluxo console (menu, ondas, loja, inventário).
## No jogo real esse fluxo é tempo-real em main.gd (HUD/ShopUI/ChampSelect);
## aqui fica a versão fiel headless: mesma ordem de métodos do Java,
## com Scanner/System.out trocados por parâmetros + print.
## Uso: var gm := GameManager.new(); gm.start("tank", "Garen"); gm.exploration_loop_auto()

var player: Player
var wave: int = 0

const ROLE_KEYS := ["tank", "assassin", "mage", "marksman", "support"]

func _init() -> void:
	randomize()
	wave = 0

# ===================== SETUP =====================
func start(p_role: String = "tank", p_name: String = "Garen") -> void:
	print("\n╔══════════════════════════════════════╗")
	print("║     BLACKWOOD - Backend em Java      ║")
	print("║        Aprenda POO na pratica        ║")
	print("╚══════════════════════════════════════╝\n")
	create_character(p_role, p_name)
	give_starting_items()
	# Java chamava mainLoop() bloqueante aqui; no Godot o main.gd dirige
	# o fluxo — use exploration_loop(), shop(), use_item_menu(), etc.

func create_character(p_role: String, p_name: String) -> void:
	var role_key := p_role.to_lower()
	if not (role_key in ROLE_KEYS):
		role_key = "support"
	var champ_name := p_name.strip_edges()
	if champ_name == "":
		champ_name = "Garen"
	player = Player.new()
	player.setup(champ_name, role_key)
	# Demo headless: equipa todas as skills da role (no jogo real elas vêm
	# dos desbloqueios do menu — ver StageData.unlocked_skills).
	for sk in ChampData.ROLES[role_key].skills:
		if player.skills.size() < ChampData.SKILL_SLOTS:
			player.skills.append({ cfg = sk, cd_left = 0.0 })
	assign_skills()
	var display: String = ChampData.ROLES[role_key].display
	print("\n>> %s, o %s, entra na Rift!\n" % [champ_name, display])

func assign_skills() -> void:
	## No Java criava DamageSkill/MagicSkill/AreaDamageSkill/HealSkill
	## manualmente por Role (Golpe Destemido, Sombra Relâmpago, ...).
	## No Godot as skills já vêm de ChampData.ROLES via player.setup()
	## (tank = Golpe Destemido + Fúria de Ferro, etc. — ver champ_data.gd).
	pass

func give_starting_items() -> void:
	if player == null:
		return
	if player.inventory.is_empty():
		player.give_starting_items()
	print(">> Itens iniciais adicionados ao inventario!\n")

# ===================== MAIN LOOP (headless) =====================
## Equivalente não-bloqueante do mainLoop() do Java: avança N ondas
## sozinho (ataque básico). Para jogar de verdade, ver main.gd.
func main_loop_demo(max_waves: int = 3) -> void:
	while player != null and player.is_alive() and wave < max_waves:
		exploration_loop_auto()
	if player != null and not player.is_alive():
		game_over()

# ===================== EXPLORACAO =====================
func exploration_loop(target_index: int = 0, use_skills: bool = false) -> void:
	wave += 1
	print("\n>> === ONDA %d ===" % wave)

	var num_enemies := 1 + randi() % mini(wave, 3)
	print(">> %d inimigo(s) apareceram!\n" % num_enemies)

	var enemies: Array = []
	for i in num_enemies:
		var e := create_random_enemy()
		enemies.append(e)
		print("  [%d] %s Lv.%d | HP: %d/%d | ATK: %d | DEF: %d" % [
			i + 1, e.type_name, e.level, e.hp, e.max_hp, e.attack, e.defense,
		])

	var target: Enemy = enemies[clampi(target_index, 0, num_enemies - 1)]
	combat(target, use_skills)

	# Recompensas
	if not target.is_alive():
		var gold: int = target.gold_reward
		var xp: int = target.exp_reward
		player.add_gold(gold)
		var msg := player.gain_exp(xp)
		if msg != "":
			print("  >> " + msg)
		print("\n>> Recompensas: %d Gold | %d EXP" % [gold, xp])

func exploration_loop_auto() -> void:
	exploration_loop(0, true)

# ===================== COMBATE =====================
func combat(enemy: Enemy, auto_skill: bool = false) -> void:
	print("\n╔═══════════════════════════════╗")
	print("║        COMBATE INICIADO!      ║")
	print("╚═══════════════════════════════╝")

	var round := 1
	while player.is_alive() and enemy.is_alive():
		print("\n--- ROUND %d ---" % round)
		_display_status(player)
		_display_enemy_info(enemy)

		# Turno do jogador
		if auto_skill:
			player_turn(enemy, 2)
		else:
			player_turn(enemy, 1)

		if not enemy.is_alive():
			break

		# Turno do inimigo
		print()
		_enemy_take_turn(enemy)

		# Regeneração + cooldowns (fim do round, como no Java)
		_end_of_round()
		round += 1

	if not player.is_alive():
		print("\n>> VOCE FOI DERROTADO!")
	else:
		print("\n>> VITORIA! Inimigo derrotado!")

## [1] básico, [2] skill 1, [3] skill 2, [4] usar item, [5] ver status.
func player_turn(enemy: Enemy, choice: int = 1) -> void:
	match choice:
		1:
			var result = player.basic_attack([enemy])
			if result == null:
				print("  >> Sem alvo no alcance!")
			elif result.crit:
				print("  >> %s ataca %s com golpe critico! (%d de dano)" % [
					player.champ_name, enemy.type_name, result.dmg,
				])
			else:
				print("  >> %s ataca %s! (%d de dano)" % [
					player.champ_name, enemy.type_name, result.dmg,
				])
		2:
			_cast_feedback(player.cast_skill(0, [enemy]), enemy)
		3:
			_cast_feedback(player.cast_skill(1, [enemy]), enemy)
		4:
			use_item_menu(1)
		5:
			_display_full_status()
		_:
			print(">> Acao invalida, atacando...")
			player_turn(enemy, 1)

func _cast_feedback(result: Dictionary, enemy: Enemy) -> void:
	if not result.get("ok", false):
		print("  >> " + str(result.get("reason", "Sem mana / em cooldown!")))
		var fallback = player.basic_attack([enemy])
		if fallback != null:
			print("  >> %s ataca %s! (%d de dano)" % [
				player.champ_name, enemy.type_name, fallback.dmg,
			])
		return
	if result.get("kind") == "heal":
		print("  >> %s se cura! (+%d HP)" % [player.champ_name, result.get("amount", 0)])
	else:
		print("  >> %s usa %s em %s! (%d de dano)" % [
			player.champ_name, result.get("name", "skill"),
			enemy.type_name, result.get("dmg", 0),
		])

## Port de Enemy.takeTurn(): fúria com HP baixo, senão ataque normal.
func _enemy_take_turn(enemy: Enemy) -> void:
	var raw: int
	if enemy.hp < enemy.max_hp / 2.0:
		raw = int(enemy.calc_damage() * 1.5)
		var dealt: int = player.take_damage(raw)
		print("  >> %s entra em fúria e ataca %s! (%d de dano)" % [
			enemy.type_name, player.champ_name, dealt,
		])
	else:
		raw = enemy.calc_damage()
		var dealt: int = player.take_damage(raw)
		print("  >> %s ataca %s! (%d de dano)" % [
			enemy.type_name, player.champ_name, dealt,
		])

func _end_of_round() -> void:
	var regen := maxi(1, int(player.mana_regen + player.level * 0.3))
	player.restore_mana(regen)
	# 1 "segundo" por round: libera o ataque básico (como no Java, sem cooldown)
	# e reduz o cooldown das skills ditadas por dicionário.
	player.attack_cd = maxf(0.0, player.attack_cd - 1.0)
	for s in player.skills:
		if s is Skill:
			s.reduce_cooldown()
		elif s is Dictionary and s.has("cd_left"):
			s.cd_left = maxf(0.0, s.cd_left - 1.0)

# ===================== LOJA =====================
## buy_index: 1-based como no Java ([0] = voltar → passe -1 ou 0).
func shop(buy_index: int = -1) -> void:
	print("\n╔═══════════════════════════════╗")
	print("║          LOJA DA RIFT         ║")
	print("║         Gold: %d             ║" % player.gold)
	print("╚═══════════════════════════════╝")

	var catalog: Array = player.shop_catalog()
	for i in catalog.size():
		var item: Item = catalog[i]
		print("[%d] %s - %d Gold" % [i + 1, item, item.price])
	print("[0] Voltar")

	if buy_index > 0 and buy_index <= catalog.size():
		player.buy_item(catalog[buy_index - 1])

# ===================== INVENTARIO =====================
func use_item_menu(index: int = -1) -> void:
	if player.inventory.is_empty():
		print(">> Inventario vazio!")
		return
	print("\nSeus itens:")
	for i in player.inventory.size():
		print("[%d] %s" % [i + 1, player.inventory[i]])
	print("[0] Cancelar")
	if index > 0 and index <= player.inventory.size():
		player.use_item(index - 1)

func equip_menu(index: int = -1) -> void:
	if player.inventory.is_empty():
		print(">> Inventario vazio!")
		return
	print("\nItens para equipar:")
	for i in player.inventory.size():
		print("[%d] %s" % [i + 1, player.inventory[i]])
	print("[0] Cancelar")
	if index > 0 and index <= player.inventory.size():
		player.equip_item(index - 1)

# ===================== GAME OVER =====================
func game_over() -> void:
	print("\n╔══════════════════════════════╗")
	print("║         GAME OVER!           ║")
	print("╚══════════════════════════════╝")
	_display_full_status()
	print(">> Voce sobreviveu a %d ondas!" % wave)

# ===================== UTILITARIOS =====================
func create_random_enemy() -> Enemy:
	var enemy_level := maxi(1, wave + randi_range(-1, 1))
	var key: String = EnemyData.random_type(maxi(1, wave))
	var e := Enemy.new()
	e.setup(key, enemy_level)
	return e

# ===================== DISPLAY =====================
func _display_status(p: Player) -> void:
	print("  %-15s Lv.%-3d | HP: %d/%d | MP: %d/%d" % [
		p.champ_name, p.level, p.hp, p.max_hp, int(p.mana), p.max_mana,
	])

func _display_enemy_info(e: Enemy) -> void:
	print("  %s Lv.%d | HP: %d/%d | ATK: %d | DEF: %d" % [
		e.type_name, e.level, e.hp, e.max_hp, e.attack, e.defense,
	])

func _display_full_status() -> void:
	if player == null:
		return
	var role_display: String = ChampData.ROLES[player.role].display
	print("  %s (%s) Lv.%d | HP: %d/%d | MP: %d/%d" % [
		player.champ_name, role_display, player.level,
		player.hp, player.max_hp, int(player.mana), player.max_mana,
	])
	print("  ATK: %d | DEF: %d | MAG: %d | Gold: %d | EXP: %d/%d" % [
		player.attack, player.defense, player.magic, player.gold,
		player.xp, player.exp_to_next(),
	])
	print("  Habilidades:")
	for i in player.skills.size():
		var s = player.skills[i]
		if s is Skill:
			print("    [%d] %s (MP: %d) CD: %d" % [
				i + 1, s.get_name(), s.get_mana_cost(), s.get_current_cooldown(),
			])
		elif s is Dictionary:
			var cfg: Dictionary = s.get("cfg", s)
			print("    [%d] %s (MP: %d) CD: %.1fs" % [
				i + 1, cfg.get("name", "?"),
				int(cfg.get("mana", 0)), float(s.get("cd_left", 0.0)),
			])
	print("  Inventário (%d/%d):" % [player.inventory.size(), Player.MAX_INVENTORY])
	for i in player.inventory.size():
		print("    [%d] %s" % [i + 1, player.inventory[i]])
