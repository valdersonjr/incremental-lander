## Telemetria de entregas em CSV (calibra o modelo da economy-balance, Etapa 10).
## Arquivo: user://telemetry/deliveries.csv — copiar para balance/telemetry/ e rodar econ.calibrate().
extends Node

const DIR := "user://telemetry"
const DELIVERIES := "user://telemetry/deliveries.csv"
const HEADER := ["planet", "distance", "thrust", "efficiency", "tank", "gas_used", "hop_time_s", "quality",
		"crashed"]

var enabled := true


## Grava uma entrega. result precisa das chaves de HEADER (distancias/gas nas unidades do modelo).
func record_delivery(result: Dictionary) -> void:
	if not enabled:
		return
	DirAccess.make_dir_recursive_absolute(DIR)
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
		var v: Variant = result.get(key, "")
		row.append(str(int(v)) if v is bool else str(v))
	f.store_csv_line(row)
