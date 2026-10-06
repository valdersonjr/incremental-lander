## Carga no cabo (missao "Cabo", v12; antes o queijao rebocado) — logica pura, testavel.
## Padrao Thrust/Solar Jetman: a carga e um ponto com massa preso por um cabo (restricao de comprimento MAXIMO:
## frouxo quando perto, esticado puxa os dois). Cada passo: gravidade -> move -> chao (quica, rola; bater forte
## racha o queijo) -> cabo (corrige a posicao da carga e troca impulso com a nave na direcao do cabo).
## Posicoes em px do mundo, velocidades em m/s do modelo (como o Lander). Config: world.json missions.tow (+ levels por
## estrela: cabo e massa).
class_name CargoTow
extends RefCounted

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var damaged := false                 # bateu no chao rapido demais (falhou a regra da carga)
var spin := 0.0                      # rotacao acumulada (rad) para a roda girar quando rola/voa
var rope_px := 26.0
var radius_px := 6.0
var mass := 0.6                      # relativa a nave (1)
var _cfg: Dictionary = {}


## Carga apoiada no chao, atras da nave (lado oposto ao destino), com o cabo frouxo. star = estrela da missao Cabo
## (cabo e massa de missions.tow.levels).
static func create(anchor: Vector2, ridge: PackedVector2Array, dir: int, star: int = 2) -> CargoTow:
	var t := CargoTow.new()
	t._cfg = WorldConfig.load_config()["missions"]["tow"]
	var lv: Array = t._cfg["levels"]
	var level: Dictionary = lv[clampi(star, 1, lv.size()) - 1]
	t.rope_px = WorldConfig.m_to_px(float(level["rope_m"]))
	t.radius_px = WorldConfig.m_to_px(float(t._cfg["radius_m"]))
	t.mass = float(level["mass"])
	var x := anchor.x - float(dir) * (t.rope_px * 0.7)
	t.pos = Vector2(x, TerrainGen.height_at(ridge, x) - t.radius_px)
	return t


## Avanca dt_m segundos do modelo. anchor = ponto do cabo na nave (px), anchor_vel = velocidade da nave (m/s).
## anchor_free = a nave esta voando (recebe o puxao); pousada ela e fixa. Devolve a mudanca de velocidade da nave.
func step(anchor: Vector2, anchor_vel: Vector2, dt_m: float, gravity: float, ridge: PackedVector2Array,
		anchor_free: bool) -> Vector2:
	var ppm := WorldConfig.m_to_px(1.0)
	vel.y += gravity * dt_m
	pos += vel * ppm * dt_m
	_ground(ridge, dt_m, true)
	var dv_anchor := Vector2.ZERO
	var d := pos - anchor
	var dist := d.length()
	if dist > rope_px and dist > 0.001:
		var n := d / dist
		var vr := (vel - anchor_vel).dot(n)                    # > 0: afastando (o cabo segura)
		if vr > 0.0:
			if anchor_free:
				var j := vr / (1.0 / mass + 1.0)               # impulso dividido pelas massas (nave = 1)
				vel -= n * (j / mass)
				dv_anchor = n * j
			else:
				vel -= n * vr
		pos = anchor + n * rope_px
		_ground(ridge, dt_m, false)
	spin += vel.x * dt_m * ppm / maxf(radius_px, 1.0)
	return dv_anchor


## true se a carga esta encostada no relevo.
func on_ground(ridge: PackedVector2Array) -> bool:
	return pos.y >= TerrainGen.height_at(ridge, pos.x) - radius_px - 0.5


## Encosta no chao: quica (bounce), atrito (friction por segundo do modelo); impacto > break_speed racha.
func _ground(ridge: PackedVector2Array, dt_m: float, judge: bool) -> void:
	var g := TerrainGen.height_at(ridge, pos.x) - radius_px
	if pos.y <= g:
		return
	pos.y = g
	var impact := maxf(vel.y, 0.0)
	if judge and impact > float(_cfg["break_speed"]):
		damaged = true
	vel.y = -impact * float(_cfg["bounce"]) if impact > 0.8 else minf(vel.y, 0.0)
	vel.x *= pow(float(_cfg["friction"]), dt_m)
