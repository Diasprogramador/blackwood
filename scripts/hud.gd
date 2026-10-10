class_name HUD
extends Control

## HUD do jogo: barras, gold, minimapa, skills, mensagens, controles.
## Port de UIManager.java para CanvasLayer com _draw.

var main  # Main

var messages: Array = []  # [{base, count, life}]
var _redraw_t := 0.0

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
	while messages.size() > 3:
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
	# Fora da qualidade Alta, redesenha a 30Hz (barras e cooldowns suaves).
	# Nada de queue_redraw vindo de fora: quem manda no ritmo é este throttle.
	if not visible:
		return
	_redraw_t += delta
	var interval := 1.0 / 60.0 if GameSettings.quality_cache <= 0 else 1.0 / 30.0
	if _redraw_t >= interval:
		_redraw_t = 0.0
		queue_redraw()

func _draw() -> void:
	if main == null or main.player == null:
		return
	var p: Player = main.player
	var w := size.x
	var h := size.y

	_draw_top_left(p)
	_draw_wave_banner(w)
	_draw_banner(w, h)
	_draw_minimap(p, w)
	_draw_skill_bar(p, w, h)
	_draw_messages(w, h)
	_draw_controls(p, h)
	_draw_vignette(p, w, h)
	_draw_fps(w)

# ---------------------------------------------------------------------
func _draw_top_left(p: Player) -> void:
	var x := 20.0
	var y := 20.0
	var bw := 264.0
	var card_h := 130.0 if p.channeling else 110.0
	ForestUI.frame(self, Rect2(x - 8, y - 8, bw + 16, card_h), ForestUI.MINT)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(x, y + 13), p.champ_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ForestUI.PAPER)
	draw_string(font, Vector2(x + 188, y + 13), "NÍVEL %02d" % p.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ForestUI.GOLD)
	_bar(x, y + 23, bw, 18, p.hp, p.max_hp, ForestUI.MINT, "VIDA", 11)
	_bar(x, y + 45, bw, 12, int(p.mana), p.max_mana, Color("7fbad8"), "MANA", 10)
	_bar(x, y + 61, bw, 10, p.xp, p.exp_to_next(), ForestUI.GOLD, "XP", 9)
	draw_string(font, Vector2(x, y + 90), "%d OURO" % p.gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ForestUI.GOLD)
	var bank := StageData.essence(main.progress) if main.get("progress") != null else 0
	draw_string(font, Vector2(x + 130, y + 90), "%d ESSÊNCIA" % bank, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("98cbd4"))
	if p.channeling:
		draw_string(font, Vector2(x, y + 112), "RECUPERANDO MANA • IMÓVEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("98cbd4"))

	# Aliados co-op (P2..P4 compactos), ancorados no RODAPÉ do cartão.
	if main.get("allies") != null:
		var idx := 0
		for q in (main.get("allies") as Array):
			idx += 1
			if q == null or not is_instance_valid(q):
				continue
			var qp: Player = q
			var ay := y + card_h + 2.0 + float(idx - 1) * 42.0
			ArtUtil.fill_rrect(self, x - 6, ay - 6, bw + 12, 40, 8, Color(0, 0, 0, 0.66))
			ArtUtil.stroke_rrect(self, x - 6, ay - 6, bw + 12, 40, 8, Color(0.4, 0.9, 1, 0.5), 1)
			draw_string(font, Vector2(x, ay + 10), "P%d %s  •  Lv.%d" % [idx + 1, qp.champ_name, qp.level],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.9, 1))
			var hr := clampf(qp.hp / float(maxi(1, qp.max_hp)), 0.0, 1.0)
			draw_rect(Rect2(x, ay + 16, bw, 7), Color(0, 0, 0, 0.85))
			draw_rect(Rect2(x, ay + 16, bw * hr, 7), Color(0.2, 0.8, 0.3))
			var mr := clampf(float(qp.mana) / float(maxi(1, qp.max_mana)), 0.0, 1.0)
			draw_rect(Rect2(x, ay + 25, bw, 5), Color(0, 0, 0, 0.85))
			draw_rect(Rect2(x, ay + 25, bw * mr, 5), Color(0.27, 0.51, 1))

