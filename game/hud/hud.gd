## HUD do voo (arte: UiKit): gas (barra ciano -> ambar -> vermelho), velocidades com cor de seguranca,
## altitude, distancia ao alvo (seta aponta o lado; multiplicador da plataforma), placar de recordes do run (v15: dinheiro
## do run grande + barra ate o recorde; entregas, distancia, pousos perfeitos e maior entrega "valor/recorde", dourados
## quando passam o recorde), selo de Reputacao;
## resultado do pouso em aviso central (pagamento com plataforma x reputacao x carga, chamado pelo Main).
## Carga (Lua): linha com a figura da carga + o que importa agora (barra do sorvete derretendo; bolo deixa o
## V.VERT mais exigente; ratinho fica colorido quando resgatado; queijo rachado).
class_name Hud
extends Control

## Pista: o jogador pediu para terminar a viagem (botao TERMINAR VIAGEM ou tecla, confirmados 2 vezes).
signal end_requested

const TOAST_SECONDS := 2.5
const WORLD_NAME_S := 1.4                       # nome do mundo na chegada (some sozinho)

var flight: Flight = null
var run: RunState = null

var _toast_left := 0.0
var _hint_left := 0.0
var _need_mark: ColorRect = null                # "Da pra chegar?" (Painel de bordo): gas que sobra ao chegar

@onready var _gas: Label = %Gas
@onready var _gas_bar: ProgressBar = %GasBar
@onready var _vy: Label = %Vy
@onready var _vx: Label = %Vx
@onready var _alt: Label = %Alt
@onready var _dist: Label = %Dist
@onready var _msg: Label = %Message
@onready var _score: VBoxContainer = %Score
@onready var _dist_icon: TextureRect = %DistIcon
@onready var _toast: Control = %Toast
@onready var _toast_title: Label = %ToastTitle
@onready var _toast_text: Label = %ToastText
@onready var _toast_extra: Label = %ToastExtra
@onready var _rep_panel: Control = %RepPanel
@onready var _rep: Label = %Rep
@onready var _badge: TextureRect = %Badge
var _hearts: Array[TextureRect] = []
var _rec_start: Dictionary = {}                 # recordes no inicio do run (Main.set_records)
var _rec_value: Dictionary = {}                 # id -> Label do valor no placar
var _rec_best: Dictionary = {}                  # id -> Label "/recorde" (ou do recorde do dinheiro)
var _rec_beaten: Dictionary = {}                # id -> ja passou o recorde neste run (pulsa/toca uma vez)
var _money_bar: ProgressBar = null
var _world_banner: PanelContainer = null        # nome do mundo na chegada (show_world_name)
var _world_label: Label = null
var _world_tween: Tween = null
var _rec_grid: GridContainer = null              # 4 recordes (grade 2x2): so depois do 1o run (onboarding)
var _rec_bar: HBoxContainer = null               # barra ate o recorde de dinheiro: idem
var _track_row: HBoxContainer = null             # v21 (pista): distancia da viagem + recorde do mundo
var _track_dist: Label = null
var _track_best: Label = null
var _pending := 0.0                              # moedas no ar + marcos a receber no proximo pouso (Main)
var _live_row: HBoxContainer = null              # "+N a receber": cresce voando, so entra no banco ao pousar
var _live: Label = null
var _live_hint: Label = null
var _combo_badge: PanelContainer = null          # v28: "x3" grande no alto (multiplicador do proximo pouso)
var _combo_label: Label = null
var _combo_shown := 0
var _combo_bar: ColorRect = null                 # risco colorido embaixo do numero (cor da faixa)
var _combo_t := 0.0
var _spark_t := 0.0
var _goal_row: HBoxContainer = null             # v30: chegada do mundo (bandeira, km, barra do recorde, faltam X)
var _goal: Label = null
var _goal_bar: ProgressBar = null
var _goal_left: Label = null
var _end_button: Button = null                   # pista: TERMINAR VIAGEM (so com a nave parada no chao)
var _end_armed := 0.0                            # > 0: o proximo toque termina (confirmacao, some sozinha)
const END_CONFIRM_S := 2.5
## Faixas do multiplicador: a partir de [n] -> cor (paleta da UI). >= 15 = arco-iris (as cores giram).
const COMBO_TIERS := [[1, "white"], [2, "leaf"], [3, "aqua"], [4, "gold"], [6, "amber"], [8, "coral"], [10, "red"],
		[15, "violet"]]
const RAINBOW := ["red", "amber", "gold", "leaf", "aqua", "violet", "lavender"]
@onready var _cargo_row: Control = %CargoRow
@onready var _cargo_icon: TextureRect = %CargoIcon
@onready var _cargo_bar: ProgressBar = %CargoBar
@onready var _cargo_text: Label = %CargoText

