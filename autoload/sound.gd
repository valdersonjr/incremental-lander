## Sons do jogo (arte sonora da skill sound-design: audio/src/** -> assets/audio/**).
## One-shots: Sound.ui(nome[, db, pitch]) no bus UI; Sound.sfx(nome[, db, pitch]) no bus SFX (cristal: sobe um grau
## por cristal do mesmo salto; combo: sobe com o tamanho do combo). Variacoes + pitch/volume aleatorios vem dos
## AudioStreamRandomizer (.tres).
## Gramatica da interface (auditoria de som 2026-10-09): "move" quando o foco anda pelo teclado/controle (automatico,
## via Viewport.gui_focus_changed logo depois de uma seta/Tab), "click" confirma, Sound.back() volta/fecha, "denied"
## nega, "pop" balao/aviso aparecendo, Sound.tally(i) tique da contagem (sobe grau a grau na escala).
## Trilha: Sound.music("title"|"flight"|"", mundo) no bus Music e Sound.ambience(planeta|"") no bus Ambience, com
## crossfade (loops; tocar o que ja toca nao reinicia). O voo toca a base + a camada do mundo (layer_<mundo>.wav) juntas
## num AudioStreamSynchronized (o mesmo tema, instrumento de cada mundo). Sound.muffle(true) abafa musica e ambiencia
## (pausa). Jingles: Sound.jingle(nome) no bus SFX, um por vez (o novo corta o anterior) e a musica abaixa enquanto
## toca. Liberar missao toca "unlock" pelo Events. Propulsor, jatinhos de giro e alarme de gas moram no Lander; os
## loops dos mundos (gelo, vento, bolhas) no Flight.
extends Node

const STREAMS := {
	"click": "res://assets/audio/ui/click.tres",
	"buy": "res://assets/audio/ui/buy.tres",
	"denied": "res://assets/audio/ui/denied.wav",
	"move": "res://assets/audio/ui/move.tres",
	"back": "res://assets/audio/ui/back.wav",
	"pop": "res://assets/audio/ui/pop.wav",
	"tally": "res://assets/audio/ui/tally.wav",
	"landing_heavy": "res://assets/audio/sfx/landing_heavy.wav",
	"crash_soft": "res://assets/audio/sfx/crash_soft.wav",
	"splash": "res://assets/audio/sfx/splash.wav",
	"sputter": "res://assets/audio/sfx/sputter.wav",
	"chest": "res://assets/audio/sfx/chest.wav",
	"gas_glug": "res://assets/audio/sfx/gas_glug.wav",
	"gift_coin": "res://assets/audio/sfx/gift_coin.wav",
	"squeak": "res://assets/audio/sfx/squeak.wav",
	"target_hit": "res://assets/audio/sfx/target_hit.wav",
	"oops": "res://assets/audio/sfx/oops.wav",
	"retry": "res://assets/audio/sfx/retry.wav",
	"aboard": "res://assets/audio/sfx/aboard.wav",
	"world_arrive": "res://assets/audio/sfx/world_arrive.wav",
	"summary_end": "res://assets/audio/sfx/summary_end.wav",
	"record": "res://assets/audio/sfx/record.wav",
	"landing": "res://assets/audio/sfx/landing.tres",
	"crash": "res://assets/audio/sfx/crash.wav",
	"delivered": "res://assets/audio/sfx/delivered.wav",
	"crystal_1": "res://assets/audio/sfx/crystal_1.wav",
	"crystal_2": "res://assets/audio/sfx/crystal_2.wav",
	"crystal_3": "res://assets/audio/sfx/crystal_3.wav",
	"combo_2": "res://assets/audio/sfx/combo_2.wav",
	"combo_3": "res://assets/audio/sfx/combo_3.wav",
	"combo_4": "res://assets/audio/sfx/combo_4.wav",
	"combo_5": "res://assets/audio/sfx/combo_5.wav",
	"star": "res://assets/audio/sfx/star.wav",
	"boing_1": "res://assets/audio/sfx/boing_1.wav",
	"boing_2": "res://assets/audio/sfx/boing_2.wav",
	"boing_3": "res://assets/audio/sfx/boing_3.wav",
	"bump": "res://assets/audio/sfx/bump.wav",
	"sheep_1": "res://assets/audio/sfx/sheep_1.wav",
	"sheep_2": "res://assets/audio/sfx/sheep_2.wav",
	"sheep_3": "res://assets/audio/sfx/sheep_3.wav",
	"sheep_4": "res://assets/audio/sfx/sheep_4.wav",
	"sheep_5": "res://assets/audio/sfx/sheep_5.wav",
	"pass_1": "res://assets/audio/sfx/pass_1.wav",
	"pass_2": "res://assets/audio/sfx/pass_2.wav",
	"pass_3": "res://assets/audio/sfx/pass_3.wav",
	"milestone": "res://assets/audio/sfx/milestone.wav",
	"unlock": "res://assets/audio/sfx/unlock.wav",
	"goal": "res://assets/audio/sfx/goal.wav",
}
const MUSIC := {"title": "res://assets/audio/music/title.wav", "flight": "res://assets/audio/music/flight.wav"}
const LAYER_DIR := "res://assets/audio/music/layer_%s.wav"
const AMBIENCE_DIR := "res://assets/audio/ambience/%s.wav"
## Cursor: o mais baixo da interface (toca a cada seta; "quase silencioso", padrao de UI).
const MOVE_DB := -7.0
## Tique da contagem: graus da pentatonica (semitons acima de D6); passou do fim, fica no ultimo.
const TALLY_STEPS: Array[int] = [0, 2, 4, 7, 9, 12, 14, 16, 19]
const TALLY_DB := -5.0
## Pausa: musica e ambiencia abafadas (passa-baixa) — o jogo "fica de lado" sem silenciar.
const MUFFLE_HZ := 700.0
const OPEN_HZ := 20000.0
const NAV_ACTIONS: Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"]
const FADE_S := 1.2
const SILENT_DB := -40.0
## Quanto a musica abaixa enquanto um jingle toca (dB).
const DUCK_DB := -9.0
const VOICES := 8

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: Array[AudioStreamPlayer] = []                  # 2 para o crossfade; _music[0] = a que toca
var _ambience: Array[AudioStreamPlayer] = []
var _music_name := ""
var _ambience_name := ""
var _jingle: AudioStreamPlayer
var _duck: Tween
var _duck_fx: AudioEffectAmplify
var _fades: Dictionary = {}                                # 0 musica / 1 ambiencia -> tween do crossfade
var _muffle_fx: Array[AudioEffectLowPassFilter] = []       # um por bus (Music, Ambience)
var _muffle: Tween
var _nav_frame := -10                                      # quadro da ultima seta/Tab (foco que anda por ela soa "move")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS                    # cliques do menu de pausa tocam com o jogo pausado
	for i in VOICES:
		_players.append(_new_player(&"SFX"))
	for i in 2:
		_music.append(_new_player(&"Music"))
		_ambience.append(_new_player(&"Ambience"))
	_jingle = _new_player(&"SFX")
	_jingle.finished.connect(_unduck)
	var bus := AudioServer.get_bus_index(&"Music")
	if bus >= 0:
		_duck_fx = AudioEffectAmplify.new()
		AudioServer.add_bus_effect(bus, _duck_fx)
	for b: StringName in [&"Music", &"Ambience"]:
		var idx := AudioServer.get_bus_index(b)
		if idx >= 0:
			var lp := AudioEffectLowPassFilter.new()
			lp.cutoff_hz = OPEN_HZ
			AudioServer.add_bus_effect(idx, lp)
			AudioServer.set_bus_effect_enabled(idx, AudioServer.get_bus_effect_count(idx) - 1, false)
			_muffle_fx.append(lp)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	Events.road_reached.connect(func(_n: String) -> void: jingle("unlock"))      # parada nova na Estrada das Estrelas