func _bar(x: float, y: float, w: float, h: float, cur: int, mx: int,
		col: Color, caption: String, fsize: int) -> void:
	draw_rect(Rect2(x, y, w, h), Color(0, 0, 0, 0.85))
	var ratio := clampf(cur / float(maxi(1, mx)), 0.0, 1.0)
	draw_rect(Rect2(x, y, floorf(w * ratio), h), col)
	draw_rect(Rect2(x, y, floorf(w * ratio), 2), col.lightened(0.3))
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
	var txt := "%d ABATES   /   %02d:%02d" % [main.kill_count, mm, ss]
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var tw2 := font.get_string_size(wave_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	# A caixa tinha 180 fixo: "Floresta Verde 3/5 • Difícil • 12/15" passa
	# de 200px e o texto vazava para fora do fundo.
	var bw2 := maxf(180.0, maxf(tw, tw2) + 26.0)
	var x := screen_w / 2.0 - bw2 / 2.0
	ForestUI.frame(self, Rect2(x, 10, bw2, 52))
	draw_string(font, Vector2(screen_w / 2.0 - tw / 2, 28), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_string(font, Vector2(screen_w / 2.0 - tw2 / 2, 44), wave_txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, diff_col)
	# Barra de progresso da onda.
	draw_rect(Rect2(x + 12, 48, bw2 - 24, 6), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(x + 12, 48, (bw2 - 24) * prog, 6), diff_col)
	draw_rect(Rect2(x + 12, 48, bw2 - 24, 6), Color(1, 1, 1, 0.35), false, 1.0)
	_draw_skip_hint(screen_w, font)
	_draw_boss_bar(screen_w)
	if boss_alive:
		var pulse := sin(Time.get_ticks_msec() * 0.012) * 0.5 + 0.5
		var warn := "★ BOSS NA ARENA ★"
		var tww := font.get_string_size(warn, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var wy := 148.0
		ArtUtil.fill_rrect(self, screen_w / 2.0 - tww / 2 - 10, wy - 15, tww + 20, 22, 8,
			Color(0.45, 0.05, 0.1, 0.55 + 0.3 * pulse))
		draw_string(font, Vector2(screen_w / 2.0 - tww / 2, wy), warn,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.4 + 0.4 * pulse, 0.35))
	elif mini_alive:
		var pulse := sin(Time.get_ticks_msec() * 0.012) * 0.5 + 0.5
		var warn := "👹 MINI-BOSS NA ARENA"
		var tww := font.get_string_size(warn, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var wy := 148.0
		ArtUtil.fill_rrect(self, screen_w / 2.0 - tww / 2 - 10, wy - 15, tww + 20, 22, 8,
			Color(0.4, 0.15, 0.03, 0.55 + 0.3 * pulse))
		draw_string(font, Vector2(screen_w / 2.0 - tww / 2, wy), warn,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.55 + 0.25 * pulse, 0.25))

# ---------------------------------------------------------------------
func _draw_skip_hint(screen_w: float, font: Font) -> void:
	# Mostra quando o pulo de onda libera (50% da cota).
	if main == null or not main.has_method("can_skip_wave"):
		return
	if not bool(main.get("wave_active")):
		return
	var quota := int(main.get("wave_quota"))
	if quota <= 0:
		return
	var txt := ""
	var col := Color(1, 0.85, 0.2, 0.9)
	if bool(main.can_skip_wave()):
		txt = "⏭ %s = pular onda!" % _key("skip")
	else:
		var need := maxi(0, int(main.skip_threshold()) - int(main.get("wave_killed")))
		txt = "⏭ pular em %d kills" % need
		col = Color(1, 1, 1, 0.55)
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(font, Vector2(screen_w / 2.0 - tw / 2, 73), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)

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
func _draw_banner(screen_w: float, screen_h: float) -> void:
	var t: float = main.wave_banner_t
	if t <= 0.0:
		return
	var txt := str(main.wave_banner_txt)
	if txt == "":
		return
	var font := ThemeDB.fallback_font
	var a := clampf(t / 0.8, 0.0, 1.0)
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x
	var pos := Vector2(screen_w / 2.0 - tw / 2.0, screen_h * 0.38)
	draw_string(font, pos + Vector2(3, 3), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(0, 0, 0, a * 0.85))
	draw_string(font, pos, txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(1, 0.85, 0.3, a))

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

	ForestUI.frame(self, Rect2(mx - 6, my - 6, mm + 12, mm + 12), ForestUI.MINT)
	draw_rect(Rect2(mx, my, mm, mm), Color(0.1, 0.25, 0.12))

	if main.minimap_tex != null:
		draw_texture_rect(main.minimap_tex, Rect2(mx, my, mm, mm), false)

	for e in main.enemies:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		# Sem clamp os pontinhos vazavam por cima da moldura e da tela.
		var pos := _mm_clamp(Vector2(mx + e.position.x * sx, my + e.position.y * sy), mx, my, mm)
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

	draw_circle(_mm_clamp(Vector2(mx + p.position.x * sx, my + p.position.y * sy), mx, my, mm),
		3.5, Color.WHITE)
	if main.get("allies") != null:
		for q2 in (main.get("allies") as Array):
			if q2 != null and is_instance_valid(q2) and (q2 as Player).is_alive():
				var qp: Player = q2
				draw_circle(_mm_clamp(Vector2(mx + qp.position.x * sx, my + qp.position.y * sy),
					mx, my, mm), 3.5, Color(0.4, 0.9, 1))
	draw_rect(Rect2(mx, my, mm, mm), ForestUI.EDGE, false, 2)

func _mm_clamp(p: Vector2, mx: float, my: float, mm: float) -> Vector2:
	return Vector2(clampf(p.x, mx + 4.0, mx + mm - 4.0), clampf(p.y, my + 4.0, my + mm - 4.0))

# ---------------------------------------------------------------------
func _draw_skill_bar(p: Player, screen_w: float, screen_h: float) -> void:
	# Barra desligável + some sozinha com touch (botões já mostram tudo).
	if main.get("settings") != null and not bool(main.get("settings").get("hud_bar", true)):
		return
	if main.touch_ui != null and main.touch_ui.visible:
		return
	var box := 52.0
	var gap := 6.0
	var max_slots: int = ChampData.SKILL_SLOTS
	var shown_locked := maxi(0, max_slots - p.skills.size())
	var total := 1 + p.skills.size() + shown_locked
	var start_x := screen_w / 2.0 - (total * (box + gap) - gap) / 2.0
	# Deixa folga para a linha de atalhos do rodapé: com -14 o fundo da barra
	# terminava em screen_h-4 e tapava o texto.
	var y := screen_h - box - 34
	var font := ThemeDB.fallback_font

	ForestUI.frame(self, Rect2(start_x - 10, y - 10, total * (box + gap) - gap + 20, box + 20))
	if p.dash_enabled:
		var dx := start_x + total * (box + gap) + 12
		ForestUI.frame(self, Rect2(dx, y, 68, box), ForestUI.MINT)
		_center_str(_key("dash").to_upper(), dx, 68, y + 19, 11, ForestUI.PAPER, font)
		_center_str("ESQUIVA" if p.dash_cd <= 0.0 else "%.1fs" % p.dash_cd, dx, 68, y + 37, 10, ForestUI.MINT, font)
		draw_rect(Rect2(dx + 6, y + 43, 56 * (1.0 - clampf(p.dash_cd / 1.6, 0, 1)), 3), ForestUI.MINT)

	# slot ataque básico
	var ready_a := p.attack_cd <= 0.0 and not p.channeling
	SkillIcon.draw_slot_bg(self, start_x, y, box, box,
		Color(1, 0.85, 0.2), ready_a, Color(1, 0.86, 0.32))
	var atk_col := Color(1, 0.86, 0.32) if ready_a else Color(0.47, 0.47, 0.47)
	_center_str("ATK", start_x, box, y + 12, 10, atk_col, font)
	SkillIcon.draw_basic(self, p.role, Vector2(start_x + box / 2.0, y + box / 2.0 + 3), 13.0, ready_a)
	_center_str("AUTO", start_x, box, y + box - 5, 10, Color(1, 0.85, 0.2), font)
	if p.attack_cd > 0.0:
		var ratio := clampf(p.attack_cd / (Player.ATTACK_CD / p.attack_speed_mult), 0.0, 1.0)
		var ch := box * ratio
		draw_rect(Rect2(start_x, y, box, ch), Color(0, 0, 0, 0.67))
		draw_rect(Rect2(start_x, y + ch - 1, box, 1), Color(1, 1, 0.4, 0.7))
		_center_str("%.1f" % p.attack_cd, start_x, box, y + box / 2 + 5, 14, Color.WHITE, font)

	# skills desbloqueadas (placa com gradiente + borda na cor da raridade)
	for i in p.skills.size():
		var s: Dictionary = p.skills[i]
		var cfg: Dictionary = s.cfg
		var bx := start_x + (i + 1) * (box + gap)
		var can: bool = s.cd_left <= 0.0 and p.mana >= cfg.mana
		var rcol := ChampData.rarity_color(int(cfg.get("rarity", 0)))
		var bcol: Color = rcol if can else Color(0.5, 0.5, 0.5)
		if can and int(cfg.get("rarity", 0)) >= 4:
			var upulse := sin(Time.get_ticks_msec() * 0.008) * 0.5 + 0.5
			bcol = Color(1, 0.85, 0.3, 0.6 + 0.4 * upulse)
		SkillIcon.draw_slot_bg(self, bx, y, box, box, bcol, can, rcol)
		var center := Vector2(bx + box / 2.0, y + box / 2.0 + 2)
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
		_center_str("—", bx, box, y + 28, 16, Color(0.5, 0.5, 0.55), font)
		_center_str(str(idx + 1), bx, box, y + box - 5, 10, Color(0.5, 0.5, 0.55), font)

# ---------------------------------------------------------------------
func _draw_messages(screen_w: float, screen_h: float) -> void:
	var font := ThemeDB.fallback_font
	var y := screen_h - 140.0
	for m in messages:
		var alpha: float = clampf(m.life / 0.5, 0.0, 1.0)
		var txt: String = m.base if int(m.count) <= 1 else "%s (%dx)" % [m.base, int(m.count)]
		draw_string(font, Vector2(19, y + 1), txt,
			HORIZONTAL_ALIGNMENT_LEFT, screen_w - 40, 14, Color(0, 0, 0, alpha * 0.7))
		draw_string(font, Vector2(18, y), txt,
			HORIZONTAL_ALIGNMENT_LEFT, screen_w - 40, 14, Color(0.8, 0.95, 0.75, alpha))
		y += 22.0

func _draw_controls(p: Player, screen_h: float) -> void:
	if main.touch_active():
		return
	var font := ThemeDB.fallback_font
	var txt := ""
	var col: Color
	if p.channeling:
		txt = "✦ CANALIZANDO — você está PARADO! Pressione %s para sair ✦" % _key("channel")
		col = Color(0.55, 0.78, 1, 0.85)
	else:
		txt = "%s: mover | ATK automático (%s) | 1-%d: skills | %s: mana | %s: item | %s: loja | %s: pausa | %s: pular (50%%)" % [
			_key("move_up").to_upper() + _key("move_left").to_upper() + _key("move_down").to_upper() + _key("move_right").to_upper(),
			_key("attack"), maxi(1, p.skills.size()), _key("channel"), _key("item"), _key("shop"), _key("pause"), _key("skip")]
		col = Color(1, 1, 1, 0.5)
		if p.dash_enabled:
			txt += " | %s: esquiva" % _key("dash")
	# Encaixa na largura da tela: sem isso a linha estourava a borda direita
	# em resoluções estreitas (draw_string não quebra linha sozinho).
	var fsize := 11
	var avail := size.x - 28.0
	while fsize > 8 and font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > avail:
		fsize -= 1
	draw_string(font, Vector2(14, screen_h - 6), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)

## Vinheta vermelha pulsante quando o HP está baixo.
## Moldura contínua (16 camadas finas) em vez de 4 barras chapadas de 10px.
func _draw_vignette(p: Player, w: float, h: float) -> void:
	if p.max_hp <= 0:
		return
	var ratio := clampf(p.hp / float(p.max_hp), 0.0, 1.0)
	if ratio >= 0.35:
		return
	var pulse := sin(Time.get_ticks_msec() * 0.009) * 0.5 + 0.5
	var a := (0.35 - ratio) / 0.35 * (0.22 + 0.30 * pulse)
	ArtUtil.frame_vignette(self, Vector2(w, h), 52.0, Color(0.8, 0.05, 0.1), a, 16)

## Cantinho de FPS (ativável nas configurações).
func _draw_fps(w: float) -> void:
	if main.get("settings") == null or not bool(main.get("settings").get("show_fps", false)):
		return
	var font := ThemeDB.fallback_font
	var txt := "%d FPS" % Engine.get_frames_per_second()
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	# Alinhado à direita da moldura do minimapa (o valor cresce e encolhe).
	draw_string(font, Vector2(w - 16 - tw, 170), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.6))

func _key(action_id: String) -> String:
	if main.get("settings") == null:
		return "?"
	return GameSettings.key_label(main.get("settings"), action_id)

func _center_str(txt: String, bx: float, bw: float, y: float, fsize: int,
		col: Color, font: Font) -> void:
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	draw_string(font, Vector2(bx + (bw - tw) / 2.0, y), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
