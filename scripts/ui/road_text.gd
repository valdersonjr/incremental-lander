## Nome, figura e frase de cada parada da Estrada das Estrelas (EconMath.road) e das pecas da nave — para a tela
## PROGRESSAO (logica pura de texto/figura; numeros vem da spec).
class_name RoadText
extends RefCounted

## O que cada habilidade faz (a tecla vem do mapa de teclas).
const ABILITY_TIP := {"stabilizer": "a nave volta a ficar de pé sozinha", "turbo": "motor com o dobro da força"}
## O que cada ajuda de voo faz (frase longa: balao/tooltip) e o resumo curto (cartao da aba AJUDAS).
const ASSIST_TIP := {
	"nav_arrow": "uma setinha perto da nave aponta para onde pousar",
	"nav_color": "a setinha muda de cor: azul longe, amarela no meio, verde chegando",
	"nav_trail": "pontinhos mostram o melhor caminho logo à frente",
	"nav_route": "pontinhos mostram o melhor caminho inteiro, de plataforma a plataforma",
	"land_shadow": "uma sombra no chão mostra a altura da nave",
	"land_level": "perto do chão, uma linha mostra se a nave está reta (verde) ou torta (vermelha)",
	"land_predict": "mostra onde a nave cai se soltar o motor: X verde = pouso bom",
	"gas_need": "uma marquinha na barra mostra quanto gás sobra ao chegar",
}
const ASSIST_SHORT := {
	"nav_arrow": "seta aponta o pouso", "nav_color": "a seta muda de cor perto do pouso",
	"nav_trail": "pontinhos do melhor caminho", "nav_route": "o caminho inteiro",
	"land_shadow": "sombra mostra a altura", "land_level": "linha mostra se está reta",
	"land_predict": "X mostra onde vai cair", "gas_need": "mostra se o gás dá",
}
## Pecas da nave (aba NAVE): icone da interface e o que melhora, em palavras de crianca.
const PARTS := ["thrust", "tank", "efficiency", "gear"]
const PART_ICON := {"thrust": "thrust", "tank": "tank", "efficiency": "efficiency", "gear": "gear"}
const PART_DOES := {"thrust": "sobe mais fácil", "tank": "voa mais longe", "efficiency": "gasta menos gás",
		"gear": "pousa mais forte"}
## Nome do degrau da peca (algarismo comum: crianca de 6 anos nao le romano).
const STAGE_NAMES := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
## Niveis por degrau das pecas (festinha e a peca cresce no desenho a cada degrau).
const STAGE := 10


## Nome curto da parada (2 linhas no maximo no no da estrada).
static func stop_name(stop: Dictionary) -> String:
	var id := str(stop["id"])
	match str(stop["type"]):
		"start":
			return "Mineiro"
		"final":
			return "Lua completa!"
		"mission":
			return str(EconMath.mission_kind(_node(id)["kind"])["name"])
		"landscape":
			return str(_land(id).get("name", id))
		"world":
			return str(EconMath._find("planets", EconMath.world_of_stop(stop)).get("name", id))
		"complete":                                            # v17: ultima parada da Estrada do mundo
			return "Mundo completo!"
	return str(EconMath._find("upgrades", id).get("name", id))


## Estrelas da missao da parada (0 = nao e ratinho).
static func stop_star(stop: Dictionary) -> int:
	return int(_node(str(stop["id"])).get("star", 0)) if str(stop["type"]) == "mission" else 0


## Figura da parada (24x24 do atlas kids ou 12x12 da interface).
static func stop_icon(stop: Dictionary) -> Texture2D:
	var id := str(stop["id"])
	match str(stop["type"]):
		"start":
			return UiKit.kid("rat_simple")
		"final":
			return UiKit.kid("star_on")
		"mission":
			return TalkArt.face(str(_node(id)["kind"]))
		"landscape":
			return UiKit.kid(id)
		"complete":
			return UiKit.kid("trophy")
		"world":
			return UiKit.kid("world_" + EconMath.world_of_stop(stop)) if UiKit.has_kid("world_" + EconMath.world_of_stop(stop)) \
					else UiKit.kid("mystery")
	match id:
		"stabilizer", "turbo":
			return CargoArt.tex(id)
		"fleet":
			return UiKit.kid("drones")
		"autopilot":
			return UiKit.icon("autopilot")
		"gas_need":
			return UiKit.icon("gas")
	return UiKit.kid(str({"nav_color": "arrow", "nav_trail": "dist_2", "nav_route": "dist_3", "land_shadow": "pad_normal",
			"land_level": "pad_narrow", "land_predict": "cross"}.get(id, "mystery")))


## Frase do balao: o que o premio traz.
static func stop_desc(stop: Dictionary) -> String:
	var id := str(stop["id"])
	match str(stop["type"]):
		"start":
			return "O ratinho mineiro: entregas simples, perto, no meio ou longe. Começa aqui!"
		"final":
			return "Você completou a Lua!"
		"mission":
			var node := _node(id)
			var kind := str(node["kind"])
			var star := int(node["star"])
			if kind == "double":
				return "Novo amiguinho! Duas regras juntas no mesmo pedido: paga muito!"
			var m := {"kind": kind, "star": star, "parts": [{"kind": kind, "star": star}]}
			if star > 1:
				return "Pedido com %d estrelas: mais difícil e paga mais! %s" % [star, MissionText.say_rule(m)]
			return "Novo amiguinho! %s %s" % [MissionText.ask(m), MissionText.say_rule(m)]
		"world":
			return "Novo mundo! Voe em %s: cada mundo tem os seus recordes." % stop_name(stop)
		"complete":
			var nxt := EconMath.next_world(id.substr(9))
			if nxt == "":
				return "Você completou a viagem inteira!"
			return "Mundo completo! Abre: %s." % str(EconMath._find("planets", nxt).get("name", nxt))
		"landscape":
			var d := str(_land(id).get("desc", ""))
			return "Nova paisagem! " + d.left(1).to_upper() + d.substr(1)
		"unlock":
			return "Libera: " + ("drones que fazem entregas sozinhos e trazem moedas" if id == "fleet"
					else "os drones trazem mais moedas")
	if ABILITY_TIP.has(id):
		return "Habilidade: " + str(ABILITY_TIP[id])
	return "Ajuda de voo: " + str(ASSIST_TIP.get(id, ""))


## Degrau (0..) de uma peca no nivel lv.
static func stage_of(level: int, max_level: int) -> int:
	return mini(level / STAGE, maxi(0, ceili(float(max_level) / STAGE) - 1))


## Paisagem da parada "land_<id>" (world.json terrain.landscapes).
static func _land(stop_id: String) -> Dictionary:
	return (WorldConfig.load_config()["terrain"]["landscapes"] as Dictionary).get(stop_id.substr(5), {})


static func _node(id: String) -> Dictionary:
	for n: Dictionary in EconMath.mission_spec().get("nodes", []):
		if n["id"] == id:
			return n
	return {}
