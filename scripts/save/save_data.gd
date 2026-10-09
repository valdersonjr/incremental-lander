## Conversao estado <-> save (logica pura, testavel). JSON versionado; nada derivado e salvo
## (stats/custos sao recalculados pelo EconMath). Dados de fora sao nao confiaveis: tudo e validado.
class_name SaveData
extends RefCounted

const SAVE_VERSION := 6
## Migracoes (_migrate): versao -> funcao que recebe o dict e devolve a versao seguinte.
## v1 -> v2 (2026-10-06): sai prestigio, loja, outros mundos e Expedicao (so a Lua por enquanto).
## v2 -> v3 (2026-10-07): Estrada das Estrelas — estrelas viram total ACUMULADO (as gastas em nos de missao voltam:
## + unlock_cost por no); sai o upgrade Reputacao (filtro da spec) e o recorde de combo (vira pousos perfeitos).
## v3 -> v4 (2026-10-07): recordes por run ("bata seu recorde"): best_run -> run_money, best_perfect (seguidos) ->
## run_perfect, longest_hop -> run_distance (um run com aquele salto voou pelo menos isso); best_delivery fica.
## v4 -> v5 (2026-10-07): mundos paralelos — recordes viram {planeta: {id: valor}} (os atuais vao para "luna");
## current_planet passa a ser guardado de verdade (mundo liberado; senao "luna").
## v5 -> v6 (2026-10-07): minijogos — uma Estrada por mundo; as estrelas que existiam vao para a Lua (world_stars);
## paradas world_* somem (filtro da Estrada).
## Dicas aprendidas (2026-10-08, campo opcional sem mudar a versao: save sem ele = nenhuma dica vista), filtradas
## por TIP_IDS (= GameState.TIPS).
## Reputacao por ratinho (v14): rep_points {tipo: pontos}, validado pelos tipos da spec.
## Recordes pessoais guardados (GameState.RECORDS; saves antigos sem recordes comecam vazios).
## Dicas do comeco: motor e girar (Coach), "tente de novo" em figura (RetryHint: so na 1a batida do jogo; o id
## guarda o motivo dela) e os destaques de 1a visita (Spotlight: cartao, NAVE + botao MAPA, Mapa, abas novas da NAVE,
## liga/desliga das ajudas, 2o mundo) e os passeios da 1a vez (2026-10-09: Mapa, NAVE, abas AJUDAS e REPUTACAO;
## spot_back/spot_assists/spot_toggle/spot_tab_rep ficam so para saves antigos: nao sao mais mostrados).
const TIP_IDS := ["thrust", "rotate", "crash_vertical_rapido", "crash_fora_da_plataforma", "crash_horizontal_rapido",
		"crash_inclinado", "crash_sem_gas", "spot_offer", "spot_ship", "spot_map", "spot_back", "spot_assists",
		"spot_toggle", "spot_tab_rep", "spot_tab_fleet", "spot_world2", "tour_map", "tour_ship", "tour_assists", "tour_rep"]
const RECORD_IDS := ["run_money", "run_deliveries", "run_distance", "run_perfect", "best_delivery"]


