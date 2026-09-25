class_name HUD
extends Control

## HUD do jogo: barras, gold, minimapa, skills, mensagens, controles.
## Port de UIManager.java para CanvasLayer com _draw.

var main  # Main

var messages: Array = []  # [{base, count, life}]

func _ready() -> void:
	# (tamanho full-rect aplicado pelo criador ANTES do add_child — ver main.gd)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Mensagem repetida não empilha: vira "Sem mana! (2x)", "(3x)"...
func add_message(text: String) -> void:
	for m in messages:
		if m.base == text:
			m.count += 1
			m.life = 1.5
			return
	messages.append({ base = text, count = 1, life = 1.5 })
	while messages.size() > 6:
		messages.pop_front()

func clear_messages() -> void:
	messages.clear()

func _process(delta: float) -> void:
	var i := messages.size() - 1
	while i >= 0:
		messages[i].life -= delta
		if messages[i].life <= 0.0:
			messages.remove_at(i)
		i -= 1
	queue_redraw()

func _draw() -> void:
	if main == null or main.player == null:
		return
	var p: Player = main.player
	var w := size.x
	var h := size.y

	_draw_top_left(p)
	_draw_wave_banner(w)
	_draw_minimap(p, w)
	_draw_skill_bar(p, w, h)
	_draw_messages(w, h)
	_draw_controls(p, h)
	_draw_vignette(p, w, h)

# ---------------------------------------------------------------------
func _draw_top_left(p: Player) -> void:
	var x := 12.0
	var y := 12.0
	var bw := 250.0

	ArtUtil.fill_rrect(self, x - 6, y - 6, bw + 12, 94, 8, Color(0, 0, 0, 0.66))
	ArtUtil.stroke_rrect(self, x - 6, y - 6, bw + 12, 94, 8, Color(1, 1, 1, 0.18), 1)

	var font := ThemeDB.fallback_font
	var label := "%s  •  Lv.%d  •  %s" % [p.champ_name, p.level, ChampData.ROLES[p.role].display]
	draw_string(font, Vector2(x, y + 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

	_bar(x, y + 20, bw, 14, p.hp, p.max_hp, Color(0.2, 0.8, 0.3), "HP", 10)
	var mp_col := Color(0.4, 0.67, 1) if p.channeling else Color(0.27, 0.51, 1)
	if p.channeling:
		var pulse := sin(Time.get_ticks_msec() * 0.01) * 0.3 + 0.7
		draw_rect(Rect2(x - 2, y + 36, bw + 4, 18), Color(0.24, 0.47, 1, 0.25))
		mp_col = Color(0.39, 0.63, pulse)
	_bar(x, y + 38, bw, 14, int(p.mana), p.max_mana, mp_col, "MP", 10)
	_bar(x, y + 56, bw, 10, p.xp, p.exp_to_next(), Color(0.78, 0.67, 0.16), "XP", 9)

	draw_string(font, Vector2(x, y + 80), "◉ %d gold" % p.gold,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.85, 0.25))
	var bank := 0
	if main.get("progress") != null:
		bank = StageData.essence(main.get("progress"))
	EssenceIcon.draw_crystal(self, Vector2(x + 136, y + 74), 8.0)
	draw_string(font, Vector2(x + 148, y + 80), "%d" % bank,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.85, 1))

	# Aliado co-op (P2 compacto).
	if main.get("player2") != null:
		var q: Player = main.get("player2")
		if q != null and is_instance_valid(q):
			var ay := y + 96.0
			ArtUtil.fill_rrect(self, x - 6, ay - 6, bw + 12, 40, 8, Color(0, 0, 0, 0.66))
			ArtUtil.stroke_rrect(self, x - 6, ay - 6, bw + 12, 40, 8, Color(0.4, 0.9, 1, 0.5), 1)
			draw_string(font, Vector2(x, ay + 10), "P2 %s  •  Lv.%d" % [q.champ_name, q.level],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.9, 1))
			var hr := clampf(q.hp / float(maxi(1, q.max_hp)), 0.0, 1.0)
			draw_rect(Rect2(x, ay + 16, bw, 7), Color(0, 0, 0, 0.85))
			draw_rect(Rect2(x, ay + 16, bw * hr, 7), Color(0.2, 0.8, 0.3))
			var mr := clampf(float(q.mana) / float(maxi(1, q.max_mana)), 0.0, 1.0)
			draw_rect(Rect2(x, ay + 25, bw, 5), Color(0, 0, 0, 0.85))
			draw_rect(Rect2(x, ay + 25, bw * mr, 5), Color(0.27, 0.51, 1))

	if p.channeling:
		draw_string(font, Vector2(x, y + 93), "✦ CANALIZANDO — você está enraizado! ✦",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.55, 0.78, 1))

