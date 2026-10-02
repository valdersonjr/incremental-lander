## Conversao estado <-> save (logica pura, testavel). JSON versionado; nada derivado e salvo
## (stats/custos sao recalculados pelo EconMath). Dados de fora sao nao confiaveis: tudo e validado.
class_name SaveData
extends RefCounted

const SAVE_VERSION := 1
## Migracoes: versao -> Callable que recebe o dict e devolve a versao seguinte.
const MIGRATIONS := {}


## Monta o dicionario do save a partir do estado do jogo.
static func serialize(state: Dictionary) -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"spec_version": EconMath.spec.get("meta", {}).get("version", 0),
		"resources": state["resources"].duplicate(),
		"levels": state["levels"].duplicate(),
		"shop": state["shop"].duplicate(),
		"prestige_points": state["prestige_points"],
		"prestige_pending": state["prestige_pending"],
		"unlocked": state["unlocked"].duplicate(),
		"current_planet": state["current_planet"],
		"cycle_earned": state["cycle_earned"].duplicate(),
		"income_history": state["income_history"].duplicate(true),
		"reached_goal": state["reached_goal"],
		"runs_done": state["runs_done"],
		"play_seconds": state["play_seconds"],
		"settings": state["settings"].duplicate(),
	}


## Valida/migra um save lido. Retorna {"ok": bool, "state": Dictionary, "warnings": Array[String]}.
## Ids que nao existem mais na spec sao descartados com aviso.
static func deserialize(raw: Variant) -> Dictionary:
	var warnings: Array[String] = []
	if not raw is Dictionary:
		return {"ok": false, "state": {}, "warnings": ["save nao e um objeto JSON"]}
	var d: Dictionary = raw
	var v := int(d.get("save_version", 0))
	while v < SAVE_VERSION and MIGRATIONS.has(v):
		d = MIGRATIONS[v].call(d)
		v += 1
	if v != SAVE_VERSION:
		return {"ok": false, "state": {}, "warnings": ["versao de save desconhecida: %d" % v]}
	var res_ids: Array = EconMath.spec["resources"].map(func(r: Dictionary) -> String: return r["id"])
	var up_ids: Array = EconMath.spec["upgrades"].map(func(u: Dictionary) -> String: return u["id"])
	var shop_ids: Array = EconMath.shop_items().map(func(i: Dictionary) -> String: return i["id"])
	var planet_ids: Array = EconMath.spec["planets"].map(func(p: Dictionary) -> String: return p["id"])
	var st := {
		"resources": _filter_numbers(d.get("resources", {}), res_ids, "recurso", warnings, false),
		"levels": _filter_numbers(d.get("levels", {}), up_ids, "upgrade", warnings, true),
		"shop": _filter_numbers(d.get("shop", {}), shop_ids, "item da loja", warnings, true),
		"prestige_points": maxf(0.0, float(d.get("prestige_points", 0.0))),
		"prestige_pending": bool(d.get("prestige_pending", false)),
		"unlocked": [],
		"current_planet": "luna",
		"cycle_earned": _filter_numbers(d.get("cycle_earned", {}), res_ids, "recurso", warnings, false),
		"income_history": [],
		"reached_goal": bool(d.get("reached_goal", false)),
		"runs_done": maxi(0, int(d.get("runs_done", 0))),
		"play_seconds": maxf(0.0, float(d.get("play_seconds", 0.0))),
		"settings": d.get("settings", {}) if d.get("settings", {}) is Dictionary else {},
	}
	for rid: String in res_ids:
		if not st["resources"].has(rid):
			st["resources"][rid] = 0.0
	for p: Variant in d.get("unlocked", ["luna"]):
		if str(p) in planet_ids and not str(p) in st["unlocked"]:
			st["unlocked"].append(str(p))
	if not "luna" in st["unlocked"]:
		st["unlocked"].insert(0, "luna")
	var cur := str(d.get("current_planet", "luna"))
	st["current_planet"] = cur if cur in st["unlocked"] else "luna"
	for h: Variant in d.get("income_history", []):
		if h is Dictionary and h.get("earned") is Dictionary:
			st["income_history"].append({"earned": h["earned"], "seconds": float(h.get("seconds", 1.0))})
	return {"ok": true, "state": st, "warnings": warnings}


## Resumo de um estado validado (deserialize) para a tela de jogos salvos.
static func summary(state: Dictionary) -> Dictionary:
	return {
		"planet": str(state.get("current_planet", "luna")),
		"runs": int(state.get("runs_done", 0)),
		"credits": float(state.get("resources", {}).get("credits", 0.0)),
		"play_seconds": float(state.get("play_seconds", 0.0)),
		"prestige_points": float(state.get("prestige_points", 0.0)),
		"reached_goal": bool(state.get("reached_goal", false)),
	}


static func _filter_numbers(src: Variant, allowed: Array, kind: String, warnings: Array[String],
		as_int: bool) -> Dictionary:
	var out := {}
	if not src is Dictionary:
		return out
	for k: Variant in src:
		if not str(k) in allowed:
			warnings.append("%s '%s' nao existe mais na spec: ignorado" % [kind, k])
			continue
		var val := float(src[k])
		out[str(k)] = maxi(0, int(val)) if as_int else maxf(0.0, val)
	return out