## Texto curto de cada regra no HUD (a figura vem antes; frase de crianca).
const MISSION_HUD := {"heavy": "pesada!", "soft": "devagar!", "fast": "", "tow": "não bata!", "passenger": "pegue o ratinho!"}
const MISSION_FAIL := {"soft": "amassou!", "fast": "derreteu!", "tow": "rachou!", "passenger": "ficou para trás"}


func _ready() -> void:
	(%GasIcon as TextureRect).texture = UiKit.icon("gas")
	for i in EconMath.reputation_levels().size():              # coracoes da Reputacao do ratinho da entrega
		var h := TextureRect.new()
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.custom_minimum_size = Vector2(15, 15)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.pivot_offset = Vector2(7, 7)
		_rep_panel.add_child(h)
		_rep_panel.move_child(h, 1 + i)
		_hearts.append(h)
	(%DistIcon as TextureRect).texture = UiKit.icon("distance")
	_build_score()
	_need_mark = ColorRect.new()
	_need_mark.color = Color("#2e222f")                       # contorno ink + miolo dourado (Resurrect 64)
	_need_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var core := ColorRect.new()
	core.color = Color("#f9c22b")
	core.position = Vector2(1, 1)
	core.size = Vector2(1, 8)
	core.name = "Core"
	_need_mark.add_child(core)
	_gas_bar.add_child(_need_mark)
	_need_mark.visible = false


## Liga o HUD a uma cena de voo e ao run atual (referencias atribuidas pelo pai).
func bind(p_flight: Flight, p_run: RunState) -> void:
	flight = p_flight
	run = p_run
	if flight.track:
		_build_track_row()
		_build_combo_badge()
	flight.delivery_finished.connect(_on_delivery_finished)
	flight.lander.took_off.connect(func() -> void: _set_status(_idle_status()))   # resultado antigo nao fica no rodape
	_set_status(_idle_status())


func _process(delta: float) -> void:
	_tick_toast(delta)
	if _hint_left > 0.0:
		_hint_left -= delta
		if _hint_left <= 0.0:
			_set_status(_idle_status())
	if flight == null:
		return
	var l := flight.lander
	var cfg: Dictionary = WorldConfig.load_config()
	var tol := LandingRules.tolerances(cfg["landing"], float(l.params.get("gear", 1.0)))
	var tank := float(l.params.get("tank", 0.0))
	var frac := l.gas / tank if tank > 0.0 else 0.0
	_gas.text = EconMath.fmt(l.gas)
	_gas_bar.value = frac * 100.0
	_gas_bar.theme_type_variation = &"GasBar" if frac > 0.35 else (&"WarnBar" if frac > 0.15 else &"DangerBar")
	_update_need_mark(l, tank)
	var vy_limit: float = tol["max_vy"]
	var soft := EconMath.mission_has(flight.mission, "soft")
	if flight.target_pad_id >= 0 and soft > 0 and flight.taxi_stage != 1:   # Pouso suave: o limite e o da estrela
		vy_limit = minf(vy_limit, Flight.soft_vy_limit(soft))
	_set_speed(_vy, l.vel_m.y, vy_limit)
	_update_mission()
	_set_speed(_vx, absf(l.vel_m.x), tol["max_vx"])
	var ground := TerrainGen.height_at(flight.terrain.ridge, l.global_position.x)
	_alt.text = "%d m" % int(WorldConfig.px_to_m(ground - l.global_position.y))
	if flight.target_pad_id >= 0:
		var pad := flight.target_pad()
		var dx := WorldConfig.px_to_m(float(pad["x"]) - l.global_position.x)
		_dist.text = "ALVO %d m" % int(absf(dx))
		if flight.target_tier != "normal":
			_dist.text += "  " + UiKit.mult_text(float(EconMath.pad_tier(flight.target_tier)["mult"]))
		_dist_icon.flip_h = dx < 0.0                           # a seta aponta para o lado da plataforma
	_dist.get_parent().visible = flight.target_pad_id >= 0   # sem alvo a janela de missao ja esta aberta: sem dica repetida
	_update_score()
	_update_track()
	_update_end_button(delta)
	_update_reputation(str(flight.mission.get("kind", "simple")) if flight.target_pad_id >= 0 else "")


## Moedas no ar + marcos passados, pagos no proximo pouso (somam no "+N a receber").
func set_pending(amount: float) -> void:
	_pending = amount


