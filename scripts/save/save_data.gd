## Conversao estado <-> save (logica pura, testavel). JSON versionado; nada derivado e salvo
## (stats/custos sao recalculados pelo EconMath). Dados de fora sao nao confiaveis: tudo e validado.
class_name SaveData
extends RefCounted

const SAVE_VERSION := 2
## Migracoes (_migrate): versao -> funcao que recebe o dict e devolve a versao seguinte.
## v1 -> v2 (2026-10-06): sai prestigio, loja, outros mundos e Expedicao (so a Lua por enquanto).
## Recordes pessoais guardados (GameState.RECORDS; saves antigos sem recordes comecam vazios).
const RECORD_IDS := ["best_delivery", "longest_hop", "best_combo", "best_run"]


## Monta o dicionario do save a partir do estado do jogo.
static func serialize(state: Dictionary) -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"spec_version": EconMath.spec.get("meta", {}).get("version", 0),
		"resources": state["resources"].duplicate(),
		"levels": state["levels"].duplicate(),
		"current_planet": state["current_planet"],
		"income_history": state["income_history"].duplicate(true),
		"runs_done": state["runs_done"],
		"play_seconds": state["play_seconds"],
		"settings": state["settings"].duplicate(),
		"records": state.get("records", {}).duplicate(),
	}


## Valida/migra um save lido. Retorna {"ok": bool, "state": Dictionary, "warnings": Array[String]}.
## Ids que nao existem mais na spec sao descartados com aviso.
static func deserialize(raw: Variant) -> Dictionary:
	var warnings: Array[String] = []
	if not raw is Dictionary:
		return {"ok": false, "state": {}, "warnings": ["save nao e um objeto JSON"]}
	var d: Dictionary = raw
	var v := int(_num(d.get("save_version", 0)))
	while v < SAVE_VERSION and v >= 1:
		d = _migrate(v, d)
		v += 1
	if v != SAVE_VERSION:
		return {"ok": false, "state": {}, "warnings": ["versao de save desconhecida: %d" % v]}
	var res_ids: Array = EconMath.spec["resources"].map(func(r: Dictionary) -> String: return r["id"])
	var up_ids: Array = EconMath.spec["upgrades"].map(func(u: Dictionary) -> String: return u["id"])
	var st := {
		"resources": _filter_numbers(d.get("resources", {}), res_ids, "recurso", warnings, false),
		"levels": _filter_numbers(d.get("levels", {}), up_ids, "upgrade", warnings, true),
		"current_planet": "luna",
		"income_history": [],
		"runs_done": maxi(0, int(_num(d.get("runs_done", 0)))),
		"play_seconds": maxf(0.0, _num(d.get("play_seconds", 0.0))),
		"settings": d.get("settings", {}) if d.get("settings", {}) is Dictionary else {},
		"records": _filter_numbers(d.get("records", {}), RECORD_IDS, "recorde", warnings, false),
	}
	for rid: String in res_ids:
		if not st["resources"].has(rid):
			st["resources"][rid] = 0.0
	var hist: Variant = d.get("income_history", [])
	for h: Variant in (hist if hist is Array else []):
		if h is Dictionary and h.get("earned") is Dictionary:
			st["income_history"].append({"earned": _filter_numbers(h["earned"], res_ids, "recurso", warnings, false),
					"seconds": maxf(1.0, _num(h.get("seconds", 1.0)))})
	return {"ok": true, "state": st, "warnings": warnings}


## Resumo de um estado validado (deserialize) para a tela de jogos salvos.
static func summary(state: Dictionary) -> Dictionary:
	return {
		"planet": str(state.get("current_planet", "luna")),
		"runs": int(state.get("runs_done", 0)),
		"credits": float(state.get("resources", {}).get("credits", 0.0)),
		"play_seconds": float(state.get("play_seconds", 0.0)),
	}


## v1 -> v2: descarta o que era de prestigio/mundos (Poeira, loja, planetas, Expedicao, minerio). Os niveis e
## recursos que nao existem mais na spec ja caem no filtro de deserialize; a renda guardada da frota so com creditos.
static func _migrate(from_version: int, d: Dictionary) -> Dictionary:
	match from_version:
		1:
			return _from_v1(d)
	return d


static func _from_v1(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	for k: String in ["shop", "prestige_points", "prestige_pending", "unlocked", "cycle_earned", "reached_goal"]:
		out.erase(k)
	out["current_planet"] = "luna"
	out["save_version"] = 2
	return out


static func _filter_numbers(src: Variant, allowed: Array, kind: String, warnings: Array[String],
		as_int: bool) -> Dictionary:
	var out := {}
	if not src is Dictionary:
		return out
	for k: Variant in src:
		if not str(k) in allowed:
			warnings.append("%s '%s' nao existe mais na spec: ignorado" % [kind, k])
			continue
		var val := _num(src[k])
		out[str(k)] = maxi(0, int(val)) if as_int else maxf(0.0, val)
	return out


## Numero de um valor de fora (save editado/danificado): so int/float/texto numerico; o resto, NaN e infinito = 0.
static func _num(v: Variant) -> float:
	var x := 0.0
	if v is int or v is float:
		x = float(v)
	elif v is String and (v as String).is_valid_float():
		x = (v as String).to_float()
	return 0.0 if is_nan(x) or is_inf(x) else x
