## Event bus: sinais globais entre ramos distantes da arvore (skill godot-dev). Sem estado.
## Sinais carregam dados (ids, numeros), nunca nos.
extends Node

@warning_ignore("unused_signal")
signal resources_changed(resource_id: String, amount: float)
@warning_ignore("unused_signal")
signal run_started(planet_id: String)
@warning_ignore("unused_signal")
signal run_finished(summary: Dictionary)
@warning_ignore("unused_signal")
signal upgrade_bought(upgrade_id: String, level: int)
## Estrelas de missao mudaram (ganhou numa entrega ou gastou liberando).
@warning_ignore("unused_signal")
signal stars_changed(amount: int)
## Parada da Estrada das Estrelas alcancada agora (GameState._check_road).
@warning_ignore("unused_signal")
signal road_reached(stop_id: String)
## Subiu o nivel de reputacao com um ratinho (tipo de missao) — festa no voo e na PROGRESSAO.
@warning_ignore("unused_signal")
signal reputation_up(kind: String, level: int)
## Opcoes mudaram (volumes, filtro CRT): quem mostra algo das opcoes se atualiza.
@warning_ignore("unused_signal")
signal settings_changed
