## Textos de cada tipo de missao para a interface (nao e economia; os nomes vem de EconMath.mission_kind(kind)["name"]).
## balloon(): fala curta do ratinho no cartao do pedido e na telinha "Novo amiguinho!" (2-3 palavras, para criancas).
## ask()/say_rule(): as duas linhas do balão do ratinho na janela de conversa do pedido (OfferPanel, 2026-10-07):
## o pedido e a regra falada (com a figura certo × errado ao lado).
## rule(): a regra em poucas palavras, embaixo do balao no cartao do pedido (o que fazer para ganhar).
## tip(): explicacao mais longa (tooltips do cartao e da aba PEDIDOS da oficina).
class_name MissionText
extends RefCounted

const BALLOON := {"simple": "Leva pra mim!", "heavy": "Tá pesado!", "soft": "Devagarinho!", "fast": "Rápido, derrete!",
		"passenger": "Me pega!", "taxi": "Me busca!", "tow": "Não deixa bater!", "double": "Duas regras!"}
const RULE := {"simple": "é só pousar na plataforma", "heavy": "nave pesada: sobe devagar",
		"soft": "pouse bem devagar", "fast": "chegue antes do relógio",
		"passenger": "passe devagar perto do ratinho", "taxi": "busque o ratinho e traga de volta",
		"tow": "a carga no cabo não pode bater"}
const ASK := {"simple": "Leva meu queijo pra vila?", "heavy": "Esse queijão é pesadão!",
		"soft": "Meu bolo é fofinho!", "fast": "Meu sorvete tá derretendo!",
		"passenger": "Socorro! Meu amigo se perdeu!", "taxi": "Busca meu amigo e traz ele aqui?",
		"tow": "Meu biscoito vai pendurado!", "double": "Tenho um pedido especial!"}
const SAY_RULE := {"simple": "É só pousar na plataforma.", "heavy": "Nave pesada: sobe devagar e gasta mais!",
		"soft": "Pousa bem devagarinho, senão amassa!", "fast": "Chega antes do relógio acabar!",
		"passenger": "Passa devagar pertinho pra ele pular!", "taxi": "Pousa lá pra ele entrar e volta!",
		"tow": "Não deixa ele bater no chão!"}
const TIP := {"simple": "entrega simples: é só pousar na plataforma",
		"heavy": "a nave fica pesada: sobe mais devagar e gasta mais gás",
		"soft": "pouse bem devagar (a velocidade de pouso fica mais baixa a cada estrela)",
		"fast": "chegue antes do relógio acabar (menos tempo a cada estrela)",
		"passenger": "passe devagar pertinho do ratinho perdido para ele pular na nave",
		"taxi": "táxi: pouse para buscar o ratinho e leve de volta",
		"tow": "a carga vai pendurada num cabo: não deixe bater no chão",
		"double": "duas regras juntas no mesmo pedido"}


## Fala do ratinho do pedido m ({kind, star, parts}); o taxi (passageiro com 2o trecho) tem fala propria.
static func balloon(m: Dictionary) -> String:
	return BALLOON.get(_key(m), BALLOON["simple"])


## Pedido falado pelo ratinho de m.
static func ask(m: Dictionary) -> String:
	return ASK.get(_key(m), ASK["simple"])


## Regra falada de m (Dupla: as regras curtas das partes juntas com " + ").
static func say_rule(m: Dictionary) -> String:
	if str(m.get("kind", "simple")) == "double":
		return rule(m)
	return SAY_RULE.get(_key(m), SAY_RULE["simple"])


## Regra curta do pedido m (Dupla: as duas regras juntas com " + ").
static func rule(m: Dictionary) -> String:
	var parts: Array = m.get("parts", [])
	if str(m.get("kind", "simple")) == "double" and not parts.is_empty():
		var lines: Array[String] = []
		for p: Dictionary in parts:
			lines.append(RULE.get(_key({"kind": p["kind"], "parts": [p]}), ""))
		return " + ".join(lines)
	return RULE.get(_key(m), RULE["simple"])


## Explicacao do pedido m (Dupla: as regras das partes, uma por linha).
static func tip(m: Dictionary) -> String:
	var parts: Array = m.get("parts", [])
	if str(m.get("kind", "simple")) == "double" and not parts.is_empty():
		var lines: Array[String] = []
		for p: Dictionary in parts:
			lines.append(TIP.get(_key({"kind": p["kind"], "parts": [p]}), ""))
		return "\n".join(lines)
	return TIP.get(_key(m), TIP["simple"])


## Explicacao do tipo kind sem pedido concreto (aba PEDIDOS: passageiro descreve as duas formas).
static func kind_tip(kind: String) -> String:
	if kind == "passenger":
		return "estrela 1: %s; 2 e 3: %s" % [TIP["passenger"], TIP["taxi"]]
	return TIP.get(kind, "")


static func _key(m: Dictionary) -> String:
	var kind := str(m.get("kind", "simple"))
	if kind == "passenger" and not (m.get("parts", []) as Array).is_empty() and EconMath.mission_leg2(m) > 0.0:
		return "taxi"
	return kind
