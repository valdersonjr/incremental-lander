## Previa das paisagens do relevo (v15): uma missao de cada paisagem, camera afastada para ver o trecho inteiro.
## Uso: gdtool.py capture res://tests/visual/landscape_preview.tscn --frames 280 --every 40 [-- --seed=N] [--near]
## (troca de paisagem a cada 40 quadros: planicie, colinas, serra, vale, planalto, crateras, degraus).
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")
const ORDER := ["planicie", "colinas", "serra", "vale", "planalto", "crateras", "degraus"]
const FRAMES_EACH := 40
const DIST_M := 700.0

var _flight: Flight
var _frame := 0
var _seed := 11
var _zoom := 0.5                                   # --near: zoom do jogo (1), camera sobre o alvo


func _ready() -> void:
	WorldConfig.register_input()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			_seed = int(a.get_slice("=", 1))
		if a == "--near":
			_zoom = 1.0
	_flight = FLIGHT_SCENE.instantiate()
	add_child(_flight)
	_flight.start("luna", _seed, GameState.ship_stats(), false)
	_show(0)


func _show(i: int) -> void:
	_flight.landscapes = [ORDER[i % ORDER.size()]] as Array[String]
	_flight.begin_mission(_seed + i, DIST_M)
	_flight.lander.set_physics_process(false)


func _process(_d: float) -> void:
	_frame += 1
	if _frame % FRAMES_EACH == FRAMES_EACH / 2:              # troca no meio: a captura (a cada 40) pega a camera parada
		_show((_frame + FRAMES_EACH / 2) / FRAMES_EACH)
	var cam := _flight.camera
	cam.zoom = Vector2(_zoom, _zoom)
	if _zoom < 1.0:                                            # visao geral: meio do trecho, bem acima do chao
		cam.global_position = Vector2(DIST_M * 0.5, TerrainGen.height_at(_flight.terrain.ridge, DIST_M * 0.5) - 150.0)
		return
	var pad := _flight.target_pad()                             # --near: como no pouso (nave quase no deck do alvo)
	_flight.lander.global_position = Vector2(float(pad["x"]), float(pad["y"]) - 30.0)
	cam.global_position = _flight.lander.global_position
