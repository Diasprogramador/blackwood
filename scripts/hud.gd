class_name HUD
extends Control

## HUD do jogo: barras, gold, minimapa, skills, mensagens, controles.
## Port de UIManager.java para CanvasLayer com _draw.

var main  # Main

var messages: Array = []  # [{base, count, life}]
var _redraw_t := 0.0
var _hp_trail := -1.0
var _portrait: TextureRect
var _portrait_role := ""
var _actions: Dictionary = {}
var _last_player: Player
var _hovered := ""

func _ready() -> void:
	# (tamanho full-rect aplicado pelo criador ANTES do add_child — ver main.gd)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait = TextureRect.new()
	_portrait.position = Vector2(12,16)
	_portrait.size = Vector2(76,72)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.material = CanvaSprites.material()
	add_child(_portrait)
	for action in ["attack","skill1","skill2","skill3","skill4","skill5","dash","item","channel","shop","pause","skip"]:
		var button := Button.new()
		button.name = action
		for state in ["normal","hover","pressed","focus","disabled"]:
			button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.pressed.connect(func():
			if main != null: main.hud_action(action)
		)
		button.mouse_entered.connect(func(): _hovered = action)
		button.mouse_exited.connect(func(): _hovered = "")
		button.focus_entered.connect(func(): _hovered = action)
		button.focus_exited.connect(func(): _hovered = "")
		add_child(button)
		_actions[action] = button

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
	if main != null and main.player != null:
		var p: Player = main.player
		if _last_player != p:
			_last_player = p
			_hp_trail = p.hp
		_hp_trail = move_toward(_hp_trail,p.hp,delta*p.max_hp*0.7)
		if _portrait_role != p.role:
			_portrait_role = p.role
			_portrait.texture = CanvaSprites.frame(p.role,0)
		_sync_actions(p)
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
func _plate(rect: Rect2, accent: Color) -> void:
	var p := rect.position
	var e := rect.end
	var points := PackedVector2Array([p+Vector2(9,0),Vector2(e.x, p.y),e-Vector2(0,9),e-Vector2(9,0),Vector2(p.x,e.y),p+Vector2(0,9)])
	draw_colored_polygon(points,Color(ForestUI.INK,0.94))
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed,ForestUI.EDGE,1)
	draw_line(p+Vector2(12,0),p+Vector2(rect.size.x*0.45,0),accent,3)

func _draw_top_left(p: Player) -> void:
	var x := 20.0
	var y := 20.0
	var bw := 244.0
	var card_h := 118.0 if p.channeling else 101.0
	_plate(Rect2(12,12,260,card_h),ForestUI.MINT)
	var font := ThemeDB.fallback_font
	draw_arc(Vector2(49,48),28,0,TAU,6,Color(ForestUI.GOLD,0.45),2)
	draw_string(font,Vector2(86,34),p.champ_name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,18,ForestUI.PAPER)
	draw_string(font,Vector2(218,33),"N.%02d" % p.level,HORIZONTAL_ALIGNMENT_LEFT,-1,12,ForestUI.GOLD)
	var health := Color("dc7467") if p.hp < p.max_hp*0.35 else ForestUI.MINT
	draw_rect(Rect2(86,43,172,17),ForestUI.PANEL)
	draw_rect(Rect2(86,43,172*clampf(_hp_trail/maxf(1,p.max_hp),0,1),17),Color("cc9e65"))
	draw_rect(Rect2(86,43,172*float(p.hp)/maxi(1,p.max_hp),17),health)
	draw_rect(Rect2(86,43,172*float(p.hp)/maxi(1,p.max_hp),2),health.lightened(0.35))
	_center_str("%d / %d" % [p.hp,p.max_hp],86,172,56,11,ForestUI.INK,font)
	draw_rect(Rect2(86,65,172,8),ForestUI.PANEL)
	draw_rect(Rect2(86,65,172*p.mana/maxi(1,p.max_mana),8),Color("7fbad8"))
	draw_string(font,Vector2(86,89),"%d MANA" % p.mana,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("9ad1e5"))
	draw_string(font,Vector2(182,89),"%d OURO" % p.gold,HORIZONTAL_ALIGNMENT_LEFT,-1,11,ForestUI.GOLD)
	draw_rect(Rect2(22,103,238,3),ForestUI.PANEL)
	draw_rect(Rect2(22,103,238*float(p.xp)/p.exp_to_next(),3),ForestUI.GOLD)
	if p.channeling:
		draw_string(font,Vector2(24,121),"CANALIZANDO • VOCÊ ESTÁ IMÓVEL",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("9ad1e5"))

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

