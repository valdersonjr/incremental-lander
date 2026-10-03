## Integracao da fisica do lander em unidades do modelo (m, s) — logica pura, testavel.
## Gas gasto = delta-v do motor / eficiencia (mesmo modelo "arcade" da economy-balance).
class_name LanderPhysics
extends RefCounted


## Um passo de integracao. Retorna {"velocity": Vector2 (m/s), "gas": float, "gas_used": float, "dv": float}.
## rotation: 0 = nariz para cima; y cresce para baixo (convencao do Godot).
## params: gravity (m/s2), thrust (m/s2), efficiency (m/s por gas), drag (1/s).
static func step(velocity: Vector2, rotation: float, thrusting: bool, gas: float,
		params: Dictionary, dt: float) -> Dictionary:
	var accel := Vector2(0.0, float(params["gravity"]))
	var gas_used := 0.0
	var dv := 0.0
	if thrusting and gas > 0.0:
		var thrust: float = params["thrust"]
		var eff: float = params["efficiency"]
		# fracao do passo com gas disponivel
		var burn_time := minf(dt, gas * eff / thrust)
		dv = thrust * burn_time
		gas_used = dv / eff
		accel += Vector2.UP.rotated(rotation) * thrust * (burn_time / dt)
	accel -= velocity * float(params.get("drag", 0.0))
	return {
		"velocity": velocity + accel * dt,
		"gas": maxf(0.0, gas - gas_used),
		"gas_used": gas_used,
		"dv": dv,
	}


## Arrasto (1/s) na altitude alt_m acima do relevo: o ar fica mais denso perto do chao (world.json atmosphere).
## planet_drag = drag do planeta na spec (0 = sem ar: Lua). Voo alto ~ drag_scale; rente ao chao soma ground_drag.
static func drag_at(planet_drag: float, alt_m: float, cfg: Dictionary) -> float:
	var atm: Dictionary = cfg["atmosphere"]
	var ground := float(atm["ground_drag"]) * exp(-maxf(alt_m, 0.0) / float(atm["scale_height_m"]))
	return planet_drag * (float(cfg["drag_scale"]) + ground)
