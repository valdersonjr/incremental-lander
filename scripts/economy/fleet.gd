## Frota de drones (logica pura, testavel): cada drone repete as rotas do jogador com eficiencia `autopilot`.
## Renda da frota = EconMath.fleet_income_per_s(renda media do jogador por s, stats) — formula da spec.
class_name Fleet
extends RefCounted

const HISTORY := 5     # runs usados na media da renda do jogador


## Renda media do jogador por segundo (do modelo), por recurso, nos ultimos HISTORY runs.
## history: Array de {"earned": {recurso: qtd}, "seconds": float}.
static func average_income(history: Array) -> Dictionary:
	var tot := {}
	var secs := 0.0
	for h: Dictionary in history.slice(maxi(0, history.size() - HISTORY)):
		secs += float(h["seconds"])
		for res: String in h["earned"]:
			tot[res] = float(tot.get(res, 0.0)) + float(h["earned"][res])
	var avg := {}
	if secs > 0.0:
		for res: String in tot:
			avg[res] = float(tot[res]) / secs
	return avg


## Quanto a frota rende em `seconds` (do modelo), por recurso.
static func payout(stats: Dictionary, history: Array, seconds: float) -> Dictionary:
	var out := {}
	var avg := average_income(history)
	for res: String in avg:
		var v := EconMath.fleet_income_per_s(float(avg[res]), stats) * seconds
		if v > 0.0:
			out[res] = v
	return out