## v28: placa grande "x3" no alto, centralizada: o multiplicador que o proximo pouso vai usar (sobe +1 a cada
## plataforma pousada). Quando sobe: pulo, brilho e o xilofone da Estrada.
func _build_combo_badge() -> void:
	_combo_badge = PanelContainer.new()
	_combo_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", -2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_badge.add_child(col)
	_combo_label = Label.new()
	_combo_label.theme_type_variation = &"BigMoneyLabel"
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_combo_label)
	_combo_bar = ColorRect.new()
	_combo_bar.custom_minimum_size = Vector2(0, 2)
	_combo_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_combo_bar)
	var cap := Label.new()
	cap.theme_type_variation = &"DimLabel"
	cap.text = "multiplicador"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(cap)
	add_child(_combo_badge)
	move_child(_combo_badge, 0)                                # atras dos avisos


func _update_combo_badge() -> void:
	var n := run.track_streak if run != null else 0
	var mult := EconMath.track_combo_mult(n)
	_combo_label.text = UiKit.mult_text(mult)
	var c := _combo_color(mult)
	_combo_label.add_theme_color_override(&"font_color", c)
	_combo_bar.color = c
	_combo_badge.reset_size()
	# animacao pela faixa: >= x3 flutua, >= x5 balanca, >= x8 solta faiscas, >= x15 cores girando (_combo_color)
	var dt := get_process_delta_time()
	_combo_t += dt
	var bob := roundf(sin(_combo_t * 4.0) * (1.0 if mult >= 3.0 else 0.0) * (2.0 if mult >= 8.0 else 1.0))
	var shake := roundf(sin(_combo_t * 23.0)) if mult >= 5.0 else 0.0   # tremidinho de 1 px (sem girar: pixel nitido)
	_combo_badge.position = Vector2(roundf((size.x - _combo_badge.size.x) * 0.5) + shake, 4.0 + bob)
	if mult >= 8.0:
		_spark_t -= dt
		if _spark_t <= 0.0:
			_spark_t = maxf(0.05, 0.35 - mult * 0.015)          # quanto maior, mais faiscas
			_spark(c)
	if n > _combo_shown:                                       # subiu num pouso: festa
		UiKit.pulse(_combo_badge, 2.0, 0.45)
		var tw := create_tween()
		tw.tween_property(_combo_label, "modulate", Color(1.6, 1.6, 1.6), 0.08)
		tw.tween_property(_combo_label, "modulate", Color.WHITE, 0.35)
		Sound.jingle("road_stop")
	_combo_shown = n


## Cor da faixa do multiplicador (>= x15: arco-iris girando).
func _combo_color(mult: float) -> Color:
	if mult >= 15.0:
		return UiKit.color(RAINBOW[int(_combo_t * 8.0) % RAINBOW.size()])
	var name := "white"
	for t: Array in COMBO_TIERS:
		if mult >= float(t[0]):
			name = str(t[1])
	return UiKit.color(name)


## Faisca: quadradinho 2x2 da cor da faixa que sai da placa e some.
func _spark(c: Color) -> void:
	var r := ColorRect.new()
	r.color = c
	r.size = Vector2(2, 2)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := _combo_badge.get_rect()
	r.position = Vector2(randf_range(b.position.x, b.end.x), randf_range(b.position.y, b.end.y)).round()
	add_child(r)
	var dir := Vector2(randf_range(-1.0, 1.0), randf_range(-0.4, 1.0)).normalized() * randf_range(10.0, 22.0)
	var tw := r.create_tween()
	tw.tween_property(r, "position", (r.position + dir).round(), 0.5)
	tw.parallel().tween_property(r, "modulate:a", 0.0, 0.5)
	tw.tween_callback(r.queue_free)


## v21 (pista): a distancia e a pontuacao da viagem -> linha grande logo abaixo do dinheiro, com o recorde do mundo.
func _build_track_row() -> void:
	_track_row = HBoxContainer.new()
	_track_row.add_theme_constant_override(&"separation", 4)
	var ic := TextureRect.new()
	ic.texture = UiKit.icon("distance")
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ic.custom_minimum_size = Vector2(12, 12)
	_track_row.add_child(ic)
	_track_dist = Label.new()
	_track_dist.theme_type_variation = &"ValueLabel"
	_track_row.add_child(_track_dist)
	var cup := TextureRect.new()
	cup.texture = UiKit.icon("trophy")
	cup.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	cup.custom_minimum_size = Vector2(12, 12)
	_track_row.add_child(cup)
	_track_best = Label.new()
	_track_best.theme_type_variation = &"DimLabel"
	_track_row.add_child(_track_best)
	_score.add_child(_track_row)
	_live_row = HBoxContainer.new()
	_live_row.add_theme_constant_override(&"separation", 3)
	_live = Label.new()
	_live.theme_type_variation = &"BigMoneyLabel"
	_live_row.add_child(_live)
	var hint := Label.new()
	_live_hint = hint
	hint.theme_type_variation = &"DimLabel"
	hint.text = "a receber: pouse!"
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_live_row.add_child(hint)
	_live_row.modulate.a = 0.0                                 # sem tremer o painel: aparece/some pela opacidade
	_score.add_child(_live_row)
	_score.move_child(_live_row, 1)
	_score.move_child(_track_row, 1)
	_rec_grid.visible = false                                  # a distancia ja esta aqui em destaque
	_build_goal_row()
	_build_end_button()


