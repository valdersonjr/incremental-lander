## HUD do voo (arte: UiKit): gas (barra ciano -> ambar -> vermelho), velocidades com cor de seguranca,
## altitude, distancia ao alvo (seta aponta o lado; multiplicador da plataforma), creditos e entregas, selo de Reputacao;
## resultado do pouso em aviso central (pagamento com plataforma x reputacao x carga, chamado pelo Main).
## Carga (Lua): linha com a figura da carga + o que importa agora (barra do sorvete derretendo; bolo deixa o
## V.VERT mais exigente; ratinho fica colorido quando resgatado; queijo rachado).
class_name Hud
extends Control

const TOAST_SECONDS := 2.5

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
@onready var _credits: Label = %Credits
@onready var _deliveries: Label = %Deliveries
@onready var _dist_icon: TextureRect = %DistIcon
@onready var _toast: Control = %Toast
@onready var _toast_title: Label = %ToastTitle
@onready var _toast_text: Label = %ToastText
@onready var _toast_extra: Label = %ToastExtra
@onready var _rep_panel: Control = %RepPanel
@onready var _rep: Label = %Rep
@onready var _cargo_row: Control = %CargoRow
@onready var _cargo_icon: TextureRect = %CargoIcon
@onready var _cargo_bar: ProgressBar = %CargoBar
@onready var _cargo_text: Label = %CargoText

## Texto curto de cada regra no HUD (a figura vem antes; frase de crianca).
const MISSION_HUD := {"heavy": "pesada!", "soft": "devagar!", "fast": "", "tow": "não bata!", "passenger": "pegue o ratinho!"}
const MISSION_FAIL := {"soft": "amassou!", "fast": "derreteu!", "tow": "rachou!", "passenger": "ficou para trás"}


func _ready() -> void:
	(%GasIcon as TextureRect).texture = UiKit.icon("gas")
	(%DistIcon as TextureRect).texture = UiKit.icon("distance")
	(%MoneyIcon as TextureRect).texture = UiKit.icon("credits")
	(%DeliveriesIcon as TextureRect).texture = UiKit.icon("expedition")
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
	else:
		_dist.text = "escolha uma entrega"
		_dist_icon.flip_h = false
	_credits.text = EconMath.fmt(GameState.amount("credits"))
	_deliveries.text = "%d/%d" % [run.deliveries.size(), run.max_deliveries] if run != null else ""
	_update_reputation(run.reputation if run != null else GameState.reputation)


## Selo de Reputacao: aceso = a proxima entrega vale +bonus (houve pouso perfeito); apagado = pouse reto e macio.
func _update_reputation(on: bool) -> void:
	_rep_panel.visible = flight != null
	_rep.text = "REPUTAÇÃO +%d%%" % roundi(EconMath.reputation_bonus() * 100.0)
	_rep.theme_type_variation = &"MoneyLabel" if on else &"DimLabel"
	_rep_panel.modulate.a = 1.0 if on else 0.55


## "Da pra chegar?": marquinha na barra no gas que deve sobrar ao chegar pelo arco ideal (conta feita na decolagem;
## pousado, com o gas de agora). Nao chega: a marquinha fica vermelha no comeco da barra.
func _update_need_mark(l: Lander, tank: float) -> void:
	_need_mark.visible = flight.target_pad_id >= 0 and tank > 0.0 and GameState.assist_on("gas_need") \
			and l.state != Lander.State.CRASHED
	if not _need_mark.visible:
		return
	var start := l.gas if l.state == Lander.State.LANDED else l.gas_at_takeoff
	var left := Assists.gas_left_at_arrival(flight.planet_id, flight.target_distance_m, flight.stats, start)
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


## Taxi: avisa o passo novo (o passageiro embarcou: agora leve de volta).
func taxi_step(step: int) -> void:
	_show_toast("A BORDO!", "agora leve de volta" if step == 2 else "", &"GoodLabel")


func _set_speed(label: Label, value: float, limit: float) -> void:
	label.text = "%.1f m/s" % value
	label.theme_type_variation = &"GoodLabel" if value <= limit * 0.6 else (&"MoneyLabel" if value <= limit
			else &"BadLabel")


func _on_delivery_finished(result: Dictionary) -> void:
	if result["crashed"]:
		var why := UiKit.crash_text(str(result["reason"]))
		_set_status("BATEU: " + why, &"BadLabel")
		_show_toast("BATEU!", why, &"BadLabel")
	# pouso bom: o Main chama show_delivery() depois de calcular o pagamento


## Aviso da entrega concluida: ganho, qualidade e o que multiplicou (plataforma, reputacao, carga).
## entry = RunState.deliveries[-1]; rep_next = a proxima entrega tem o bonus da Reputacao (pouso perfeito agora).
func show_delivery(entry: Dictionary, rep_next: bool) -> void:
	var gain := float(entry["rewards"].get("credits", 0.0))
	var text := "+%s   qualidade %d%%" % [EconMath.fmt(gain), int(float(entry["quality"]) * 100.0)]
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
	if rep_next:
		parts.append("POUSO PERFEITO! próxima +%d%%" % roundi(EconMath.reputation_bonus() * 100.0))
	elif float(entry.get("rep", 1.0)) > 1.0:
		parts.append("pouso não foi perfeito: próxima sem bônus")
	_set_status("ENTREGA! " + text, &"GoodLabel")
	_show_toast("ENTREGA!", text, &"GoodLabel")
	_toast_extra.text = "  ·  ".join(parts)
	_toast_extra.visible = not parts.is_empty()
	_toast_extra.theme_type_variation = &"MoneyLabel"


## Pedido de confirmacao no rodape (ex.: "R de novo para reiniciar"); some sozinho depois de seconds.
func confirm_hint(text: String, seconds: float) -> void:
	_set_status(text, &"MoneyLabel")
	_hint_left = seconds


## Rodape em repouso: so a marca do sandbox. As teclas ficam no menu do Esc (CONTROLES), nao na tela.
func _idle_status() -> String:
	return "SANDBOX" if Sandbox.active() else ""


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
