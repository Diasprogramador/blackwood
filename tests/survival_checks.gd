extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	seed(4242)
	game.start_game(2, 0, 0, 4242)
	game.player.controlled = false
	check(game.player.exp_to_next() == 36, "First level must be reachable in the opening fight")
	check(game.wave_quota == 14 and game.enemies.size() == 12, "Opening wave should sustain pressure")
	var enemies: Array = []
	for offset in [Vector2(40, 0), Vector2(70, 0), Vector2(500, 0)]:
		var enemy := Enemy.new()
		enemy.world = game.world
		enemy.setup("MINION", 1)
		enemy.position = game.player.position + offset
		game.entities.add_child(enemy)
		enemies.append(enemy)
	game.player.crit_chance = 0.0
	var mana: float = game.player.mana
	var hit = game.player.basic_attack(enemies)
	check(hit != null and enemies[0].hp < enemies[0].max_hp, "Basic attack should damage nearest target")
	check(game.player.mana == mana, "Automatic basic attack must not consume mana")
	check(game.player.basic_attack(enemies) == null, "Cooldown must prevent a second immediate attack")
	RunUpgrades.apply(game.player, "strikes")
	game.player.attack_cd = 0.0
	hit = game.player.basic_attack(enemies)
	check(hit.hits.size() == 2 and enemies[1].hp < enemies[1].max_hp, "Branching upgrade should damage two enemies")
	check(enemies[2].hp == enemies[2].max_hp, "Branching attack must respect range")
	RunUpgrades.apply(game.player, "haste")
	game.player.attack_cd = 0.0
	game.player.basic_attack(enemies)
	check(game.player.attack_cd < Player.ATTACK_CD, "Haste should shorten actual cooldown")
	for i in 5:
		RunUpgrades.apply(game.player, "strikes")
	check(game.player.strike_count == 4, "Upgrade stack limits must be enforced")
	var offers := RunUpgrades.offer(game.player)
	var ids := {}
	for option in offers:
		ids[option.id] = true
		check(option.id != "strikes", "Capped upgrades must leave the offer pool")
	check(offers.size() == 3 and ids.size() == 3, "Offer should contain three distinct choices")
	check(not RunUpgrades.apply(game.player, "invalid"), "Invalid upgrades must be rejected")
	var notices := [0]
	game.player.leveled_up.connect(func(_msg): notices[0] += 1)
	game.player.gain_exp(87)
	await process_frame
	check(notices[0] == 2 and game.player.level == 3, "Large XP grants should enqueue every crossed level")
	check(game.state == game.State.UPGRADE and paused, "Upgrade choice must freeze the game")
	var position: Vector2 = game.player.position
	var cooldown: float = game.player.attack_cd
	for i in 5:
		await process_frame
	check(game.player.position == position and game.player.attack_cd == cooldown, "Movement and cooldowns must freeze during choice")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_1
	key.pressed = true
	game.upgrade_menu._unhandled_key_input(key)
	await process_frame
	check(game._pending_upgrades == 1 and paused, "Keyboard selection should open the next queued choice")
	game.upgrade_menu._choose(0)
	await process_frame
	check(game._pending_upgrades == 0 and not paused and game.state == game.State.PLAY, "Final choice should resume gameplay")
	game.start_game(2, 0, 0, 4242)
	game.player.controlled = false
	check(game.player.strike_count == 1 and game.player.aura_rank == 0 and game.player.run_upgrade_counts.is_empty(), "Restart must reset temporary build")
	await process_frame
	var dash_key := InputEventKey.new()
	dash_key.physical_keycode = KEY_SHIFT
	dash_key.pressed = true
	game._unhandled_input(dash_key)
	game.player.controlled = true
	var start: Vector2 = game.player.position
	game.player._physics_process(1.0 / 60.0)
	check(game.player.dash_cd > 0.0 and game.player.invulnerable_t > 0.0, "Shift should start a protected dash")
	check(game.player.position.distance_to(start) > Player.SPEED / 60.0, "Dash should move faster than walking")
	check(not game.player.try_dash(), "Dash cooldown must block immediate repeat")
	game.player.controlled = false
	game.player.invulnerable_t = 0.0
	var automatic_target := Enemy.new()
	automatic_target.world = game.world
	automatic_target.setup("MINION", 1)
	automatic_target.position = game.player.position + Vector2(35, 0)
	automatic_target.died.connect(game._on_enemy_killed)
	game.entities.add_child(automatic_target)
	game.enemies.append(automatic_target)
	game.player.attack_cd = 0.0
	game._physics_process(1.0 / 60.0)
	check(automatic_target.hp < automatic_target.max_hp, "Gameplay tick must attack without keyboard input")
	var enemy := Enemy.new()
	game.entities.add_child(enemy)
	enemy.setup("MINION", 1)
	enemy.position = game.player.position
	enemy.take_damage(10000)
	game._on_enemy_killed(enemy)
	var kills: int = game.kill_count
	game._on_enemy_killed(enemy)
	check(game.kill_count == kills, "Death signal and attack feedback must not grant duplicate rewards")
	check(game.player.xp == 0, "Solo XP must wait for crystal collection")
	var gems := get_nodes_in_group("xp_gems")
	check(gems.size() == 1, "A defeated enemy should create an XP crystal")
	if not gems.is_empty():
		gems[0]._physics_process(1.0 / 60.0)
	check(game.player.xp == enemy.exp_reward, "Collecting crystal should award exact XP")
	game.player.invulnerable_t = 0.0
	game.player.take_damage(10)
	var hp: int = game.player.hp
	check(game.player.take_damage(10) == 0 and game.player.hp == hp, "Brief protection must prevent overlapping contact hits")
	var a := Node2D.new()
	var b := Node2D.new()
	a.position = game.world.center_px()
	b.position = a.position
	EnemySpacing.separate([a, b], game.world)
	check(a.position.distance_to(b.position) > 0.0, "Exactly overlapping enemies must separate")
	a.free()
	b.free()
	game._set_pause(true)
	check(paused, "Pause must freeze the scene tree")
	game._set_pause(false)
	check(not paused, "Resume must unfreeze the scene tree")
	game.mp = 1
	game.start_game(2, 0, 0, 4242, [0])
	check(not game.player.dash_enabled, "Solo dash must not desync co-op")
	game.player.gain_exp(36)
	await process_frame
	check(game.state == game.State.PLAY and not paused, "Co-op must retain continuous play without solo upgrade dialogs")
	game.mp = 0
	game._enter_menu()
	check(not paused and game.player == null, "Returning to menu must clean up the run")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("SURVIVAL_CHECKS %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