## v30 (usuario: "o recorde deveria ficar mostrando junto com a distancia da linha de chegada... quanto falta"):
## bandeirinha + chegada em km + barra (recorde / chegada) + "faltam X". Some no mundo sem chegada.
func _build_goal_row() -> void:
	_goal_row = HBoxContainer.new()
	_goal_row.add_theme_constant_override(&"separation", 3)
	_goal_row.add_child(FinishFlagIcon.new())
	_goal = Label.new()
	_goal.theme_type_variation = &"ValueLabel"
	_goal_row.add_child(_goal)
	_goal_bar = ProgressBar.new()
	_goal_bar.show_percentage = false
	_goal_bar.theme_type_variation = &"GasBar"
	_goal_bar.custom_minimum_size = Vector2(44, 7)
	_goal_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_goal_row.add_child(_goal_bar)
	_goal_left = Label.new()
	_goal_left.theme_type_variation = &"DimLabel"
	_goal_row.add_child(_goal_left)
	_score.add_child(_goal_row)
	_score.move_child(_goal_row, _track_row.get_index() + 1)


## Pista (2026-10-11): o jogador decide quando parar (no lugar do fim automatico por "o gas nao da", que errava).
## Canto de baixo a direita; sem foco (Espaco e o motor, nao pode apertar o botao).
func _build_end_button() -> void:
	_end_button = Button.new()
	_end_button.text = "TERMINAR VIAGEM"
	_end_button.focus_mode = Control.FOCUS_NONE
	_end_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 6)
	_end_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_end_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_end_button.visible = false
	_end_button.pressed.connect(request_end)
	add_child(_end_button)


## Botao ou tecla: 1o toque arma ("TERMINAR? toque de novo"), 2o dentro de END_CONFIRM_S termina.
func request_end() -> void:
	if not can_end():
		return
	if _end_armed > 0.0:
		_end_armed = 0.0
		end_requested.emit()
		return
	_end_armed = END_CONFIRM_S
	Sound.ui("click")


## Da para terminar agora? Pista, run em andamento e a nave parada no chao (no ar o salto se perderia).
func can_end() -> bool:
	return _end_button != null and flight != null and run != null and not run.over \
			and flight.lander.state == Lander.State.LANDED


func _update_end_button(delta: float) -> void:
	if _end_button == null:
		return
	_end_armed = maxf(_end_armed - delta, 0.0)
	_end_button.visible = can_end()
	if not _end_button.visible:
		_end_armed = 0.0
	_end_button.text = "TERMINAR? toque de novo" if _end_armed > 0.0 else "TERMINAR VIAGEM"
	_end_button.theme_type_variation = &"DangerButton" if _end_armed > 0.0 else &""


func _update_track() -> void:
	if _track_row == null:
		return
	var best := flight.track_best_m
	var dist := run.distance_flown if run != null else 0.0     # distancia = ate onde POUSOU
	_track_dist.text = GameState.record_text("run_distance", dist)
	_track_dist.theme_type_variation = &"MoneyLabel" if best > 0.0 and dist > best else &"ValueLabel"
	_track_best.text = GameState.record_text("run_distance", best) if best > 0.0 else "-"
	_update_goal(maxf(best, dist))
	var live := _pending + flight.track_live_gain()
	_live_row.modulate.a = 1.0 if live >= 1.0 else 0.0
	_live.text = "+" + (str(int(live)) if live < 1000.0 else EconMath.fmt(live))
	var combo := EconMath.track_combo_mult(run.track_streak) if run != null else 1.0
	_live_hint.text = "a receber %s: pouse!" % UiKit.mult_text(combo)   # v28: x plataformas pousadas na viagem
	_update_combo_badge()


func _update_goal(best: float) -> void:
	var finish := EconMath.finish_m(flight.planet_id)
	_goal_row.visible = finish > 0.0
	if finish <= 0.0:
		return
	_goal.text = GameState.record_text("run_distance", finish)
	_goal_bar.value = clampf(best / finish, 0.0, 1.0) * 100.0
	var left := finish - best
	_goal_left.text = "chegou!" if left <= 0.0 else "faltam " + GameState.record_text("run_distance", left)
	_goal_left.theme_type_variation = &"MoneyLabel" if left <= 0.0 else &"DimLabel"