func _draw_wave_banner(screen_w: float) -> void:
	var font := ThemeDB.fallback_font
	var x := screen_w/2-142
	var accent: Color = BiomeArt.palette(main.cur_stage)[4]
	_plate(Rect2(x,12,284,75),accent)
	_center_str(StageData.stage_name(main.cur_stage).to_upper(),x,284,31,14,ForestUI.PAPER,font)
	_center_str("%s  /  %02d:%02d  /  %d ABATES" % [StageData.diff_name(main.cur_diff),int(main.game_time)/60,int(main.game_time)%60,main.kill_count],x,284,49,11,accent,font)
	for i in 5:
		var col := accent if i <= main.wave_idx else ForestUI.EDGE
		var bx := x+18+i*51
		draw_rect(Rect2(bx,59,44,4),Color(col,0.3))
		var fraction := 1.0 if i < main.wave_idx else (clampf(float(main.wave_killed)/maxi(1,main.wave_quota),0,1) if i == main.wave_idx else 0.0)
		draw_rect(Rect2(bx,59,44*fraction,4),col)
	var status := "ONDA %d / 5   •   %d / %d" % [main.wave_idx+1,main.wave_killed,main.wave_quota]
	if not main.wave_active:
		status = "PRÓXIMA ONDA EM %ds" % (maxi(0,int(main.between_timer))+1)
	_center_str(status,x,284,79,10,ForestUI.PAPER,font)
	_draw_boss_bar(screen_w)

# ---------------------------------------------------------------------
func _draw_boss_bar(screen_w: float) -> void:
	var foe: Enemy = null
	for enemy in main.enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive(): continue
		if enemy.is_boss():
			foe = enemy
			break
		if enemy.is_miniboss() and foe == null: foe = enemy
	if foe == null: return
	var width := 284.0
	var x := screen_w/2-width/2
	var accent := Color("dc7467")
	_plate(Rect2(x,98,width,45),accent)
	var font := ThemeDB.fallback_font
	_center_str(foe.type_name.to_upper(),x,width,116,12,ForestUI.PAPER,font)
	draw_rect(Rect2(x+14,125,width-28,6),ForestUI.PANEL)
	draw_rect(Rect2(x+14,125,(width-28)*float(foe.hp)/maxi(1,foe.max_hp),6),accent)
	for i in 4:
		draw_line(Vector2(x+14+(width-28)*(i+1)/5,125),Vector2(x+14+(width-28)*(i+1)/5,131),ForestUI.INK,2)

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
	var mm := 108.0
	var mx := screen_w - mm - 12
	var my := 12.0
	var world: World = main.world
	if world == null:
		return
	var sx := mm / world.world_size().x
	var sy := mm / world.world_size().y

	_plate(Rect2(mx - 6, my - 6, mm + 12, mm + 12), ForestUI.MINT)
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
func _slot_rect(index: int) -> Rect2:
	var total := 6*58+76
	return Rect2(size.x/2-total/2.0+index*58,size.y-84,52,58)

func _action_rect(id: String) -> Rect2:
	if id == "attack": return _slot_rect(0)
	if id.begins_with("skill"): return _slot_rect(int(id.trim_prefix("skill")))
	if id == "dash": return Rect2(_slot_rect(5).end.x+12,size.y-84,68,58)
	if id == "item": return Rect2(14,size.y-72,82,46)
	if id == "channel": return Rect2(102,size.y-72,92,46)
	if id == "shop": return Rect2(size.x-126,134,54,44)
	if id == "pause": return Rect2(size.x-68,134,54,44)
	return Rect2(size.x-146,size.y-72,132,46)

func _sync_actions(p: Player) -> void:
	var desktop: bool = not main.touch_active() and main.state == main.State.PLAY and not main.shop.visible
	for id in _actions:
		var button: Button = _actions[id]
		button.visible = desktop
		button.position = _action_rect(id).position
		button.size = _action_rect(id).size
		button.disabled = false
		button.tooltip_text = ""
		if id in ["attack","dash"] or id.begins_with("skill"):
			button.visible = desktop and bool(main.settings.get("hud_bar",true))
		if id.begins_with("skill"):
			var index := int(id.trim_prefix("skill"))-1
			button.disabled = index >= p.skills.size()
			button.tooltip_text = "Desbloqueie habilidades na loja do menu."
			if index < p.skills.size():
				var cfg: Dictionary = p.skills[index].cfg
				button.tooltip_text = "%s • %d mana • %.1fs de recarga\n%s" % [cfg.name,cfg.mana,cfg.cd,cfg.desc]
		elif id == "dash":
			button.visible = button.visible and p.dash_enabled
			button.tooltip_text = "Esquiva na direção do movimento • " + _key("dash")
		elif id == "skip":
			button.disabled = not main.can_skip_wave()
			button.tooltip_text = "Antecipe a próxima onda após derrotar metade dos inimigos."
		else:
			button.tooltip_text = {"attack":"Ataque básico automático", "item":"Usar primeiro item do inventário", "channel":"Recuperar mana • fique parado", "shop":"Abrir loja da partida", "pause":"Pausar partida"}.get(id,"")

