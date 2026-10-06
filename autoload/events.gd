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
## Liberou um no da arvore de missoes (economy.json contracts.missions.nodes).
@warning_ignore("unused_signal")
signal mission_unlocked(node_id: String)
## Opcoes mudaram (volumes, filtro CRT): quem mostra algo das opcoes se atualiza.
@warning_ignore("unused_signal")
signal settings_changed