## Recordes no inicio do run (o placar compara com eles; 0 = ainda sem recorde: so mostra o numero do run).
func set_records(start: Dictionary) -> void:
	_rec_start = start.duplicate()
	_rec_beaten.clear()
	for key: String in _rec_best:
		var rec := float(_rec_start.get(key, 0.0))
		var l: Label = _rec_best[key]
		l.text = GameState.record_text(key, rec)
		if key != "run_money":
			l.get_parent().visible = rec > 0.0
	(_rec_best["run_money"] as Label).get_parent().visible = float(_rec_start.get("run_money", 0.0)) > 0.0
	# comeco do jogo (onboarding): no 1o run o placar mostra so o dinheiro; os recordes entram depois
	_rec_grid.visible = GameState.shows_records() and _track_row == null   # pista: distancia em destaque
	_rec_bar.visible = _rec_bar.visible and GameState.shows_records()


## Placar (variante A aprovada): dinheiro grande; barra + trofeu + recorde; grade 2x2 com os outros recordes.
func _build_score() -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 3)
	var coin := TextureRect.new()
	coin.texture = UiKit.icon("credits")
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.custom_minimum_size = Vector2(24, 24)
	top.add_child(coin)
	var money := Label.new()
	money.theme_type_variation = &"BigValueLabel"
	top.add_child(money)
	_rec_value["run_money"] = money
	_score.add_child(top)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override(&"separation", 3)
	_money_bar = ProgressBar.new()
	_money_bar.show_percentage = false
	_money_bar.theme_type_variation = &"GasBar"
	_money_bar.custom_minimum_size = Vector2(0, 7)
	_money_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_money_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_row.add_child(_money_bar)
	var trophy := TextureRect.new()
	trophy.texture = UiKit.icon("trophy")
	trophy.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	trophy.custom_minimum_size = Vector2(12, 12)
	bar_row.add_child(trophy)
	var best := Label.new()
	best.theme_type_variation = &"DimLabel"
	bar_row.add_child(best)
	_rec_best["run_money"] = best
	_score.add_child(bar_row)
	_rec_bar = bar_row
	var grid := GridContainer.new()
	_rec_grid = grid
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 0)
	for key: String in GameState.RECORDS:
		if key == "run_money":
			continue
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override(&"separation", 4)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ic := TextureRect.new()
		ic.texture = UiKit.icon(str(GameState.RECORDS[key][1]))
		ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		ic.custom_minimum_size = Vector2(12, 12)
		ic.tooltip_text = str(GameState.RECORDS[key][0])
		chip.add_child(ic)
		var v := Label.new()
		v.theme_type_variation = &"ValueLabel"
		chip.add_child(v)
		var best_box := HBoxContainer.new()                     # recorde = trofeuzinho + numero (nao "/8": parecia fracao)
		best_box.add_theme_constant_override(&"separation", 1)
		var cup := TextureRect.new()
		cup.texture = UiKit.icon("trophy")
		cup.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		cup.custom_minimum_size = Vector2(12, 12)
		best_box.add_child(cup)
		var r := Label.new()
		r.theme_type_variation = &"DimLabel"
		best_box.add_child(r)
		chip.add_child(best_box)
		_rec_value[key] = v
		_rec_best[key] = r
		grid.add_child(chip)
	_score.add_child(grid)
	set_records({})


func _update_score() -> void:
	if run == null:
		return
	var values := run.record_values()
	for key: String in _rec_value:
		var v := float(values.get(key, 0.0))
		var rec := float(_rec_start.get(key, 0.0))
		var l: Label = _rec_value[key]
		l.text = GameState.record_text(key, v)
		var beaten := rec > 0.0 and v > rec
		if key == "run_money":
			l.theme_type_variation = &"BigMoneyLabel" if beaten else &"BigValueLabel"
			_money_bar.value = (v / rec * 100.0) if rec > 0.0 else 0.0
		else:
			l.theme_type_variation = &"MoneyLabel" if beaten else &"ValueLabel"
			(_rec_best[key] as Label).theme_type_variation = &"MoneyLabel" if beaten else &"DimLabel"
		if beaten and not _rec_beaten.get(key, false):          # passou o recorde agora: pulinho (+ aviso no dinheiro)
			_rec_beaten[key] = true
			UiKit.pulse(l.get_parent(), 1.9, 0.5)
			if key == "run_money":
				var tw := create_tween()
				tw.tween_interval(1.6)                          # depois do aviso da entrega
				tw.tween_callback(_show_toast.bind("NOVO RECORDE!", str(GameState.RECORDS[key][0]), &"MoneyLabel"))
				tw.tween_callback(Sound.jingle.bind("milestone"))