func _bar(x: float, y: float, w: float, h: float, cur: int, mx: int,
		col: Color, caption: String, fsize: int) -> void:
	draw_rect(Rect2(x, y, w, h), Color(0, 0, 0, 0.85))
	var ratio := clampf(cur / float(maxi(1, mx)), 0.0, 1.0)
	draw_rect(Rect2(x, y, w * ratio, h), col)
	draw_rect(Rect2(x, y, w, h), Color(1, 1, 1, 0.7), false, 1.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(x + 4, y + h - 3), "%s %d/%d" % [caption, cur, mx],
		HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color.WHITE)

# ---------------------------------------------------------------------
func _draw_wave_banner(screen_w: float) -> void:
	# Faixa da onda/fase/dificuldade + progresso + alerta de boss.
	var font := ThemeDB.fallback_font
	var gw := 1
	var wave_txt := ""
	var prog := 0.0
	var diff_col := Color.WHITE
	var boss_alive := false
	var mini_alive := false
	if main.get("wave_quota") != null:
		gw = StageData.global_wave(int(main.get("cur_stage")), int(main.get("wave_idx")))
		var quota := int(main.get("wave_quota"))
		var killed := int(main.get("wave_killed"))
		var active := bool(main.get("wave_active"))
		var stage := int(main.get("cur_stage"))
		var diff := int(main.get("cur_diff"))
		var widx := int(main.get("wave_idx"))
		var dd: Dictionary = StageData.DIFFS[clampi(diff, 0, StageData.DIFFS.size() - 1)]
		diff_col = dd.get("color", Color.WHITE)
		wave_txt = "%s %d/5 • %s • %d/15" % [StageData.stage_name(stage), widx + 1, StageData.diff_name(diff), gw]
		if quota > 0:
			prog = clampf(killed / float(quota), 0.0, 1.0)
		if not active and killed >= quota:
			wave_txt = "Próxima onda em %ds..." % maxi(0, int(main.get("between_timer")) + 1)
		for e in main.enemies:
			if not is_instance_valid(e) or not e.is_alive():
				continue
			if e.is_boss():
				boss_alive = true
			elif e.is_miniboss():
				mini_alive = true
			if boss_alive and mini_alive:
				break
	var secs := int(main.game_time)
	var mm := int(secs / 60.0)
	var ss := secs % 60
	var txt := "☠ %d   ⏱ %02d:%02d" % [main.kill_count, mm, ss]
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var x := screen_w / 2.0 - 90
	ArtUtil.fill_rrect(self, x, 10, 180, 52, 8, Color(0, 0, 0, 0.62))
	draw_string(font, Vector2(screen_w / 2.0 - tw / 2, 28), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	var tw2 := font.get_string_size(wave_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(screen_w / 2.0 - tw2 / 2, 44), wave_txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, diff_col)
	# Barra de progresso da onda.
	draw_rect(Rect2(x + 12, 48, 156, 6), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(x + 12, 48, 156 * prog, 6), diff_col)
	draw_rect(Rect2(x + 12, 48, 156, 6), Color(1, 1, 1, 0.35), false, 1.0)
	_draw_boss_bar(screen_w)
	if boss_alive:
		var pulse := sin(Time.get_ticks_msec() * 0.012) * 0.5 + 0.5
		var warn := "★ BOSS NA ARENA ★"
		var tww := font.get_string_size(warn, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var wy := 78.0
		ArtUtil.fill_rrect(self, screen_w / 2.0 - tww / 2 - 10, wy - 15, tww + 20, 22, 8,
			Color(0.45, 0.05, 0.1, 0.55 + 0.3 * pulse))
		draw_string(font, Vector2(screen_w / 2.0 - tww / 2, wy), warn,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.4 + 0.4 * pulse, 0.35))
	elif mini_alive:
		var pulse := sin(Time.get_ticks_msec() * 0.012) * 0.5 + 0.5
		var warn := "👹 MINI-BOSS NA ARENA"
		var tww := font.get_string_size(warn, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var wy := 78.0
		ArtUtil.fill_rrect(self, screen_w / 2.0 - tww / 2 - 10, wy - 15, tww + 20, 22, 8,
			Color(0.4, 0.15, 0.03, 0.55 + 0.3 * pulse))
		draw_string(font, Vector2(screen_w / 2.0 - tww / 2, wy), warn,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.55 + 0.25 * pulse, 0.25))

# ---------------------------------------------------------------------
func _draw_boss_bar(screen_w: float) -> void:
	# Maior ameaça viva (boss primeiro, senão mini-boss).
	var foe = null
	for e in main.enemies:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		if e.is_boss():
			foe = e
			break
		elif e.is_miniboss() and foe == null:
			foe = e
	if foe == null:
		return
	var font := ThemeDB.fallback_font
	var bw := 240.0
	var bx := screen_w / 2.0 - bw / 2.0
	var by := 96.0
	var is_boss: bool = foe.is_boss()
	var col := Color(0.75, 0.2, 0.9) if is_boss else Color(1.0, 0.45, 0.1)
	var label := "%s %s Lv.%d" % ["★ BOSS" if is_boss else "👹 MINI-BOSS", foe.type_name, foe.level]
	ArtUtil.fill_rrect(self, bx - 8, by - 4, bw + 16, 34, 8, Color(0, 0, 0, 0.62))
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(screen_w / 2.0 - tw / 2, by + 10), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
	var ratio := clampf(foe.hp / float(maxi(1, foe.max_hp)), 0.0, 1.0)
	draw_rect(Rect2(bx, by + 16, bw, 7), Color(0, 0, 0, 0.85))
	draw_rect(Rect2(bx, by + 16, bw * ratio, 7), col)
	draw_rect(Rect2(bx, by + 16, bw, 7), Color(1, 1, 1, 0.4), false, 1.0)

# ---------------------------------------------------------------------
func _draw_minimap(p: Player, screen_w: float) -> void:
	var mm := 140.0
	var mx := screen_w - mm - 12
	var my := 12.0
	var world: World = main.world
	if world == null:
		return
	var sx := mm / world.world_size().x
	var sy := mm / world.world_size().y

	ArtUtil.fill_rrect(self, mx - 4, my - 4, mm + 8, mm + 8, 8, Color(0, 0, 0, 0.66))
	draw_rect(Rect2(mx, my, mm, mm), Color(0.1, 0.25, 0.12))

	if main.minimap_tex != null:
		draw_texture_rect(main.minimap_tex, Rect2(mx, my, mm, mm), false)

	for e in main.enemies:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var pos := Vector2(mx + e.position.x * sx, my + e.position.y * sy)
		if e.is_boss():
			draw_circle(pos, 4.5, Color(0.85, 0.2, 0.95))
			draw_arc(pos, 4.5, 0, TAU, 12, Color(1, 0.85, 0.3), 1.5)
		elif e.is_miniboss():
			draw_circle(pos, 4.0, Color(1, 0.35, 0.1))
			draw_arc(pos, 4.0, 0, TAU, 12, Color(1, 0.7, 0.3), 1.2)
		elif e.get("is_elite") and bool(e.get("is_elite")):
			draw_circle(pos, 3.5, Color(1, 0.6, 0.2))
		else:
			draw_circle(pos, 2.5, Color(1, 0.25, 0.2))

	draw_circle(Vector2(mx + p.position.x * sx, my + p.position.y * sy), 3.5, Color.WHITE)
	if main.get("player2") != null:
		var q2: Player = main.get("player2")
		if q2 != null and is_instance_valid(q2) and q2.is_alive():
			draw_circle(Vector2(mx + q2.position.x * sx, my + q2.position.y * sy), 3.5, Color(0.4, 0.9, 1))
	ArtUtil.stroke_rrect(self, mx - 4, my - 4, mm + 8, mm + 8, 8, Color(0.5, 0.5, 0.5), 1)

# ---------------------------------------------------------------------
func _draw_skill_bar(p: Player, screen_w: float, screen_h: float) -> void:
	var box := 52.0
	var gap := 6.0
	var max_slots: int = ChampData.SKILL_SLOTS
	var shown_locked := maxi(0, max_slots - p.skills.size())
	var total := 1 + p.skills.size() + shown_locked
	var start_x := screen_w / 2.0 - (total * (box + gap) - gap) / 2.0
	var y := screen_h - box - 14
	var font := ThemeDB.fallback_font

	ArtUtil.fill_rrect(self, start_x - 10, y - 10,
		total * (box + gap) - gap + 20, box + 20, 10, Color(0, 0, 0, 0.66))

	# slot ataque básico
	var ready_a := p.attack_cd <= 0.0 and not p.channeling
	ArtUtil.fill_rrect(self, start_x, y, box, box, 6,
		Color(0.24, 0.24, 0.12) if ready_a else Color(0.16, 0.12, 0.12))
	ArtUtil.stroke_rrect(self, start_x, y, box, box, 6,
		Color(1, 0.85, 0.2) if ready_a else Color(0.5, 0.5, 0.5), 2.0 if ready_a else 1.5)
	var atk_col := Color(1, 0.86, 0.32) if ready_a else Color(0.47, 0.47, 0.47)
	_center_str("ATK", start_x, box, y + 12, 10, atk_col, font)
	SkillIcon.draw_basic(self, p.role, Vector2(start_x + box / 2.0, y + box / 2.0 + 3), 13.0, ready_a)
	_center_str(_key("attack"), start_x, box, y + box - 5, 10, Color(1, 0.85, 0.2), font)
	if p.attack_cd > 0.0:
		var ratio := clampf(p.attack_cd / (22.0 / 60.0), 0.0, 1.0)
		var ch := box * ratio
		draw_rect(Rect2(start_x, y, box, ch), Color(0, 0, 0, 0.67))
		draw_rect(Rect2(start_x, y + ch - 1, box, 1), Color(1, 1, 0.4, 0.7))
		_center_str("%.1f" % p.attack_cd, start_x, box, y + box / 2 + 5, 14, Color.WHITE, font)

	# skills desbloqueadas (ícone + borda na cor da raridade)
	for i in p.skills.size():
		var s: Dictionary = p.skills[i]
		var cfg: Dictionary = s.cfg
		var bx := start_x + (i + 1) * (box + gap)
		var can: bool = s.cd_left <= 0.0 and p.mana >= cfg.mana
		var rcol := ChampData.rarity_color(int(cfg.get("rarity", 0)))
		ArtUtil.fill_rrect(self, bx, y, box, box, 6,
			Color(0.16, 0.24, 0.16) if can else Color(0.16, 0.12, 0.12))
		var bw := 2.0 if can else 1.5
		var bcol: Color = rcol if can else Color(0.5, 0.5, 0.5)
		if can and int(cfg.get("rarity", 0)) >= 4:
			var upulse := sin(Time.get_ticks_msec() * 0.008) * 0.5 + 0.5
			bcol = Color(1, 0.85, 0.3, 0.6 + 0.4 * upulse)
			bw = 3.0
		ArtUtil.stroke_rrect(self, bx, y, box, box, 6, bcol, bw)
		var center := Vector2(bx + box / 2.0, y + box / 2.0 + 2)
		if can:
			var gpulse := sin(Time.get_ticks_msec() * 0.006 + i) * 0.5 + 0.5
			draw_circle(center, 17.0 + gpulse * 2.0, Color(rcol, 0.16))
		SkillIcon.draw_icon(self, p.role, str(cfg.get("kind", "damage")), i, center, 13.0, not can)
		draw_string(font, Vector2(bx + 4, y + 12), str(i + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.85, 0.2))
		draw_string(font, Vector2(bx + 4, y + box - 5), "%dmp" % cfg.mana,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.31, 0.55, 1))
		if s.cd_left > 0.0:
			var ratio := clampf(s.cd_left / maxf(0.01, cfg.cd), 0.0, 1.0)
			var ch := box * ratio
			draw_rect(Rect2(bx, y, box, ch), Color(0, 0, 0, 0.67))
			draw_rect(Rect2(bx, y + ch - 1, box, 1), Color(0.4, 0.78, 1, 0.7))
			_center_str(str(int(ceil(s.cd_left))), bx, box, y + box / 2 + 5, 14, Color.WHITE, font)
	# slots bloqueados (desbloqueie no menu com ◆)
	for j in shown_locked:
		var idx := p.skills.size() + j
		var bx := start_x + (idx + 1) * (box + gap)
		ArtUtil.fill_rrect(self, bx, y, box, box, 6, Color(0.08, 0.08, 0.1))
		ArtUtil.stroke_rrect(self, bx, y, box, box, 6, Color(0.3, 0.3, 0.35), 1.0)
		_center_str("🔒", bx, box, y + 28, 16, Color(0.5, 0.5, 0.55), font)
		_center_str(str(idx + 1), bx, box, y + box - 5, 10, Color(0.5, 0.5, 0.55), font)

