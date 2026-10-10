## Balao de uma parada da Estrada das Estrelas (clique na parada): figura (o ratinho de corpo inteiro ou o icone do
## premio), nome, o que traz e quanto falta (barra). Usado pelo Mapa (a Estrada mora so nele desde 2026-10-09; antes
## tambem no alto da NAVE, em todas as abas — usuario: "precisa so em 1 lugar").
class_name StopBalloon
extends PanelContainer

const TEXT_W := 170.0


func _ready() -> void:
	theme_type_variation = &"Balloon"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


## Monta o balao da parada stop_id e posiciona perto de anchor (coordenadas do pai), acima (above) ou abaixo dela,
## sem sair de area. Devolve false se a parada nao existe.
func show_stop(stop_id: String, anchor: Vector2, area: Vector2, above: bool) -> bool:
	var stop := EconMath.road_stop(stop_id)
	if stop.is_empty():
		return false
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	add_child(row)
	var pic := TextureRect.new()
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if str(stop["type"]) == "mission":                         # o ratinho de corpo inteiro
		var kind := str(RoadText._node(stop_id)["kind"])
		pic.texture = TalkArt.frames(kind, GameState.current_planet).get_frame_texture(&"idle", 0)
	else:
		pic.texture = RoadText.stop_icon(stop)
		pic.custom_minimum_size = Vector2(36, 36)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(pic)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 2)
	col.custom_minimum_size = Vector2(TEXT_W, 0)
	row.add_child(col)
	col.add_child(_label(RoadText.stop_name(stop) + (" (%d estrelas de dificuldade)" % RoadText.stop_star(stop)
			if RoadText.stop_star(stop) > 1 else "")))
	col.add_child(_label(RoadText.stop_desc(stop)))
	var need := int(stop["stars"])
	var have := GameState.stars_in()
	if GameState.road_reached.has(stop_id):
		col.add_child(_label("Você já tem!"))
	else:
		col.add_child(_label("Faltam %d estrelas (você tem %d). Cada entrega dá 1." % [need - have, have]))
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.theme_type_variation = &"XpBar"
		bar.custom_minimum_size = Vector2(TEXT_W, 6)
		bar.max_value = maxi(1, need)
		bar.value = have
		col.add_child(bar)
	visible = true
	reset_size()
	size = get_combined_minimum_size()
	var y := anchor.y - size.y - 8.0 if above else anchor.y + 30.0
	position = Vector2(clampf(anchor.x - size.x * 0.5, 4.0, area.x - size.x - 4.0), clampf(y, 4.0, area.y - size.y - 4.0))
	return true


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"BalloonLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.custom_minimum_size = Vector2(TEXT_W, 0)
	return l