## Reputacao com o ratinho da entrega em andamento (v14): rostinho + coracoes (cheios = nivel) + bonus. Some sem alvo.
func _update_reputation(kind: String) -> void:
	_rep_panel.visible = kind != "" and GameState.shows_reputation()   # coracoes so depois do comeco (onboarding)
	if kind == "":
		return
	var lv := GameState.rep_level(kind)
	_badge.texture = TalkArt.face(kind)
	for i in _hearts.size():
		_hearts[i].texture = UiKit.kid("heart_on" if i < lv else "heart_off")
	_rep.text = "+%d%%" % roundi((EconMath.reputation_mult(lv) - 1.0) * 100.0) if lv > 0 else ""
	_rep_panel.tooltip_text = "reputação com este ratinho: missões cumpridas enchem os corações"


## Subiu a reputacao com um ratinho (Main, depois da entrega): aviso e coracoes pulando.
func show_reputation_up(kind: String, level: int) -> void:
	var name := str(EconMath.mission_kind(kind).get("name", kind))
	_show_toast("REPUTAÇÃO!", "%s gosta mais de você: +%d%%" % [name,
			roundi((EconMath.reputation_mult(level) - 1.0) * 100.0)], &"GoodLabel")
	for h in _hearts:
		UiKit.pulse(h, 1.8, 0.4)


## "Da pra chegar?": marquinha na barra no gas que deve sobrar ao chegar pelo arco ideal (conta feita na decolagem;
## pousado, com o gas de agora). Nao chega: a marquinha fica vermelha no comeco da barra.
func _update_need_mark(l: Lander, tank: float) -> void:
	_need_mark.visible = flight.target_pad_id >= 0 and tank > 0.0 and GameState.assist_on("gas_need") \
			and l.state != Lander.State.CRASHED
	if not _need_mark.visible:
		return
	var start := l.gas if l.state == Lander.State.LANDED else l.gas_at_takeoff
	var left := Assists.gas_left_at_arrival(flight.planet_id, flight.target_distance_m, flight.eff_stats(), start)
	var w := _gas_bar.size.x
	_need_mark.size = Vector2(3, _gas_bar.size.y + 2)
	_need_mark.position = Vector2(roundf(clampf(left / tank, 0.0, 1.0) * (w - 3.0)), -1)
	(_need_mark.get_node("Core") as ColorRect).size.y = _gas_bar.size.y
	(_need_mark.get_node("Core") as ColorRect).color = Color("#f9c22b") if left >= 0.0 else Color("#e83b3b")


## Linha da missao: figura da regra + barra (relogio da Rapida ou peso da Pesada) + frase curta. Taxi: passo 1/2.
## Dupla: figura da 1a regra e as duas frases.
func _update_mission() -> void:
	var m: Dictionary = flight.mission
	var parts: Array = m.get("parts", [])
	var mini := flight.minigame_text() if flight.target_pad_id >= 0 else ""
	if mini != "":                                             # v17: placar do minijogo do mundo
		_cargo_row.visible = true
		var ic := flight.minigame_icon()
		_cargo_icon.texture = MinigameArt.tex(ic) if ic != "" else UiKit.icon("credits")
		_cargo_bar.visible = true
		_cargo_bar.value = 100.0 * flight.minigame_got / maxf(1.0, flight.minigame_total)
		_cargo_bar.theme_type_variation = &"XpBar"
		_cargo_text.text = mini
		_cargo_text.theme_type_variation = &"MoneyLabel"
		return
	var show := flight.target_pad_id >= 0 and not parts.is_empty()
	_cargo_row.visible = show
	if not show:
		return
	var kind: String = parts[0]["kind"]
	var failed: Array = flight.failed
	_cargo_icon.texture = CargoArt.icon(kind, failed.has(kind))
	var heavy := EconMath.mission_has(m, "heavy")
	if flight.urgent_limit > 0.0 and not failed.has("fast"):
		var frac := flight.urgent_left / maxf(flight.urgent_limit, 0.001)
		_cargo_bar.visible = true
		_cargo_bar.value = frac * 100.0
		_cargo_bar.theme_type_variation = &"GasBar" if frac > 0.5 else (&"WarnBar" if frac > 0.2 else &"DangerBar")
	elif heavy > 0:                                            # peso: barra cheia na estrela 3
		_cargo_bar.visible = true
		_cargo_bar.value = 100.0 * heavy / 3.0
		_cargo_bar.theme_type_variation = &"WarnBar"
	else:
		_cargo_bar.visible = false
	var texts: Array[String] = []
	var bad := false
	for p: Dictionary in parts:
		var k: String = p["kind"]
		if failed.has(k):
			texts.append("enjoou" if k == "passenger" and flight.taxi_stage > 0 else MISSION_FAIL.get(k, ""))
			bad = true
		elif k == "passenger" and flight.taxi_stage == 1:
			texts.append("1: busque o ratinho")
		elif k == "passenger" and flight.taxi_stage == 2:
			texts.append("2: leve de volta")
		elif k == "passenger" and flight.rescued:
			texts.append("a bordo!")
			_cargo_icon.texture = CargoArt.tex("mouse_safe")
		elif MISSION_HUD.get(k, "") != "":
			texts.append(MISSION_HUD[k])
	_cargo_text.text = "  ".join(texts)
	_cargo_text.theme_type_variation = &"BadLabel" if bad else &"MoneyLabel"