## Seta/Tab: marca o quadro; o foco que mudar logo depois foi o jogador navegando (grab_focus de tela nova nao soa).
func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	for a: StringName in NAV_ACTIONS:
		if event.is_action_pressed(a, true):
			_nav_frame = Engine.get_process_frames()
			return


func _on_focus_changed(_node: Control) -> void:
	if Engine.get_process_frames() - _nav_frame <= 1:
		ui("move", MOVE_DB)


## Voltar/fechar/cancelar (desce: o contrario do clique de confirmar).
func back() -> void:
	ui("back")


## Tique n da contagem (0, 1, 2...): cada um um grau acima na pentatonica.
func tally(n: int) -> void:
	ui("tally", TALLY_DB, pow(2.0, float(TALLY_STEPS[mini(n, TALLY_STEPS.size() - 1)]) / 12.0))


## Amostra do volume que o jogador acabou de mudar, tocada no proprio bus (Musica/Ambiencia ja estao tocando).
func preview(bus: String) -> void:
	match bus:
		"SFX":
			_play("crystal_2", &"SFX")
		"Music", "Ambience":
			pass                                               # a faixa que toca ja e a amostra
		_:
			ui("click")


## Pausa: abafa musica e ambiencia (passa-baixa que fecha em 0,25 s); false volta ao normal.
func muffle(on: bool) -> void:
	if _muffle != null:
		_muffle.kill()
	if _muffle_fx.is_empty():
		return
	for b: StringName in [&"Music", &"Ambience"]:
		var idx := AudioServer.get_bus_index(b)
		if idx >= 0 and on:
			AudioServer.set_bus_effect_enabled(idx, AudioServer.get_bus_effect_count(idx) - 1, true)
	_muffle = create_tween().set_parallel(true)
	for lp: AudioEffectLowPassFilter in _muffle_fx:
		_muffle.tween_property(lp, "cutoff_hz", MUFFLE_HZ if on else OPEN_HZ, 0.25 if on else 0.4) \
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if not on:
		_muffle.chain().tween_callback(func() -> void:
			for b: StringName in [&"Music", &"Ambience"]:
				var idx := AudioServer.get_bus_index(b)
				if idx >= 0:
					AudioServer.set_bus_effect_enabled(idx, AudioServer.get_bus_effect_count(idx) - 1, false))


