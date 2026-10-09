## Pecas da nave que CRESCEM por degrau (ROADMAP 16.5; arte: art/src/sprites/lander_parts.py, skill pixel-art).
## Cada peca tem 4 versoes (0 = de serie). Versao a partir do degrau (nivel / STAGE) pela tabela de
## data/world.json > ship_parts. Voo: corpo em assets/sprites/lander_body_frames.tres (animacao b_<tanque><bocal><pernas>,
## idle com piscar) + chama em lander_flame_frames.tres (flame_<motor>, comeca na boca do bocal). Tela NAVE: atlas
## ship_poster.png (80x70, indice tanque*16 + bocal*4 + pernas) + ship_poster_flame.png (linha = motor, 4 quadros).
## Montagem (bocas e caixas das pecas do poster) em assets/sprites/lander_parts.json.
class_name ShipArt
extends RefCounted

const META_PATH := "res://assets/sprites/lander_parts.json"
## Niveis por degrau das pecas (fonte unica; RoadText.STAGE le daqui). Sem depender da UI: o Lander usa esta classe e os
## testes rodam sem autoloads.
const STAGE := 10
const PARTS: Array[String] = ["tank", "efficiency", "gear", "thrust"]

static var _meta: Dictionary = {}


static func meta() -> Dictionary:
	if _meta.is_empty():
		var f := FileAccess.open(META_PATH, FileAccess.READ)
		if f == null:
			push_error("lander_parts.json ausente")
			return {"tiers": 1, "flight": {"mouth": [21]}, "poster": {"mouth": [47], "grid": 8, "frame": [80, 70],
					"flame": [80, 60], "boxes": {}}}
		_meta = JSON.parse_string(f.get_as_text())
	return _meta


## Versao (0..3) de uma peca para o nivel dado.
static func tier(part: String, level: int) -> int:
	var cfg: Dictionary = WorldConfig.load_config().get("ship_parts", {})
	var table: Array = cfg.get("gear_stage_to_tier" if part == "gear" else "stage_to_tier", [0])
	var stage := maxi(level, 0) / STAGE
	return int(table[mini(stage, table.size() - 1)])


## Versao de cada peca a partir dos niveis das pecas (id -> nivel).
static func tiers(levels: Dictionary) -> Dictionary:
	var out := {}
	for p: String in PARTS:
		out[p] = tier(p, int(levels.get(p, 0)))
	return out


static func body_anim(t: Dictionary) -> StringName:
	return StringName("b_%d%d%d" % [int(t.get("tank", 0)), int(t.get("efficiency", 0)), int(t.get("gear", 0))])


static func flame_anim(t: Dictionary) -> StringName:
	return StringName("flame_%d" % int(t.get("thrust", 0)))


## Linha (y, a partir do canto de cima do sprite) onde a chama comeca: a boca do bocal da versao atual.
static func mouth(t: Dictionary, poster: bool = false) -> int:
	return int(meta()["poster" if poster else "flight"]["mouth"][int(t.get("efficiency", 0))])


## Recorte do corpo no atlas do poster.
static func poster_region(t: Dictionary) -> Rect2:
	var pm: Dictionary = meta()["poster"]
	var i := int(t.get("tank", 0)) * 16 + int(t.get("efficiency", 0)) * 4 + int(t.get("gear", 0))
	var w := int(pm["frame"][0])
	var h := int(pm["frame"][1])
	var g := int(pm["grid"])
	return Rect2((i % g) * w, (i / g) * h, w, h)


## Recorte do quadro da chama do poster (linha = versao do Motor).
static func poster_flame_region(t: Dictionary, frame: int) -> Rect2:
	var fs: Array = meta()["poster"]["flame"]
	return Rect2((frame % 4) * int(fs[0]), int(t.get("thrust", 0)) * int(fs[1]), int(fs[0]), int(fs[1]))


## Caixas da peca no poster (destaque do cartao): uma por lado nas pecas em par (tanques, pernas); vazio se nao houver.
static func poster_boxes(part: String, t: Dictionary) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var boxes: Dictionary = meta()["poster"].get("boxes", {})
	if boxes.has(part):
		for b: Array in boxes[part][int(t.get(part, 0))]:
			out.append(Rect2(b[0], b[1], b[2], b[3]))
	return out