## Minijogo do mundo: o verbo grande no comeco da missao (estilo WarioWare: "Pegue!", "Junte!"...).
func show_verb(verb: String, text: String = "") -> void:
	if verb != "":
		_show_toast(verb, text, &"MoneyLabel")


## Aprendiz: o salto nao deu depois das tentativas; o cartao abre para escolher outra missao.
func show_other_mission() -> void:
	_show_toast("OUTRA MISSÃO!", "essa ficou difícil: escolha outra", &"MoneyLabel")
	Sound.ui("pop")
	_set_status(_idle_status())


## Aprendiz: "Veja como!" - o piloto automatico voa o salto; qualquer comando devolve a nave ao jogador.
func show_guide() -> void:
	_show_toast("VEJA COMO!", "aperte o motor para pilotar", &"GoodLabel")
	_set_status(_idle_status())


## Fim do aprendiz (world.json > onboarding.apprentice_stars entregas): daqui em diante bater acaba a viagem.
## extra = 2a linha (o Nivelador emprestado: agora mora na NAVE ou volta na Estrada).
func show_graduation(extra: String = "") -> void:
	_show_toast("PILOTO FORMADO!", "agora é pra valer: bater acaba a viagem", &"GoodLabel")
	_toast_extra.text = extra
	_toast_extra.visible = extra != ""


## Chegada no mundo (comeco do run): o nome do mundo no alto por WORLD_NAME_S, junto do aviso do salto. Some sozinho.
func show_world_name(world_name: String) -> void:
	if _world_banner == null:
		_world_banner = PanelContainer.new()
		_world_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_world_banner.add_child(row)
		for i in 3:
			if i == 1:
				_world_label = Label.new()
				_world_label.theme_type_variation = &"TitleLabel"
				_world_label.add_theme_color_override(&"font_color", get_theme_color(&"font_color", &"MoneyLabel"))
				row.add_child(_world_label)
			else:
				var star := TextureRect.new()
				star.texture = UiKit.kid("star_on")
				star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				star.custom_minimum_size = Vector2(12, 12)
				row.add_child(star)
		add_child(_world_banner)
	_world_label.text = world_name
	_world_banner.reset_size()
	_world_banner.position = Vector2(roundf((size.x - _world_banner.size.x) * 0.5), 6.0)
	_world_banner.modulate.a = 1.0
	_world_banner.visible = true
	if _world_tween != null:
		_world_tween.kill()
	_world_tween = create_tween()
	_world_tween.tween_interval(WORLD_NAME_S)
	_world_tween.tween_property(_world_banner, "modulate:a", 0.0, 0.4)
	_world_tween.tween_callback(func() -> void: _world_banner.visible = false)


## Aprendiz: a nave bateu (ou o gas acabou) e o mesmo salto recomeca. Na 1a batida do tipo (shown_in_picture) o jeito
## de acertar vem em figura (fantasma + balao do RetryHint) e o aviso e so o titulo; depois, a frase curta lembra.
func show_retry(reason: String, shown_in_picture: bool = false) -> void:
	_show_toast("TENTE DE NOVO!", "" if shown_in_picture else UiKit.crash_tip(reason), &"MoneyLabel")
	Sound.sfx("retry")
	_set_status(_idle_status())


## Taxi: avisa o passo novo (o passageiro embarcou: agora leve de volta).
func taxi_step(step: int) -> void:
	_show_toast("A BORDO!", "agora leve de volta" if step == 2 else "", &"GoodLabel")
	Sound.sfx("aboard")


func _set_speed(label: Label, value: float, limit: float) -> void:
	label.text = ("%.1f m/s" % value).replace(".", ",")
	if value > limit:
		label.text += " !"                                   # forma alem da cor (daltonismo): rapido demais
	label.theme_type_variation = &"GoodLabel" if value <= limit * 0.6 else (&"MoneyLabel" if value <= limit
			else &"BadLabel")


func _on_delivery_finished(result: Dictionary) -> void:
	if result["crashed"]:
		var why := UiKit.crash_text(str(result["reason"]))
		_set_status("BATEU: " + why, &"BadLabel")
		_show_toast("BATEU!", why, &"BadLabel")
	# pouso bom: o Main chama show_delivery() depois de calcular o pagamento


