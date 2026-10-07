## Save/load do progresso (skill godot-dev, save-telemetry.md): JSON versionado, escrita atomica (tmp -> rename),
## backup .bak, autosave nos eventos, salva ao fechar. VARIOS JOGOS SALVOS (SLOTS espacos): o jogo 1 e o
## user://save.json de sempre (saves antigos continuam valendo, sem migracao); o jogo N>1 e user://save_N.json.
## Opcoes (volumes) e o ultimo jogo usado sao globais, em user://settings.json — trocar de jogo nao muda o volume.
## Desligado em --demo, --dev_* e --no_save e em tudo de tests/ (verificacao nunca carrega nem sobrescreve
## o progresso do jogador — uma previa que simula compra dispararia o autosave sobre o save real).
extends Node

const SLOTS := 5

var PATH := "user://save.json"
var TMP := "user://save.json.tmp"
var BAK := "user://save.bak"

var enabled := true
## Modo sandbox (Sandbox.begin/end): o jogo de teste nunca e gravado; so as opcoes globais.
var sandbox := false
## Jogo salvo em uso (1..SLOTS): o autosave grava nele.
var slot := 1
var _dir := "user://"
var _dirty := false
## Aviso para o jogador (o menu inicial mostra): um jogo salvo existe mas nao pode ser lido.
var load_warning := ""
## Espacos cujo arquivo existe mas nao carregou (danificado ou de versao mais nova): antes de gravar por cima, os
## arquivos sao guardados a parte (nunca se perde um save por uma leitura que falhou).
var _unreadable: Dictionary = {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--demo" or a == "--no_save" or a.begins_with("--dev_"):
			enabled = false
	for a in OS.get_cmdline_args():
		# qualquer coisa de tests/ (previas, executor de testes unitarios, paridade) nunca le nem grava o save real;
		# as integracoes que testam o save ligam de novo com uma pasta propria (set_dir)
		if a.begins_with("res://tests/"):
			enabled = false
	if enabled:
		_migrate_old_user_dir()
		_load_prefs_and_slot()
	Events.run_finished.connect(func(_s: Dictionary) -> void: request_save())
	Events.upgrade_bought.connect(func(_i: String, _l: int) -> void: request_save())
	Events.road_reached.connect(func(_n: String) -> void: request_save())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


## A pasta de dados passou a ter nome proprio (project.godot: custom_user_dir_name), independente do nome do jogo.
## Na primeira vez, copia os saves, opcoes e telemetria da pasta antiga do Godot (app_userdata/Incremental Lander).
## Nunca sobrescreve nada que ja exista na pasta nova.
func _migrate_old_user_dir() -> void:
	var new_dir := OS.get_user_data_dir()
	if FileAccess.file_exists(new_dir.path_join("save.json")) or FileAccess.file_exists(new_dir.path_join("settings.json")):
		return
	for engine_dir: String in ["Godot", "godot"]:
		var old_dir := OS.get_data_dir().path_join(engine_dir).path_join("app_userdata").path_join("Incremental Lander")
		if old_dir == new_dir or not DirAccess.dir_exists_absolute(old_dir):
			continue
		_copy_tree(old_dir, new_dir, ["json", "bak", "csv"])
		print("save: dados copiados de %s" % old_dir)
		return


func _copy_tree(src: String, dst: String, exts: Array) -> void:
	DirAccess.make_dir_recursive_absolute(dst)
	for f: String in DirAccess.get_files_at(src):
		if f.get_extension() in exts and not FileAccess.file_exists(dst.path_join(f)):
			DirAccess.copy_absolute(src.path_join(f), dst.path_join(f))
	for d: String in ["telemetry"]:
		if DirAccess.dir_exists_absolute(src.path_join(d)):
			_copy_tree(src.path_join(d), dst.path_join(d), exts)


## Muda a pasta do save (testes de integracao usam uma pasta propria, nunca o save real). Volta ao jogo 1.
func set_dir(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	_dir = dir
	_use_slot(1)


## Arquivos de um jogo salvo: {path, tmp, bak}. Jogo 1 = nomes antigos (save.json / save.bak).
func slot_files(n: int) -> Dictionary:
	var base := "save" if n == 1 else "save_%d" % n
	return {"path": _dir.path_join(base + ".json"), "tmp": _dir.path_join(base + ".json.tmp"),
			"bak": _dir.path_join(base + ".bak")}


## Agenda um save no fim do frame (junta varios eventos seguidos num save so).
func request_save() -> void:
	if enabled and not _dirty:
		_dirty = true
		call_deferred("_flush")


func _flush() -> void:
	_dirty = false
	save_game()


## Salva agora o jogo em uso (e as opcoes globais). Escrita atomica: grava .tmp, guarda o anterior em .bak e renomeia.
func save_game() -> bool:
	if not enabled:
		return false
	_save_prefs()
	if sandbox:
		return false
	if _unreadable.has(slot):
		_keep_unreadable(slot)
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	if f == null:
		push_warning("save: nao abriu %s" % TMP)
		return false
	f.store_string(JSON.stringify(SaveData.serialize(GameState.save_state()), "\t"))
	f.close()
	if FileAccess.file_exists(PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(BAK))
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(TMP), ProjectSettings.globalize_path(PATH)) == OK


## Carrega o jogo em uso (ou o backup, se o principal estiver corrompido). Retorna true se carregou.
func load_game() -> bool:
	var r := _read_slot(slot)
	for w: String in r["warnings"]:
		push_warning("save: " + w)
	if r["ok"]:
		GameState.apply_save_state(r["state"])
		_unreadable.erase(slot)
	elif r["exists"]:
		_unreadable[slot] = true
		load_warning = ("O Jogo %d não pôde ser lido (arquivo danificado ou de outra versão do jogo).\n" +
				"Ele foi guardado à parte e não será apagado.") % slot
		push_warning("save: jogo %d ilegivel; sera guardado a parte antes de gravar" % slot)
	return r["ok"]


## Resumo de um jogo salvo para a tela de selecao (so leitura; nao mexe no jogo em uso).
## {exists, ok, slot, current, planet, runs, credits, play_seconds, stars, nodes}
func slot_summary(n: int) -> Dictionary:
	var r := _read_slot(n)
	var out := SaveData.summary(r["state"]) if r["ok"] else {}
	out["exists"] = r["exists"]
	out["ok"] = r["ok"]
	out["slot"] = n
	out["current"] = n == slot
	return out


## Passa a usar o jogo salvo n: carrega o progresso dele (ou comeca do zero, se vazio). As opcoes nao mudam.
func load_slot(n: int) -> void:
	if sandbox:                                               # jogos salvos so mudam fora do sandbox
		push_warning("save: load_slot ignorado no sandbox")
		return
	load_warning = ""
	var settings: Dictionary = GameState.settings.duplicate()
	_use_slot(n)
	GameState.reset()
	if enabled:
		load_game()
	GameState.settings = settings
	GameState.apply_settings()
	_save_prefs()


## Novo jogo no espaco n (padrao: o atual): apaga o progresso dele e passa a usa-lo (mantem as opcoes).
func new_game(n: int = -1) -> void:
	if sandbox:                                               # jogos salvos so mudam fora do sandbox
		push_warning("save: new_game ignorado no sandbox")
		return
	load_warning = ""
	if n < 0:
		n = slot
	var settings: Dictionary = GameState.settings.duplicate()
	_use_slot(n)
	GameState.reset()
	GameState.settings = settings
	_remove_slot_files(n)
	save_game()


## "Salvar" do menu do jogo: grava o jogo em uso no espaco n e passa a usa-lo (o autosave segue nele). Se n tinha
## outro jogo, ele e substituido (um arquivo ilegivel e guardado a parte antes). O espaco antigo fica como estava.
func save_to_slot(n: int) -> bool:
	if sandbox or not enabled:                                # o sandbox nunca grava
		return false
	if n != slot:
		var r := _read_slot(n)
		if r["exists"] and not r["ok"]:
			_keep_unreadable(n)
		_remove_slot_files(n)
		_use_slot(n)
	load_warning = ""
	return save_game()


## Apaga um jogo salvo. Se for o jogo em uso, o estado em memoria volta ao inicio (sem gravar nada).
func delete_slot(n: int) -> void:
	if sandbox:                                               # jogos salvos so mudam fora do sandbox
		push_warning("save: delete_slot ignorado no sandbox")
		return
	load_warning = ""
	if not enabled:
		return
	_remove_slot_files(n)
	if n == slot:
		var settings: Dictionary = GameState.settings.duplicate()
		GameState.reset()
		GameState.settings = settings


func _use_slot(n: int) -> void:
	slot = clampi(n, 1, SLOTS)
	var f := slot_files(slot)
	PATH = f["path"]
	TMP = f["tmp"]
	BAK = f["bak"]


## Guarda os arquivos ilegiveis do espaco n como <nome>.unreadable[N].json/.bak (nunca sobrescreve outro).
func _keep_unreadable(n: int) -> void:
	_unreadable.erase(n)
	var f := slot_files(n)
	for key: String in ["path", "bak"]:
		var src: String = f[key]
		if not FileAccess.file_exists(src):
			continue
		var ext := src.get_extension()
		var base := src.get_basename()
		var dst := "%s.unreadable.%s" % [base, ext]
		var k := 2
		while FileAccess.file_exists(dst):
			dst = "%s.unreadable%d.%s" % [base, k, ext]
			k += 1
		DirAccess.rename_absolute(ProjectSettings.globalize_path(src), ProjectSettings.globalize_path(dst))


func _remove_slot_files(n: int) -> void:
	_unreadable.erase(n)
	var f := slot_files(n)
	for path: String in [f["path"], f["bak"], f["tmp"]]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Le e valida um jogo salvo (principal, senao o backup). {exists, ok, state, warnings}
func _read_slot(n: int) -> Dictionary:
	var f := slot_files(n)
	var exists := false
	var warnings: Array[String] = []
	for path: String in [f["path"], f["bak"]]:
		if not FileAccess.file_exists(path):
			continue
		exists = true
		var json := JSON.new()  # parse() devolve o erro sem imprimir (save corrompido nao e erro do jogo)
		var raw: Variant = json.data if json.parse(FileAccess.get_file_as_string(path)) == OK else null
		var r := SaveData.deserialize(raw)
		warnings.append_array(r["warnings"])
		if r["ok"]:
			return {"exists": true, "ok": true, "state": r["state"], "warnings": warnings}
		warnings.append("save invalido em %s; tentando o backup" % path)
	return {"exists": exists, "ok": false, "state": {}, "warnings": warnings}


## Opcoes globais + ultimo jogo usado. Sem settings.json (saves antigos): as opcoes vem do proprio save.
func _load_prefs_and_slot() -> void:
	var prefs := _read_prefs()
	_use_slot(int(prefs.get("last_slot", 1)))
	load_game()
	if prefs.get("settings") is Dictionary:
		GameState.settings = prefs["settings"]
		GameState.apply_settings()


func _read_prefs() -> Dictionary:
	var path := _dir.path_join("settings.json")
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()                                     # opcoes corrompidas: volta ao padrao, sem erro
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	return json.data if json.data is Dictionary else {}


func _save_prefs() -> void:
	if not enabled:
		return
	var f := FileAccess.open(_dir.path_join("settings.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"last_slot": slot, "settings": GameState.settings}, "\t"))
