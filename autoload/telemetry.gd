## Telemetria de entregas em CSV (calibra o modelo da economy-balance, Etapa 10). So local (nada sai do computador).
## Arquivo: user://telemetry/deliveries.csv — copiar para balance/telemetry/ e rodar econ.calibrate().
## Ligada no desenvolvimento (editor / build de depuracao); no build publico so com --telemetry. Arquivo acima de
## MAX_BYTES vira deliveries_old*.csv (nao cresce sem limite).
## Sessao (2026-10-08, auditoria dos primeiros minutos): user://telemetry/session.csv guarda os marcos do jogo
## (jogo novo, decolagem, entrega, batida, tentar de novo, compra, telas, fechar) para medir o comeco:
## .claude/skills/godot-dev/scripts/ftue.py le o arquivo e mostra o funil de cada jogo novo.
extends Node

const DIR := "user://telemetry"
const DELIVERIES := "user://telemetry/deliveries.csv"
const HEADER := ["planet", "distance", "thrust", "efficiency", "tank", "gas_used", "hop_time_s", "quality",
		"crashed", "pilot", "tier", "gift", "vy", "vx", "tilt", "reason", "mission", "star", "failed", "mg_got",
		"mg_total", "mg_extra"]

const SESSION := "user://telemetry/session.csv"
const SESSION_HEADER := ["session", "t_s", "event", "detail", "stars", "runs", "credits", "play_s"]

const MAX_BYTES := 5 * 1024 * 1024

var enabled := true
var pilot := "human"      # "demo" quando o piloto automatico voa (nao misturar na calibracao)
var _session := ""        # id da sessao (hora de abrir o jogo)
var _session_on := false  # funil so de jogo de verdade (sem demo, testes, --dev_*, --no_save)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	enabled = OS.is_debug_build() or "--telemetry" in args
	if "--demo" in args:
		pilot = "demo"
		enabled = "--telemetry" in args
	_session_on = enabled and not "--no_save" in args
	for a in args:                                             # atalhos de dev nao entram no funil
		if a.begins_with("--dev_"):
			_session_on = false
	for a in OS.get_cmdline_args():                            # tests/ (previas, testes) nunca entram no funil
		if a.begins_with("res://tests/"):
			_session_on = false
	_session = str(int(Time.get_unix_time_from_system()))
	Events.upgrade_bought.connect(func(id: String, level: int) -> void: event("buy", "%s:%d" % [id, level]))
	event("boot")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		event("close")


## Marco da sessao (funil do comeco do jogo). detail = texto livre curto (motivo da batida, peca comprada...).
func event(name: String, detail: String = "") -> void:
	if not _session_on:
		return
	DirAccess.make_dir_recursive_absolute(DIR)
	var is_new := not FileAccess.file_exists(SESSION)
	var f := FileAccess.open(SESSION, FileAccess.READ_WRITE if not is_new else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	if is_new:
		f.store_csv_line(PackedStringArray(SESSION_HEADER))
	f.store_csv_line(PackedStringArray([_session, "%.2f" % (Time.get_ticks_msec() / 1000.0), name, detail,
			str(GameState.stars), str(GameState.runs_done), str(int(GameState.amount("credits"))),
			str(int(GameState.play_seconds))]))


## Grava uma entrega. result precisa das chaves de HEADER (distancias/gas nas unidades do modelo); missao, estrela,
## regras que falharam e o placar do minijogo saem de result.mission/failed/minigame; mg_extra = medida propria do
## minijogo (Flight.minigame_extra: curling = distancia de parada ao centro em m; Bolhas = segundos com o bau na agua;
## Cogumelos = quiques totais).
func record_delivery(result: Dictionary) -> void:
	if not enabled:
		return
	DirAccess.make_dir_recursive_absolute(DIR)
	_rotate_if_old_header()
	var is_new := not FileAccess.file_exists(DELIVERIES)
	var f := FileAccess.open(DELIVERIES, FileAccess.READ_WRITE if not is_new else FileAccess.WRITE)
	if f == null:
		push_warning("telemetria: nao abriu %s" % DELIVERIES)
		return
	f.seek_end()
	if is_new:
		f.store_csv_line(PackedStringArray(HEADER))
	var row := PackedStringArray()
	var m: Dictionary = result.get("mission", {})
	var mg: Array = result.get("minigame", [0, 0])
	var derived := {"pilot": pilot, "mission": m.get("kind", ""), "star": m.get("star", ""),
			"failed": "|".join(PackedStringArray(result.get("failed", []))), "mg_got": mg[0], "mg_total": mg[1]}
	for key: String in HEADER:
		var v: Variant = derived[key] if derived.has(key) else result.get(key, "")
		row.append(str(int(v)) if v is bool else str(v))
	f.store_csv_line(row)


## Se o arquivo existente tem outro cabecalho (versao antiga) ou passou de MAX_BYTES, guarda como deliveries_old.csv
## (ou deliveries_old2.csv, 3... — nunca sobrescreve dados antigos).
func _rotate_if_old_header() -> void:
	if not FileAccess.file_exists(DELIVERIES):
		return
	var f := FileAccess.open(DELIVERIES, FileAccess.READ)
	var head := f.get_csv_line()
	var too_big := f.get_length() > MAX_BYTES
	f.close()
	if Array(head) != HEADER or too_big:
		var n := 1
		var name := "deliveries_old.csv"
		while FileAccess.file_exists(DIR.path_join(name)):
			n += 1
			name = "deliveries_old%d.csv" % n
		DirAccess.rename_absolute(ProjectSettings.globalize_path(DELIVERIES),
				ProjectSettings.globalize_path(DIR.path_join(name)))
