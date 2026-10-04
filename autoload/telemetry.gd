## Telemetria de entregas em CSV (calibra o modelo da economy-balance, Etapa 10). So local (nada sai do computador).
## Arquivo: user://telemetry/deliveries.csv — copiar para balance/telemetry/ e rodar econ.calibrate().
## Ligada no desenvolvimento (editor / build de depuracao); no build publico so com --telemetry. Arquivo acima de
## MAX_BYTES vira deliveries_old*.csv (nao cresce sem limite).
extends Node

const DIR := "user://telemetry"
const DELIVERIES := "user://telemetry/deliveries.csv"
const HEADER := ["planet", "distance", "thrust", "efficiency", "tank", "gas_used", "hop_time_s", "quality",
		"crashed", "pilot", "tier", "crystals", "vy", "vx", "tilt", "reason"]

const MAX_BYTES := 5 * 1024 * 1024

var enabled := true
var pilot := "human"      # "demo" quando o piloto automatico voa (nao misturar na calibracao)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	enabled = OS.is_debug_build() or "--telemetry" in args
	if "--demo" in args:
		pilot = "demo"
		enabled = "--telemetry" in args


## Grava uma entrega. result precisa das chaves de HEADER (distancias/gas nas unidades do modelo).
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
	for key: String in HEADER:
		var v: Variant = pilot if key == "pilot" else result.get(key, "")
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
