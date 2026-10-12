## Regras de pouso: batida x pouso e qualidade q (0..1) — logica pura, testavel.
## q define o pagamento (EconMath.contract_pay) e calibra o 'skill' da economia via telemetria.
class_name LandingRules
extends RefCounted


## Tolerancias efetivas (trem de pouso amplia: tolerancia x gear^gear_exp).
static func tolerances(landing: Dictionary, gear: float) -> Dictionary:
	var k := pow(maxf(gear, 0.01), float(landing["gear_exp"]))
	return {
		"max_vy": float(landing["max_vy"]) * k,
		"max_vx": float(landing["max_vx"]) * k,
		"max_tilt": float(landing["max_tilt"]) * k,
	}


## Motivo da batida ou "" se o pouso e valido. vy > 0 = descendo (m/s), tilt em rad.
static func crash_reason(vy: float, vx: float, tilt: float, on_pad: bool, tol: Dictionary) -> String:
	if not on_pad:
		return "fora_da_plataforma"
	if vy > tol["max_vy"]:
		return "vertical_rapido"
	if absf(vx) > tol["max_vx"]:
		return "horizontal_rapido"
	if absf(tilt) > tol["max_tilt"]:
		return "inclinado"
	return ""


## Qualidade 0..1 de um pouso valido. center_offset em fracao da meia-largura da plataforma (0 = centro).
static func quality(vy: float, vx: float, tilt: float, center_offset: float, tol: Dictionary,
		weights: Dictionary) -> float:
	var t_vy := 1.0 - clampf(maxf(vy, 0.0) / tol["max_vy"], 0.0, 1.0)
	var t_vx := 1.0 - clampf(absf(vx) / tol["max_vx"], 0.0, 1.0)
	var t_tilt := 1.0 - clampf(absf(tilt) / tol["max_tilt"], 0.0, 1.0)
	var t_c := 1.0 - clampf(absf(center_offset), 0.0, 1.0)
	var q := float(weights["vy"]) * t_vy + float(weights["vx"]) * t_vx \
			+ float(weights["tilt"]) * t_tilt + float(weights["center"]) * t_c
	var total := float(weights["vy"]) + float(weights["vx"]) + float(weights["tilt"]) + float(weights["center"])
	return clampf(q / total, 0.0, 1.0)


## Pouso perfeito (Reputacao: a proxima entrega vale +bonus): reto e macio, pelas tolerancias BASE (sem o trem de
## pouso, que so evita batida). landing = world.json > landing (perfect.vy_frac, perfect.tilt_frac).
static func is_perfect(vy: float, tilt: float, landing: Dictionary) -> bool:
	var p: Dictionary = landing.get("perfect", {})
	if p.is_empty():
		return false
	return maxf(vy, 0.0) <= float(landing["max_vy"]) * float(p["vy_frac"]) \
			and absf(tilt) <= float(landing["max_tilt"]) * float(p["tilt_frac"])


## Raspao (world.json landing.scrape): {"ok": bool, "velocity": Vector2}. vel em m/s (y para baixo), normal unitaria
## saindo do chao. Impacto = velocidade contra o chao; quica se impacto <= max_mps x gear^gear_exp e (dentro da
## carencia ou amassados < per_hop). Quicar: normal x restitution (no minimo min_out_mps), resto x friction.
static func scrape_bounce(vel: Vector2, normal: Vector2, gear: float, scrapes: int, grace: bool,
		sc: Dictionary) -> Dictionary:
	var vn := vel.dot(normal)
	var impact := maxf(-vn, 0.0)
	var limit := float(sc["max_mps"]) * pow(maxf(gear, 0.01), float(sc["gear_exp"]))
	if impact > limit or (not grace and scrapes >= int(sc["per_hop"])):
		return {"ok": false, "velocity": vel}
	var tangent := (vel - normal * vn) * float(sc["friction"])
	var out := maxf(impact * float(sc["restitution"]), float(sc["min_out_mps"]))
	return {"ok": true, "velocity": tangent + normal * out}


## Batida num obstaculo do ceu (sky_obstacles): sempre quica (sem limite de velocidade; o limite e o numero de
## amassados, conferido pela nave). Mesma resposta do raspao: normal x restitution (minimo min_out_mps), resto x friction.
static func obstacle_bounce(vel: Vector2, normal: Vector2, sc: Dictionary) -> Vector2:
	var vn := vel.dot(normal)
	var impact := maxf(-vn, 0.0)
	var tangent := (vel - normal * vn) * float(sc["friction"])
	return tangent + normal * maxf(impact * float(sc["restitution"]), float(sc["min_out_mps"]))
