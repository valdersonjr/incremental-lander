## Piloto automatico para o modo --demo (verificacao sem teclado) — logica pura.
## Tres modos, como um bom piloto (e como o modelo da economy-balance assume: salto balistico):
##  1. decolagem: sobe na vertical ate sair do chao;
##  2. arco balistico: mira a velocidade que leva ao alvo sob gravidade e so corrige desvios (motor mais desligado);
##  3. frenagem e pouso: perto do alvo, cancela a velocidade horizontal e desce firme sobre a plataforma.
class_name Autopilot
extends RefCounted

var target: Dictionary = {}          # plataforma alvo {x, y, half_width} em px
var ridge: PackedVector2Array        # contorno do terreno (px)
var mode := "takeoff"
var _duty_acc := 0.0                 # acumulador sigma-delta (motor liga/desliga com "acelerador" medio)


## Retorna {"rotate": -1..1, "thrust": bool}. Unidades: pos em px, vel em m/s do modelo.
func control(pos_px: Vector2, vel_m: Vector2, rotation: float, params: Dictionary) -> Dictionary:
	var cfg: Dictionary = WorldConfig.load_config()
	var ppm := float(cfg["px_per_m"])
	var feet := float(cfg["lander"]["feet_offset_m"])
	var pos := pos_px / ppm
	var dx := float(target["x"]) / ppm - pos.x
	var pad_y := float(target["y"]) / ppm
	var height := pad_y - (pos.y + feet)                       # >0: acima da plataforma
	var alt := TerrainGen.height_at(ridge, pos_px.x) / ppm - (pos.y + feet)
	var g: float = params["gravity"]
	var thrust_max: float = params["thrust"]
	var a_net := maxf(thrust_max - g, 0.3)                    # desaceleracao vertical disponivel
	var brake_dist := vel_m.x * vel_m.x / (2.0 * 0.5 * maxf(thrust_max - g * 0.5, 0.5)) + 40.0
	var approach_alt := 40.0 + g * 8.0                          # altura de chegada do arco (m)

	var v_des := Vector2.ZERO
	var compensate_gravity := true
	var max_tilt := 0.9
	if mode == "takeoff" and (alt > 20.0 or absf(dx) < 60.0):
		mode = "arc"
	if mode == "arc" and absf(dx) < brake_dist:
		mode = "land"

	match mode:
		"takeoff":
			v_des = Vector2(0.0, -6.0)
		"arc":
			# velocidade que leva ao alvo em tempo T (tiro a ~45 graus): o proprio arco ja inclui a gravidade
			var t_flight := sqrt(2.0 * absf(dx) / g) + 1.0
			# mira um ponto ACIMA da plataforma (espaco para frear): queda = h_arc = vy*T + g*T^2/2
			var h_arc := height - approach_alt
			v_des = Vector2(dx / t_flight, (h_arc - 0.5 * g * t_flight * t_flight) / t_flight)
			compensate_gravity = false
		"land":
			v_des.x = clampf(dx * 0.3, -6.0, 6.0)
			if absf(dx) < 8.0:
				# perfil de parada: nunca descer mais rapido do que o motor consegue frear ate o chao
				var stop_v := sqrt(2.0 * a_net * 0.5 * maxf(height, 0.0))
				v_des.y = clampf(minf(height * 0.25, stop_v), 1.2, 8.0)
			else:
				# aproxima 30 m acima da plataforma OU do ponto mais alto do relevo ate ela (cristas, picos)
				var top := TerrainGen.highest_between(ridge, pos_px.x, float(target["x"])) / ppm - feet
				v_des.y = clampf((minf(pad_y, top) - 30.0 - pos.y) * 0.3, -4.0, 4.0)
			if absf(dx) < 12.0 and height < 25.0:
				max_tilt = 0.15

	var a_des := (v_des - vel_m) * 0.9
	var t_vec := a_des - Vector2(0.0, g) if compensate_gravity else a_des
	var rot_des := clampf(atan2(t_vec.x, -t_vec.y), -max_tilt, max_tilt)
	var err := wrapf(rot_des - rotation, -PI, PI)
	var nose := Vector2.UP.rotated(rotation)
	var thrust := false
	if absf(err) < 0.6:
		if compensate_gravity:
			# sigma-delta: liga o motor na fracao exata do tempo que a aceleracao pedida exige
			# (ex.: pairar com motor 10 em gravidade 5 = 50% do tempo), em vez de "sempre ligado"
			_duty_acc += clampf(t_vec.dot(nose) / thrust_max, 0.0, 1.0)
			if _duty_acc >= 1.0:
				_duty_acc -= 1.0
				thrust = true
		else:
			# no arco: so corrige desvios relevantes (economiza gas, como o salto balistico do modelo)
			thrust = t_vec.dot(nose) > maxf(1.0, 0.1 * v_des.length())
	return {"rotate": clampf(err * 4.0, -1.0, 1.0), "thrust": thrust}
