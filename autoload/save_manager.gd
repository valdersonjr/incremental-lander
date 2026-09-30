## Save/load do progresso (skill godot-dev, save-telemetry.md): JSON versionado em user://save.json,
## escrita atomica (tmp -> rename), backup save.bak, autosave nos eventos, salva ao fechar.
## Desligado em --demo, --dev_* e --no_save (verificacao nunca sobrescreve o progresso do jogador).
extends Node

var PATH := "user://save.json"
var TMP := "user://save.json.tmp"
var BAK := "user://save.bak"

var enabled := true
var _dirty := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--demo" or a == "--no_save" or a.begins_with("--dev_"):
			enabled = false
	if enabled:
		load_game()
	Events.run_finished.connect(func(_s: Dictionary) -> void: request_save())
	Events.upgrade_bought.connect(func(_i: String, _l: int) -> void: request_save())
	Events.planet_unlocked.connect(func(_p: String) -> void: request_save())
	Events.prestiged.connect(func(_g: float, _t: float) -> void: request_save())
	Events.goal_reached.connect(func(_p: String) -> void: request_save())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


## Muda a pasta do save (testes de integracao usam uma pasta propria, nunca o save real).
func set_dir(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	PATH = dir.path_join("save.json")
	TMP = dir.path_join("save.json.tmp")
	BAK = dir.path_join("save.bak")


## Agenda um save no fim do frame (junta varios eventos seguidos num save so).
func request_save() -> void:
	if enabled and not _dirty:
		_dirty = true
		call_deferred("_flush")


func _flush() -> void:
	_dirty = false
	save_game()


## Salva agora. Escrita atomica: grava .tmp, guarda o save anterior em .bak e renomeia.
func save_game() -> bool:
	if not enabled:
		return false
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	if f == null:
		push_warning("save: nao abriu %s" % TMP)
		return false
	f.store_string(JSON.stringify(SaveData.serialize(GameState.save_state()), "\t"))
	f.close()
	if FileAccess.file_exists(PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(BAK))
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(TMP), ProjectSettings.globalize_path(PATH)) == OK


## Carrega o save (ou o backup, se o principal estiver corrompido). Retorna true se carregou.
func load_game() -> bool:
	for path: String in [PATH, BAK]:
		if not FileAccess.file_exists(path):
			continue
		var json := JSON.new()  # parse() devolve o erro sem imprimir (save corrompido nao e erro do jogo)
		var raw: Variant = json.data if json.parse(FileAccess.get_file_as_string(path)) == OK else null
		var r := SaveData.deserialize(raw)
		for w: String in r["warnings"]:
			push_warning("save: " + w)
		if r["ok"]:
			GameState.apply_save_state(r["state"])
			return true
		push_warning("save invalido em %s; tentando o backup" % path)
	return false


## Novo jogo: apaga o progresso (mantem as opcoes).
func new_game() -> void:
	var settings: Dictionary = GameState.settings.duplicate()
	GameState.reset()
	GameState.settings = settings
	for path: String in [PATH, BAK]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	save_game()