func _draw_skill_bar(p: Player, _screen_w: float, _screen_h: float) -> void:
	if main.touch_active(): return
	var font := ThemeDB.fallback_font
	if bool(main.settings.get("hud_bar",true)):
		for i in 6:
			var rect := _slot_rect(i)
			var id := "attack" if i == 0 else "skill%d" % i
			var locked := i > p.skills.size()
			var accent := ForestUI.GOLD if i == 0 else (ChampData.rarity_color(int(p.skills[i-1].cfg.get("rarity",0))) if not locked else ForestUI.EDGE)
			_plate(rect,accent)
			if _hovered == id and not locked: draw_rect(rect.grow(-2),Color(accent,0.15))
			var center := rect.get_center()-Vector2(0,2)
			if locked:
				draw_arc(center-Vector2(0,3),6,PI,TAU,10,ForestUI.EDGE,2)
				draw_rect(Rect2(center-Vector2(8,3),Vector2(16,12)),ForestUI.EDGE)
			else:
				if i == 0: SkillIcon.draw_basic(self,p.role,center,16,true)
				else: SkillIcon.draw_icon(self,p.role,str(p.skills[i-1].cfg.kind),i-1,center,16,false)
				var cooldown: float = p.attack_cd if i == 0 else p.skills[i-1].cd_left
				var duration: float = Player.ATTACK_CD/p.attack_speed_mult if i == 0 else p.skills[i-1].cfg.cd
				if cooldown > 0:
					draw_rect(rect.grow(-2),Color(ForestUI.INK,0.63))
					draw_arc(center,20,-PI/2,-PI/2+TAU*clampf(cooldown/duration,0,1),24,accent,2)
					_center_str("%.1f" % cooldown,rect.position.x,rect.size.x,center.y+4,13,ForestUI.PAPER,font)
				elif i > 0 and p.mana < p.skills[i-1].cfg.mana:
					draw_rect(rect.grow(-2),Color(ForestUI.INK,0.5))
					_center_str("MANA",rect.position.x,rect.size.x,center.y+4,10,Color("7fbad8"),font)
			_center_str("AUTO" if i == 0 else _key(id).to_upper(),rect.position.x,rect.size.x,rect.end.y-6,10,accent,font)
		if p.dash_enabled:
			var r := _action_rect("dash")
			_plate(r,ForestUI.MINT)
			_center_str(_key("dash").to_upper(),r.position.x,r.size.x,r.position.y+19,11,ForestUI.PAPER,font)
			_center_str("ESQUIVA" if p.dash_cd <= 0 else "%.1fs" % p.dash_cd,r.position.x,r.size.x,r.position.y+39,10,ForestUI.MINT,font)
			draw_rect(Rect2(r.position+Vector2(8,48),Vector2(52*(1-clampf(p.dash_cd/1.6,0,1)),3)),ForestUI.MINT)
	for id in ["item","channel","shop","pause","skip"]:
		var r := _action_rect(id)
		var accent := ForestUI.GOLD if id == "skip" else ForestUI.MINT
		_plate(r,accent)
		if _hovered == id: draw_rect(r.grow(-2),Color(accent,0.15))
		var title: String = {"item":"ITEM", "channel":"MANA", "shop":"LOJA", "pause":"PAUSA", "skip":"PRÓXIMA ONDA"}[id]
		var hint := _key(id).to_upper()
		if id == "skip" and not main.can_skip_wave():
			hint = "%d ABATES RESTANTES" % maxi(0,main.skip_threshold()-main.wave_killed)
			accent = Color("96aaa2")
		_center_str(title,r.position.x,r.size.x,r.position.y+19,10,ForestUI.PAPER,font)
		_center_str(hint,r.position.x,r.size.x,r.position.y+35,9,accent,font)

# ---------------------------------------------------------------------
func _draw_messages(screen_w: float, screen_h: float) -> void:
	var font := ThemeDB.fallback_font
	var mobile: bool = main.touch_active()
	var y := 174.0 if mobile else screen_h-142.0
	var width := minf(screen_w-40,600)
	var x := (screen_w-width)/2 if mobile else 18.0
	for m in messages:
		var alpha: float = clampf(m.life/0.5,0,1)
		var txt: String = m.base if int(m.count) <= 1 else "%s (%dx)" % [m.base,int(m.count)]
		draw_rect(Rect2(x-6,y-16,width+12,22),Color(ForestUI.INK,alpha*0.8))
		draw_string(font,Vector2(x,y),txt,HORIZONTAL_ALIGNMENT_LEFT,width,13,Color(ForestUI.PAPER,alpha))
		y += 26

func _draw_controls(_p: Player, screen_h: float) -> void:
	if main.touch_active(): return
	var font := ThemeDB.fallback_font
	_center_str("ATAQUE AUTOMÁTICO   /   CLIQUE NAS AÇÕES OU USE OS ATALHOS",0,size.x,screen_h-9,10,ForestUI.PAPER,font)

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
	draw_string(font, Vector2(w - 16 - tw, 195), txt,
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
