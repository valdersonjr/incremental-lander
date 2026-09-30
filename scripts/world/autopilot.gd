## Piloto automatico simples para o modo --demo (verificacao sem teclado) — logica pura.
## Controle por velocidade desejada: cruza acima do relevo e desce devagar sobre a plataforma alvo.
class_name Autopilot
extends RefCounted

var target: Dictionary = {}          # plataforma alvo {x, y, half_width} em px
var ridge: PackedVector2Array        # contorno do terreno (px) para achar a altura de cruzeiro
var clearance_m := 60.0


## Retorna {"rotate": -1..1, "thrust": bool}. Unidades: pos em px, vel em m/s do modelo.
func control(pos_px: Vector2, vel_m: Vector2, rotation: float, params: Dictionary) -> Dictionary:
	var cfg: Dictionary = WorldConfig.load_config()
	var feet := float(cfg["lander"]["feet_offset_m"])
	var pos := pos_px / float(cfg["px_per_m"])
	var tx := float(target["x"]) / float(cfg["px_per_m"])
	var pad_y := float(target["y"]) / float(cfg["px_per_m"])
	var dx := tx - pos.x
	var height := pad_y - (pos.y + feet)
	var g: float = params["gravity"]
	var thrust_max: float = params["thrust"]

	var ground_m := TerrainGen.height_at(ridge, pos_px.x) / float(cfg["px_per_m"])
	var alt := ground_m - (pos.y + feet)            # altura acima do terreno logo abaixo
	var v_des := Vector2.ZERO
	if alt < 25.0 and absf(dx) > 30.0:
		v_des = Vector2(0.0, -6.0)                  # decolagem: sobe na vertical antes de avancar
	elif absf(dx) > 30.0:
		var top := _highest_between(pos.x * float(cfg["px_per_m"]), float(target["x"])) / float(cfg["px_per_m"])
		var cruise_y := top - clearance_m
		v_des.x = clampf(dx * 0.08, -25.0, 25.0)
		v_des.y = clampf((cruise_y - pos.y) * 0.3, -8.0, 6.0)
	else:
		v_des.x = clampf(dx * 0.3, -3.0, 3.0)
		v_des.y = clampf(height * 0.15, 0.6, 5.0) if absf(dx) < 8.0 else clampf((pad_y - 30.0 - pos.y) * 0.3, -4.0, 4.0)

	var a_des := (v_des - vel_m) * 0.9
	var t_vec := a_des - Vector2(0.0, g)          # empuxo necessario (total = gravidade + empuxo)
	var max_tilt := 0.15 if (absf(dx) < 12.0 and height < 25.0) else 0.9
	var rot_des := clampf(atan2(t_vec.x, -t_vec.y), -max_tilt, max_tilt)
	var err := wrapf(rot_des - rotation, -PI, PI)
	var nose := Vector2.UP.rotated(rotation)
	var thrust := t_vec.dot(nose) > 0.35 * thrust_max and absf(err) < 0.6
	return {"rotate": clampf(err * 4.0, -1.0, 1.0), "thrust": thrust}


func _highest_between(x0: float, x1: float) -> float:
	var top := INF
	var lo := minf(x0, x1)
	var hi := maxf(x0, x1)
	for p in ridge:
		if p.x >= lo and p.x <= hi:
			top = minf(top, p.y)
	return top if top < INF else float(target["y"])