func _new_player(bus: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _exit_tree() -> void:
	for p: AudioStreamPlayer in _players + _music + _ambience + [_jingle]:
		p.stop()
		p.stream = null
	for t: Tween in [_duck, _muffle] + _fades.values():
		if t != null:
			t.kill()
	for b: StringName in [&"Music", &"Ambience"]:
		var bi := AudioServer.get_bus_index(b)
		for i in range(AudioServer.get_bus_effect_count(bi) - 1, -1, -1):
			var fx := AudioServer.get_bus_effect(bi, i)
			if bi >= 0 and fx is AudioEffectLowPassFilter and _muffle_fx.has(fx as AudioEffectLowPassFilter):
				AudioServer.remove_bus_effect(bi, i)
	_muffle_fx.clear()
	var bus := AudioServer.get_bus_index(&"Music")
	for i in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
		if bus >= 0 and AudioServer.get_bus_effect(bus, i) == _duck_fx:
			AudioServer.remove_bus_effect(bus, i)
	_duck_fx = null
	_cache.clear()
	UiKit.clear_cache()
	CargoArt.clear_cache()
	MinigameArt.clear_cache()


## Musica de fundo (loop) com crossfade; "" silencia. A mesma que ja toca continua de onde estava. O voo leva o mundo:
## base + camada do mundo tocando juntas (sem camada = so a base).
func music(name: String, world: String = "") -> void:
	var key := "%s:%s" % [name, world] if name == "flight" else name
	if key == _music_name:
		return
	_music_name = key
	_crossfade(_music, _music_stream(name, world))


func _music_stream(name: String, world: String) -> AudioStream:
	if not MUSIC.has(name):
		return null
	var base := _load(MUSIC[name])
	var layer_path := LAYER_DIR % world
	if name != "flight" or world == "" or not ResourceLoader.exists(layer_path):
		return base
	var key := "sync:" + world
	if not _cache.has(key):
		var sync := AudioStreamSynchronized.new()
		sync.stream_count = 2
		sync.set_sync_stream(0, base)
		sync.set_sync_stream(1, _load(layer_path))
		_cache[key] = sync
	return _cache[key]


## Ambiencia do mundo (loop) com crossfade; "" silencia. Mundo sem arquivo de ambiencia = silencio.
func ambience(planet_id: String) -> void:
	if planet_id == _ambience_name:
		return
	_ambience_name = planet_id
	var path := AMBIENCE_DIR % planet_id
	_crossfade(_ambience, _load(path) if planet_id != "" and ResourceLoader.exists(path) else null)


## Jingle de progresso (um por vez); a musica abaixa DUCK_DB enquanto ele toca.
func jingle(name: String) -> void:
	if not STREAMS.has(name):
		push_warning("jingle desconhecido: %s" % name)
		return
	_jingle.stream = _stream(name)
	_jingle.play()
	played[name] = int(played.get(name, 0)) + 1
	_set_duck(DUCK_DB, 0.15)


func _unduck() -> void:
	_set_duck(0.0, 0.8)


## Abaixa/volta a musica por um Amplify no bus Music (nao briga com o volume das faixas nem com as opcoes).
func _set_duck(db: float, secs: float) -> void:
	if _duck_fx == null:
		return
	if _duck != null:
		_duck.kill()
	_duck = create_tween()
	_duck.tween_property(_duck_fx, "volume_db", db, secs)


## Troca de faixa: a nova entra em FADE_S enquanto a antiga sai; a antiga para no fim. Um tween por par (o anterior
## e cancelado: trocas rapidas nao deixam um "parar" atrasado desligar a faixa nova).
func _crossfade(pair: Array[AudioStreamPlayer], stream: AudioStream) -> void:
	var key := 0 if pair == _music else 1
	var prev: Tween = _fades.get(key)
	if prev != null:
		prev.kill()
	var old := pair[0]
	var new := pair[1]
	pair.reverse()                                             # a nova passa a ser pair[0]
	if not old.playing and stream == null:
		new.stop()
		return
	var tw := create_tween().set_parallel(true)
	_fades[key] = tw
	if stream != null:
		new.stream = stream
		new.volume_db = SILENT_DB
		new.play()
		tw.tween_property(new, "volume_db", 0.0, FADE_S)
	else:
		new.stop()
	if old.playing:
		tw.tween_property(old, "volume_db", SILENT_DB, FADE_S)
		tw.chain().tween_callback(old.stop)


func _stream(name: String) -> AudioStream:
	return _load(STREAMS[name])


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]


func ui(name: String, db: float = 0.0, pitch: float = 1.0) -> void:
	_play(name, &"UI", db, pitch)


func sfx(name: String, db: float = 0.0, pitch: float = 1.0) -> void:
	_play(name, &"SFX", db, pitch)


## Ultimo som tocado por canal (para testes/verificacao): nome -> vezes.
var played: Dictionary = {}


func _play(name: String, bus: StringName, db: float = 0.0, pitch: float = 1.0) -> void:
	if not STREAMS.has(name):
		push_warning("som desconhecido: %s" % name)
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _stream(name)
	p.bus = bus
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()
	played[name] = int(played.get(name, 0)) + 1