## Monta o dicionario do save a partir do estado do jogo.
static func serialize(state: Dictionary) -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"spec_version": EconMath.spec.get("meta", {}).get("version", 0),
		"resources": state["resources"].duplicate(),
		"levels": state["levels"].duplicate(),
		"current_planet": state["current_planet"],
		"income_history": state["income_history"].duplicate(true),
		"stars": int(state.get("stars", 0)),
		"mission_nodes": state.get("mission_nodes", []).duplicate(),
		"missions_new": state.get("missions_new", {}).duplicate(),
		"road_reached": state.get("road_reached", []).duplicate(),
		"road_seen": state.get("road_seen", []).duplicate(),
		"rep_points": state.get("rep_points", {}).duplicate(),
		"world_stars": state.get("world_stars", {}).duplicate(),
		"runs_done": state["runs_done"],
		"play_seconds": state["play_seconds"],
		"settings": state["settings"].duplicate(),
		"records": state.get("records", {}).duplicate(),
		"tips": state.get("tips", []).duplicate(),
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
		"current_planet": "luna",                              # validado abaixo (precisa estar liberado)
		"income_history": [],
		"stars": maxi(0, int(_num(d.get("stars", 0)))),
		"mission_nodes": [],
		"missions_new": {},
		"road_reached": _filter_ids(d.get("road_reached", []), _road_ids()),
		"road_seen": _filter_ids(d.get("road_seen", []), _road_ids()),
		"rep_points": {},
		"runs_done": maxi(0, int(_num(d.get("runs_done", 0)))),
		"play_seconds": maxf(0.0, _num(d.get("play_seconds", 0.0))),
		"settings": d.get("settings", {}) if d.get("settings", {}) is Dictionary else {},
		"records": {},
		"world_stars": {},
		"tips": _filter_ids(d.get("tips", []), TIP_IDS),
	}
	var planet_ids: Array = EconMath.spec["planets"].map(func(p: Dictionary) -> String: return p["id"])
	var recs: Variant = d.get("records", {})
	for pid: Variant in (recs as Dictionary if recs is Dictionary else {}):
		if str(pid) in planet_ids and recs[pid] is Dictionary:
			st["records"][str(pid)] = _filter_numbers(recs[pid], RECORD_IDS, "recorde", warnings, false)
		else:
			warnings.append("recordes do mundo '%s' ignorados" % pid)
	var ws: Variant = d.get("world_stars", {})
	st["world_stars"] = _filter_numbers(ws if ws is Dictionary else {}, planet_ids, "estrelas do mundo", warnings, true)
	var cp := str(d.get("current_planet", "luna"))
	var prev := ""                                             # mundo liberado = o anterior esta completo
	var open_ids: Array = []
	for pid: String in planet_ids:
		if prev == "" or ("complete_" + prev) in st["road_reached"]:
			open_ids.append(pid)
		else:
			break
		prev = pid
	if cp in open_ids:
		st["current_planet"] = cp
	for rid: String in res_ids:
		if not st["resources"].has(rid):
			st["resources"][rid] = 0.0
	var node_ids: Array = EconMath.mission_spec().get("nodes", []).map(func(n: Dictionary) -> String: return n["id"])
	var nodes: Variant = d.get("mission_nodes", [])
	for n: Variant in (nodes if nodes is Array else []):
		if str(n) in node_ids and not str(n) in st["mission_nodes"]:
			st["mission_nodes"].append(str(n))
		elif not str(n) in node_ids:
			warnings.append("missao '%s' nao existe mais na spec: ignorada" % n)
	var kind_ids: Array = EconMath.mission_spec().get("kinds", []).map(func(k: Dictionary) -> String: return k["id"])
	st["missions_new"] = _filter_numbers(d.get("missions_new", {}), kind_ids, "missao nova", warnings, true)
	st["rep_points"] = _filter_numbers(d.get("rep_points", {}), kind_ids, "reputacao", warnings, true)
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
		"stars": int(state.get("stars", 0)),
		"nodes": (state.get("mission_nodes", []) as Array).size(),   # nos da arvore de missoes liberados
		"road": (state.get("road_reached", []) as Array).size(),     # paradas da Estrada alcancadas
		"road_total": EconMath.road().size(),
	}


## v1 -> v2: descarta o que era de prestigio/mundos (Poeira, loja, planetas, Expedicao, minerio). Os niveis e
## recursos que nao existem mais na spec ja caem no filtro de deserialize; a renda guardada da frota so com creditos.
static func _migrate(from_version: int, d: Dictionary) -> Dictionary:
	match from_version:
		1:
			return _from_v1(d)
		2:
			return _from_v2(d)
		3:
			return _from_v3(d)
		4:
			return _from_v4(d)
		5:
			return _from_v5(d)
	return d


static func _from_v1(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	for k: String in ["shop", "prestige_points", "prestige_pending", "unlocked", "cycle_earned", "reached_goal"]:
		out.erase(k)
	out["current_planet"] = "luna"
	out["save_version"] = 2
	return out


static func _from_v2(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	var nodes: Variant = d.get("mission_nodes", [])
	var spent := (nodes as Array).size() if nodes is Array else 0
	var cost := int(EconMath.mission_spec().get("stars", {}).get("unlock_cost", 3))
	out["stars"] = maxi(0, int(_num(d.get("stars", 0)))) + spent * cost
	var rec: Variant = out.get("records", {})
	if rec is Dictionary:
		(rec as Dictionary).erase("best_combo")
	out["save_version"] = 3
	return out


static func _from_v3(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	var rec: Variant = out.get("records", {})
	if rec is Dictionary:
		var r := rec as Dictionary
		for pair: Array in [["best_run", "run_money"], ["best_perfect", "run_perfect"], ["longest_hop", "run_distance"]]:
			if r.has(pair[0]):
				r[pair[1]] = maxf(_num(r[pair[0]]), _num(r.get(pair[1], 0.0)))
				r.erase(pair[0])
	out["save_version"] = 4
	return out


static func _from_v4(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	var rec: Variant = out.get("records", {})
	out["records"] = {"luna": rec} if rec is Dictionary and not (rec as Dictionary).is_empty() else {}
	out["save_version"] = 5
	return out


static func _from_v5(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	out["world_stars"] = {"luna": maxi(0, int(_num(d.get("stars", 0))))}
	out["save_version"] = 6
	return out


static func _road_ids() -> Array:
	return EconMath.road().map(func(r: Dictionary) -> String: return r["id"])


## Lista de ids de fora: so os que existem em allowed, sem repetir.
static func _filter_ids(src: Variant, allowed: Array) -> Array:
	var out: Array = []
	for x: Variant in (src if src is Array else []):
		if str(x) in allowed and not str(x) in out:
			out.append(str(x))
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