## Aviso da entrega concluida: ganho, qualidade e o que multiplicou (plataforma, reputacao, carga).
## entry = RunState.deliveries[-1] (rep = bonus do ratinho, rep_pts = pontos de reputacao ganhos, perfect).
func show_delivery(entry: Dictionary) -> void:
	var gain := float(entry["rewards"].get("credits", 0.0))
	var text := "+%s   qualidade %d%%" % [EconMath.fmt(gain), int(float(entry["quality"]) * 100.0)]
	if entry.has("accum"):                                     # v27: (acumulado + pouso) x nota x sequencia = banco
		var raw := float(entry["accum"]) + float(entry.get("land_bonus", 0.0))
		var combo := float(entry.get("combo", 1.0))
		text = "%s  pouso %s  plataformas %s = +%s" % [EconMath.fmt(raw), UiKit.mult_text(float(entry["land_mult"])),
				UiKit.mult_text(combo), EconMath.fmt(gain)]
	var parts: Array[String] = []
	if float(entry.get("mult", 1.0)) > 1.0:
		parts.append("plataforma " + UiKit.mult_text(float(entry["mult"])))
	if float(entry.get("rep", 1.0)) > 1.0:
		parts.append("reputação +%d%%" % roundi((float(entry["rep"]) - 1.0) * 100.0))
	if float(entry.get("gift_pay", 0.0)) > 0.0:
		parts.append("presente +%s" % EconMath.fmt(float(entry["gift_pay"])))
	var m: Dictionary = entry.get("mission", {})
	if not (m.get("parts", []) as Array).is_empty():
		var mm := float(entry.get("mission_mult", 1.0))
		var failed: Array = entry.get("failed", [])
		var name := str(EconMath.mission_kind(str(m["kind"]))["name"])
		parts.append(("%s %s" % [name, UiKit.mult_text(mm)]) if failed.is_empty()
				else "%s %s" % [MISSION_FAIL.get(str(failed[0]), "falhou"), UiKit.mult_text(mm)])
	var mg: Array = entry.get("minigame", [0, 0])
	if int(mg[1]) > 0 and int(mg[0]) >= int(mg[1]):           # selo do minijogo feito por inteiro (auditoria T4)
		parts.append("MINIJOGO COMPLETO!")
	if bool(entry.get("perfect", false)):
		parts.append("POUSO PERFEITO!")
	if float(entry.get("bonus", 0.0)) > 0.0:                  # moedas no ar + marcos, pagos no pouso
		parts.append("moedas e marcos +%s" % EconMath.fmt(float(entry["bonus"])))
	if int(entry.get("skipped", 0)) > 0:                      # v21 (pista): pulou uma plataforma
		parts.append("PULOU UMA!")
	if int(entry.get("rep_pts", 0)) > 0:
		parts.append("+%d reputação" % int(entry["rep_pts"]))
	var title := "ENTREGA!"
	if entry.has("stars"):                                     # v21 (pista): pouso + estrelas da nota
		var n := int(entry["stars"])
		title = "POUSOU! +%d %s" % [n, "estrela" if n == 1 else "estrelas"]
	_set_status(title + " " + text, &"GoodLabel")
	_show_toast(title, text, &"GoodLabel")
	_toast_extra.text = "  ·  ".join(parts)
	_toast_extra.visible = not parts.is_empty()
	_toast_extra.theme_type_variation = &"MoneyLabel"


## Pedido de confirmacao no rodape (ex.: "R de novo para reiniciar"); some sozinho depois de seconds.
func confirm_hint(text: String, seconds: float) -> void:
	_set_status(text, &"MoneyLabel")
	_hint_left = seconds


## Rodape em repouso: so a marca do sandbox. As teclas ficam no menu do Esc (CONTROLES), nao na tela.
func _idle_status() -> String:
	return "MODO LIVRE" if Sandbox.active() else ""


## Rodape (resultado do ultimo pouso ou marca do sandbox) (painel fino no Footer, da largura do texto; some se vazio).
func _set_status(text: String, variation: StringName = &"DimLabel") -> void:
	_msg.text = text
	(_msg.get_parent() as Control).visible = text != ""
	_msg.theme_type_variation = variation


## Aviso grande no centro (o momento mais importante do voo nao pode ficar so no rodape).
func _show_toast(title: String, text: String, variation: StringName) -> void:
	_toast_title.text = title
	_toast_title.add_theme_color_override(&"font_color", get_theme_color(&"font_color", variation))
	_toast_text.text = text
	_toast_text.visible = text != ""
	_toast_extra.visible = false
	_toast.modulate.a = 1.0
	_toast.visible = true
	_toast_left = TOAST_SECONDS


func _tick_toast(delta: float) -> void:
	if _toast_left <= 0.0:
		return
	_toast_left -= delta
	_toast.modulate.a = clampf(_toast_left / 0.5, 0.0, 1.0)  # some no ultimo meio segundo
	if _toast_left <= 0.0:
		_toast.visible = false
