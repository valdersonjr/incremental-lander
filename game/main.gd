## Entrada do jogo: Main -> World (voo) + GUI (HUD, ofertas, resumo). Orquestra o run (Fase 2):
## ofertas -> voo -> entrega -> recompensas (GameState) -> ofertas ... -> resumo -> novo run.
## Args: --demo (piloto automatico escolhe, voa e compra), --seed=N, --planet=id, --hangar_wait=s. R reinicia.
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")
const HUD_SCENE := preload("res://game/hud/hud.tscn")
const OFFER_SCENE := preload("res://game/run/offer_panel.tscn")
const SUMMARY_SCENE := preload("res://game/run/run_summary.tscn")
const HANGAR_SCENE := preload("res://game/hangar/hangar.tscn")

var _args: Dictionary = {}
var _demo := false
var _run_seed := 0
var _run: RunState = null
var _flight: Flight = null
var _hud: Hud = null
var _offers: OfferPanel = null
var _summary: RunSummary = null
var _hangar: Hangar = null

@onready var _world: Node2D = %World
@onready var _gui: CanvasLayer = %GUI


func _ready() -> void:
	WorldConfig.load_config()
	WorldConfig.register_input()
	_args = _parse_args(OS.get_cmdline_user_args())
	_demo = _args.has("demo")
	_run_seed = int(_args.get("seed", WorldConfig.load_config()["demo"]["seed"]))
	if _args.has("planet"):
		GameState.current_planet = str(_args["planet"])
	_hangar = HANGAR_SCENE.instantiate()
	_gui.add_child(_hangar)
	_hangar.visible = false
	_hangar.launch_requested.connect(_on_launch_requested)
	_start_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart") and not _hangar.visible:
		_start_run()


func _start_run() -> void:
	_hangar.visible = false
	for n: Node in [_flight, _hud, _offers, _summary]:
		if n != null:
			n.queue_free()
	var stats := GameState.ship_stats()
	_run = RunState.create(GameState.current_planet, stats, _run_seed)
	_flight = FLIGHT_SCENE.instantiate()
	_world.add_child(_flight)
	_hud = HUD_SCENE.instantiate()
	_gui.add_child(_hud)
	_offers = OFFER_SCENE.instantiate()
	_gui.add_child(_offers)
	_summary = SUMMARY_SCENE.instantiate()
	_gui.add_child(_summary)
	_summary.visible = false
	_gui.move_child(_hangar, -1)  # hangar sempre por cima
	_flight.start(GameState.current_planet, _run_seed, stats, _demo)
	_hud.bind(_flight, _run)
	_flight.delivery_finished.connect(_on_delivery_finished)
	_flight.stranded.connect(_on_stranded)
	_offers.offer_chosen.connect(_on_offer_chosen)
	_offers.end_requested.connect(_on_end_requested)
	_summary.continue_requested.connect(_on_continue)
	Events.run_started.emit(GameState.current_planet)
	_show_offers()


func _show_offers() -> void:
	var gas := _flight.lander.gas
	if not _run.over and not _run.can_continue(gas):
		_run.finish("sem_gas")
	if _run.over:
		_end_run()
		return
	_offers.show_offers(_run, gas)
	if _demo:
		await get_tree().create_timer(0.5).timeout
		var i := _run.best_offer(_flight.lander.gas)
		if i < 0:
			_run.finish("sem_gas")
			_end_run()
		else:
			_on_offer_chosen(i)


func _on_offer_chosen(index: int) -> void:
	var d := _run.take_offer(index)
	_offers.visible = false
	_flight.set_target(d)


func _on_end_requested() -> void:
	_run.finish("encerrado")
	_end_run()


func _on_delivery_finished(result: Dictionary) -> void:
	print("DELIVERY_RESULT ", JSON.stringify(result))  # verificacao automatica (gdtool run/capture)
	if result["crashed"]:
		_run.crash(str(result["reason"]))
		_end_run()
		return
	var rewards := _run.complete_delivery(result["distance"], result["quality"], result["gas_used"])
	GameState.add_rewards(rewards)
	_show_offers()


func _on_stranded() -> void:
	_run.finish("sem_gas")
	_end_run()


func _end_run() -> void:
	_offers.visible = false
	var s := _run.summary()
	_summary.show_summary(s)
	GameState.runs_done += 1
	Events.run_finished.emit(s)
	print("RUN_SUMMARY ", JSON.stringify(s))
	if _demo:
		await get_tree().create_timer(2.0).timeout
		_on_continue()


## Fim do run -> hangar (comprar upgrades) -> decolar novo run.
func _on_continue() -> void:
	_summary.visible = false
	_hud.visible = false
	_hangar.open()
	if _demo:
		_demo_shop()
		await get_tree().create_timer(float(_args.get("hangar_wait", 0.5))).timeout
		_on_launch_requested()


func _on_launch_requested() -> void:
	_run_seed += 1
	_start_run()


## Demo: compra repetidamente o upgrade acessivel mais barato (verificacao automatica da progressao).
func _demo_shop() -> void:
	while true:
		var best := ""
		var best_cost := INF
		for r: Dictionary in GameState.upgrade_rows():
			var c := float(r["cost"].get("credits", 0.0))
			if r["affordable"] and c < best_cost:
				best = r["id"]
				best_cost = c
		if best == "" or not GameState.buy_upgrade(best):
			break
	_hangar.refresh()
	print("HANGAR ", JSON.stringify({"credits": GameState.amount("credits"), "levels": GameState.levels,
			"stats": GameState.ship_stats()}))


func _parse_args(args: PackedStringArray) -> Dictionary:
	var out := {}
	for a in args:
		var s := a.trim_prefix("--")
		if "=" in s:
			out[s.get_slice("=", 0)] = s.get_slice("=", 1)
		else:
			out[s] = true
	return out
