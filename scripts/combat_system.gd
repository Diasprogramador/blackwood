class_name CombatSystem
extends Object

## Port de CombatSystem.java — utilitários estáticos de combate.

enum CombatResult { VICTORY, DEFEAT, FLED }

## Combate 1v1 básico por turnos (equivalente ao console Java).
## Retorna CombatResult.
static func single_combat(player, enemy) -> int:
	print("\n=== COMBATE 1v1 ===")
	var round := 1

	while player.is_alive() and enemy.is_alive():
		print("\n--- Round %d ---" % round)
		_display_status(player)
		_display_enemy_info(enemy)

		# Jogador ataca
		player.basic_attack(enemy)

		if not enemy.is_alive():
			break

		# Inimigo ataca (berserk quando HP baixo, como no Enemy.takeTurn)
		var raw: int
		if enemy.hp < enemy.max_hp / 2.0:
			raw = int(enemy.calc_damage() * 1.5)
		else:
			raw = enemy.calc_damage()
		player.take_damage(raw)

		# Regeneração e cooldowns
		var per_frame := maxi(1, int(player.mana_regen + player.level * 0.3))
		player.restore_mana(per_frame)
		for s in player.skills:
			if s is Skill:
				s.reduce_cooldown()
			elif s is Dictionary and s.has("cd_left"):
				s.cd_left = maxf(0.0, s.cd_left - 1.0 / 60.0)

		round += 1

	if player.is_alive():
		return CombatResult.VICTORY
	return CombatResult.DEFEAT

## Cálculo de dano (utilitário estático).
static func calculate_damage(attack: int, defense: int) -> int:
	var reduction := defense / float(defense + 100)
	var base_damage := int(attack * (1.0 - reduction))
	return maxi(1, base_damage)

## Cálculo de cura.
static func calculate_heal(magic: int, base_heal: int) -> int:
	return magic + base_heal

## Exibe opções de habilidade do player.
static func display_skill_options(player) -> void:
	print("\nHabilidades disponiveis:")
	var skills: Array = player.skills
	for i in skills.size():
		var s = skills[i]
		if s is Skill:
			var status := "[PRONTO]" if s.can_use(player) else "[INDISP.]"
			print("  [%d] %s (MP: %d) - CD: %d %s" % [
				i + 1, s.get_name(), s.get_mana_cost(),
				s.get_current_cooldown(), status,
			])
		elif s is Dictionary:
			var cfg: Dictionary = s.get("cfg", s)
			print("  [%d] %s (MP: %d) - CD: %.1fs" % [
				i + 1, cfg.get("name", "?"),
				int(cfg.get("mana", 0)), float(s.get("cd_left", 0.0)),
			])

static func _display_status(p) -> void:
	print("  %-15s Lv.%-3d | HP: %d/%d | MP: %d/%d" % [
		p.champ_name, p.level, p.hp, p.max_hp, int(p.mana), p.max_mana,
	])

static func _display_enemy_info(e) -> void:
	print("  %s | HP: %d/%d | ATK: %d | DEF: %d" % [
		e.type_name, e.hp, e.max_hp, e.attack, e.defense,
	])
