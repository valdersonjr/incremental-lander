## Modo sandbox (menu inicial): testar tudo sem a progressao. So troca o ESTADO da sessao (GameState) por um ponto de
## partida de teste (data/world.json > sandbox); as regras sao as mesmas do jogo. Antes de entrar, o jogo em uso e
## salvo e copiado em memoria; durante, o SaveManager so grava as opcoes e a telemetria nao registra; ao sair, a copia
## volta (com as opcoes mudadas no sandbox).
class_name Sandbox
extends RefCounted

## Estado verdadeiro guardado na entrada (GameState.save_state, copia profunda).
static var _real: Dictionary = {}
static var _telemetry_was := true


static func active() -> bool:
	return SaveManager.sandbox


## Entra no sandbox no mundo planet_id; strong = nave com upgrades altos, senao nave basica.
static func begin(planet_id: String, strong: bool) -> void:
	SaveManager.save_game()                                    # o progresso verdadeiro fica guardado antes
	_real = GameState.save_state().duplicate(true)
	SaveManager.sandbox = true
	_telemetry_was = Telemetry.enabled
	Telemetry.enabled = false                                  # voos de teste nao entram na calibracao
	var cfg: Dictionary = WorldConfig.load_config()["sandbox"]
	var settings: Dictionary = GameState.settings.duplicate()
	GameState.reset()
	GameState.settings = settings
	GameState.current_planet = planet_id
	GameState.runs_done = 1
	if strong:
		var lv: Dictionary = cfg["strong_levels"]
		for id: String in lv:
			GameState.levels[id] = int(lv[id])
	top_up()


## Repoe os recursos de teste (chamado a cada visita ao hangar).
static func top_up() -> void:
	var res: Dictionary = WorldConfig.load_config()["sandbox"]["resources"]
	for id: String in res:
		GameState.resources[id] = maxf(GameState.amount(id), float(res[id]))
		Events.resources_changed.emit(id, GameState.resources[id])


## Sai do sandbox: devolve o jogo verdadeiro (as opcoes mudadas no sandbox ficam) e volta a gravar.
static func end() -> void:
	if not SaveManager.sandbox:
		return
	var settings: Dictionary = GameState.settings.duplicate()
	_real["settings"] = settings
	GameState.apply_save_state(_real)
	_real = {}
	SaveManager.sandbox = false
	Telemetry.enabled = _telemetry_was
	SaveManager.save_game()