# ---------------------------------------------------------------------
func _draw_messages(screen_w: float, screen_h: float) -> void:
	var font := ThemeDB.fallback_font
	var y := screen_h / 3.0
	for m in messages:
		var alpha: float = clampf(m.life / 0.5, 0.0, 1.0)
		var txt: String = m.base if int(m.count) <= 1 else "%s (%dx)" % [m.base, int(m.count)]
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(font, Vector2(screen_w / 2.0 - tw / 2 + 1, y + 1), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0, alpha * 0.7))
		draw_string(font, Vector2(screen_w / 2.0 - tw / 2, y), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 0.4, alpha))
		y += 22.0

func _draw_controls(p: Player, screen_h: float) -> void:
	var font := ThemeDB.fallback_font
	var txt := ""
	var col: Color
	if p.channeling:
		txt = "✦ CANALIZANDO — você está PARADO! Pressione %s para sair ✦" % _key("channel")
		col = Color(0.55, 0.78, 1, 0.85)
	else:
		txt = "%s: mover | %s: soco | 1-%d: skills | %s: mana | %s: item | %s: loja | %s: pausa" % [
			_key("move_up").to_upper() + _key("move_left").to_upper() + _key("move_down").to_upper() + _key("move_right").to_upper(),
			_key("attack"), maxi(1, p.skills.size()), _key("channel"), _key("item"), _key("shop"), _key("pause")]
		col = Color(1, 1, 1, 0.5)
	draw_string(font, Vector2(14, screen_h - 6), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)

## Vinheta vermelha pulsante quando o HP está baixo.
func _draw_vignette(p: Player, w: float, h: float) -> void:
	if p.max_hp <= 0:
		return
	var ratio := clampf(p.hp / float(p.max_hp), 0.0, 1.0)
	if ratio >= 0.35:
		return
	var pulse := sin(Time.get_ticks_msec() * 0.009) * 0.5 + 0.5
	var a := (0.35 - ratio) / 0.35 * (0.25 + 0.35 * pulse)
	var t := 10.0
	var col := Color(0.8, 0.05, 0.1, a)
	draw_rect(Rect2(0, 0, w, t), col)
	draw_rect(Rect2(0, h - t, w, t), col)
	draw_rect(Rect2(0, 0, t, h), col)
	draw_rect(Rect2(w - t, 0, t, h), col)

func _key(action_id: String) -> String:
	if main.get("settings") == null:
		return "?"
	return GameSettings.key_label(main.get("settings"), action_id)

func _center_str(txt: String, bx: float, bw: float, y: float, fsize: int,
		col: Color, font: Font) -> void:
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	draw_string(font, Vector2(bx + (bw - tw) / 2.0, y), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
