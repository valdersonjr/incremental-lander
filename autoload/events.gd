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
@warning_ignore("unused_signal")
signal planet_unlocked(planet_id: String)
