## Sons do jogo (arte sonora da skill sound-design: audio/src/** -> assets/audio/**).
## One-shots: Sound.ui(nome[, db, pitch]) no bus UI; Sound.sfx(nome[, db, pitch]) no bus SFX (cristal: sobe um grau
## por cristal do mesmo salto; combo: sobe com o tamanho do combo). Sons com variacoes (VARIANTS) sorteiam o arquivo e
## ganham pitch/volume aleatorios aqui (antes era AudioStreamRandomizer, que nao toca em modo Sample na web).
## Gramatica da interface (auditoria de som 2026-10-09): "move" quando o foco anda pelo teclado/controle (automatico,
## via Viewport.gui_focus_changed logo depois de uma seta/Tab), "click" confirma, Sound.back() volta/fecha, "denied"
## nega, "pop" balao/aviso aparecendo, Sound.tally(i) tique da contagem (sobe grau a grau na escala).
## Trilha: Sound.music("title"|"flight"|"", mundo) no bus Music e Sound.ambience(planeta|"") no bus Ambience, com
## crossfade (loops; tocar o que ja toca nao reinicia). O voo toca a base + a camada do mundo (layer_<mundo>.wav) em
## dois players disparados juntos (o mesmo tema, instrumento de cada mundo; a camada tem 1/3 da base e fecha junto).
## Sound.muffle(true) abafa musica e ambiencia (pausa). Jingles: Sound.jingle(nome) no bus SFX, um por vez (o novo
## corta o anterior) e a musica abaixa enquanto toca. Liberar missao toca "unlock" pelo Events. Propulsor, jatinhos de
## giro e alarme de gas moram no Lander; os loops dos mundos (gelo, vento, bolhas) no Flight.
## Mixagem (auditoria v2, 2026-10-09): a web roda em modo Sample (sem threads), onde efeitos de bus NAO funcionam
## (docs: "Exporting for the Web"). Por isso ducking e pausa sao volume dos players (compostos em _process); o
## passa-baixa da pausa e o limitador do Master sao so um extra no desktop. Vozes com prioridade + limite de
## instancias e intervalo minimo por som (RULES) evitam empilhar repeticoes e cortar sons importantes.
extends Node

const STREAMS := {
	"click": "res://assets/audio/ui/click_01.wav",
	"buy": "res://assets/audio/ui/buy_01.wav",
	"denied": "res://assets/audio/ui/denied.wav",
	"move": "res://assets/audio/ui/move_01.wav",
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
	"landing": "res://assets/audio/sfx/landing_01.wav",
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
## Sons com variacoes: sorteia o arquivo (sem repetir o anterior) + pitch/volume aleatorios (os mesmos dos .tres
## antigos: pitch ate x1,05, volume +-1 dB). WAV puro: toca em modo Sample na web.
const VARIANTS := {
	"click": ["res://assets/audio/ui/click_01.wav", "res://assets/audio/ui/click_02.wav",
			"res://assets/audio/ui/click_03.wav"],
	"buy": ["res://assets/audio/ui/buy_01.wav", "res://assets/audio/ui/buy_02.wav", "res://assets/audio/ui/buy_03.wav"],
	"move": ["res://assets/audio/ui/move_01.wav", "res://assets/audio/ui/move_02.wav",
			"res://assets/audio/ui/move_03.wav"],
	"landing": ["res://assets/audio/sfx/landing_01.wav", "res://assets/audio/sfx/landing_02.wav",
			"res://assets/audio/sfx/landing_03.wav"],
}
const RANDOM_PITCH := 1.05
const RANDOM_DB := 1.0
## Simultaneidade por som: [instancias ao mesmo tempo, intervalo minimo entre disparos (s)]. Passou do limite, a
## instancia mais antiga do mesmo som recomeca (nao rouba voz de outro som); dentro do intervalo, o disparo e ignorado
## (repeticao redundante: dois cliques no mesmo quadro soam como um, mais alto e embolado). Familias numeradas
## (crystal_1..3, combo_2..5, sheep_*, boing_*, pass_*) contam juntas no limite: e o mesmo som em alturas diferentes
## (12 cristais seguidos davam 9 vozes somadas e estouravam a saida web, que nao tem limitador de bus).
const RULES := {
	"move": [1, 0.035], "pop": [1, 0.08], "back": [1, 0.06], "denied": [1, 0.1], "click": [2, 0.04],
	"buy": [2, 0.05], "tally": [2, 0.0], "landing": [1, 0.15], "landing_heavy": [1, 0.15], "bump": [2, 0.06],
	"crash_soft": [1, 0.3], "splash": [1, 0.3], "delivered": [1, 0.2], "oops": [1, 0.2],
	"crystal": [3, 0.0], "combo": [1, 0.0], "sheep": [2, 0.0], "boing": [2, 0.0], "pass": [2, 0.0],
}
const DEFAULT_RULE := [3, 0.03]
## Prioridade no roubo de voz (todas ocupadas): um som so rouba a voz de outro de prioridade igual ou menor (o mais
## antigo). Interface curta = 0; padrao = 1; respostas importantes = 2 (nunca cortadas por um clique).
const PRIORITY := {
	"move": 0, "tally": 0, "pop": 0, "click": 0, "back": 0,
	"crash_soft": 2, "splash": 2, "landing_heavy": 2, "delivered": 2, "record": 2, "summary_end": 2, "oops": 2,
	"retry": 2, "aboard": 2,
}
## theme = tema do gatinho (so a tela inicial); title = Mapa e NAVE (calma); flight = voo (+ camada do mundo).
const MUSIC := {"theme": "res://assets/audio/music/theme.wav", "title": "res://assets/audio/music/title.wav",
		"flight": "res://assets/audio/music/flight.wav"}
const LAYER_DIR := "res://assets/audio/music/layer_%s.wav"
## Andamento de cada faixa (o mesmo dos scripts em audio/src/music/soundtrack.py): relogio musical das animacoes.
const BPM := {"theme": 68.0, "title": 84.0, "flight": 100.0}
const AMBIENCE_DIR := "res://assets/audio/ambience/%s.wav"
## Cursor: o mais baixo da interface (toca a cada seta; "quase silencioso", padrao de UI).
const MOVE_DB := -7.0
## Tique da contagem: graus da pentatonica (semitons acima de D6); passou do fim, fica no ultimo.
const TALLY_STEPS: Array[int] = [0, 2, 4, 7, 9, 12, 14, 16, 19]
const TALLY_DB := -5.0
## Pausa: musica e ambiencia abaixam MUFFLE_DB (funciona em todo lugar) e, no desktop, tambem ficam abafadas
## (passa-baixa em MUFFLE_HZ) — o jogo "fica de lado" sem silenciar.
const MUFFLE_DB := -6.0
const MUFFLE_HZ := 700.0
const OPEN_HZ := 20000.0
const NAV_ACTIONS: Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"]
const FADE_S := 1.2
const SILENT_DB := -40.0
## Quanto a musica abaixa enquanto um jingle toca (dB).
const DUCK_DB := -9.0
const VOICES := 10

## Ultimo som tocado por canal (para testes/verificacao): nome -> vezes que tocou de fato.
var played: Dictionary = {}
## Disparos ignorados pelas regras de simultaneidade (testes): nome -> vezes.
var skipped: Dictionary = {}
## Efeitos de bus funcionam? Falso na web em modo Sample (o padrao sem threads).
var effects_ok := true

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _voice_name: Array[String] = []                        # som que cada voz toca
var _voice_t: Array[int] = []                              # quando comecou (ms)
var _last_start: Dictionary = {}                           # nome -> ms do ultimo disparo
var _last_variant: Dictionary = {}                         # nome -> indice do ultimo arquivo sorteado
var _rng := RandomNumberGenerator.new()
var _music: Array[AudioStreamPlayer] = []                  # 2 para o crossfade; _music[0] = a que toca
var _layers: Array[AudioStreamPlayer] = []                 # camada do mundo de cada um (mesmo indice de _music)
var _ambience: Array[AudioStreamPlayer] = []
var _level: Dictionary = {}                                # player de trilha -> nivel do crossfade (dB)
var _music_name := ""
var _ambience_name := ""
var _jingle: AudioStreamPlayer
var _duck_db := 0.0
var _muffle_db := 0.0
var _duck: Tween
var _fades: Dictionary = {}                                # 0 musica / 1 ambiencia -> tween do crossfade
var _muffle_fx: Array[AudioEffectLowPassFilter] = []       # um por bus (Music, Ambience); so com effects_ok
var _muffle: Tween
var _nav_frame := -10                                      # quadro da ultima seta/Tab (foco que anda por ela soa "move")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS                    # cliques do menu de pausa tocam com o jogo pausado
	effects_ok = not uses_samples()
	for i in VOICES:
		_players.append(_new_player(&"SFX"))
		_voice_name.append("")
		_voice_t.append(0)
	for i in 2:
		_music.append(_new_player(&"Music"))
		_layers.append(_new_player(&"Music"))
		_ambience.append(_new_player(&"Ambience"))
	for p: AudioStreamPlayer in _music + _layers + _ambience:
		_level[p] = SILENT_DB
	_jingle = _new_player(&"SFX")
	_jingle.finished.connect(_unduck)
	if effects_ok:
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
	if OS.has_feature("web") and str(JavaScriptBridge.eval("location.search", true)).contains("audiotest"):
		_web_report.call_deferred()


## Web sem threads toca em modo Sample (Web Audio): baixa latencia, mas sem efeitos de bus.
static func uses_samples() -> bool:
	if not OS.has_feature("web"):
		return false
	return int(ProjectSettings.get_setting("audio/general/default_playback_type.web", 1)) == 1


## Volume final das trilhas = crossfade + ducking (so musica) + pausa. Composto aqui porque na web nao ha efeito de
## bus para abaixar a musica.
func _process(_delta: float) -> void:
	for p: AudioStreamPlayer in _music + _layers:
		p.volume_db = float(_level[p]) + _duck_db + _muffle_db
	for p: AudioStreamPlayer in _ambience:
		p.volume_db = float(_level[p]) + _muffle_db


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


## Batidas desde o comeco da faixa que toca (float), pela posicao real do audio (docs do Godot: "Sync the gameplay
## with audio and music": posicao + tempo desde a ultima mixagem - latencia de saida). Sem musica tocando, um relogio
## de parede no andamento do tema (as animacoes continuam no mesmo ritmo).
func music_beat() -> float:
	var bpm := float(BPM.get(_music_name.get_slice(":", 0), BPM["theme"]))
	var p := _music[0]
	if not p.playing:
		return Time.get_ticks_msec() / 1000.0 * bpm / 60.0
	var t := p.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return maxf(t, 0.0) * bpm / 60.0


## Voltar/fechar/cancelar (desce: o contrario do clique de confirmar).
func back() -> void:
	ui("back")


## Tique n da contagem (0, 1, 2...): cada um um grau acima na pentatonica.
func tally(n: int) -> void:
	ui("tally", TALLY_DB, pow(2.0, float(TALLY_STEPS[mini(n, TALLY_STEPS.size() - 1)]) / 12.0))


## Amostra do volume que o jogador acabou de mudar, tocada no proprio bus (Musica/Ambiencia ja estao tocando).
func preview(bus: String) -> void:
	match bus:
		"SFX", "Master":
			_play("crystal_2", &"SFX")
		"Music", "Ambience":
			pass                                               # a faixa que toca ja e a amostra
		_:
			ui("click")


## Pausa: musica e ambiencia abaixam (e, no desktop, fecham o passa-baixa) em 0,25 s; false volta ao normal.
func muffle(on: bool) -> void:
	if _muffle != null:
		_muffle.kill()
	for b: StringName in [&"Music", &"Ambience"]:
		var idx := AudioServer.get_bus_index(b)
		if idx >= 0 and on and not _muffle_fx.is_empty():
			AudioServer.set_bus_effect_enabled(idx, AudioServer.get_bus_effect_count(idx) - 1, true)
	_muffle = create_tween().set_parallel(true)
	_muffle.tween_property(self, "_muffle_db", MUFFLE_DB if on else 0.0, 0.25 if on else 0.4)
	for lp: AudioEffectLowPassFilter in _muffle_fx:
		_muffle.tween_property(lp, "cutoff_hz", MUFFLE_HZ if on else OPEN_HZ, 0.25 if on else 0.4) \
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if not on and not _muffle_fx.is_empty():
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
	for p: AudioStreamPlayer in _players + _music + _layers + _ambience + [_jingle]:
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
	var base: AudioStream = _load(MUSIC[name]) if MUSIC.has(name) else null
	var layer_path := LAYER_DIR % world
	var layer: AudioStream = null
	if base != null and name == "flight" and world != "" and ResourceLoader.exists(layer_path):
		layer = _load(layer_path)
	_crossfade(0, base, layer)


## Ambiencia do mundo (loop) com crossfade; "" silencia. Mundo sem arquivo de ambiencia = silencio.
func ambience(planet_id: String) -> void:
	if planet_id == _ambience_name:
		return
	_ambience_name = planet_id
	var path := AMBIENCE_DIR % planet_id
	_crossfade(1, _load(path) if planet_id != "" and ResourceLoader.exists(path) else null, null)


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


## Abaixa/volta a musica (volume dos players, composto em _process: nao briga com o crossfade nem com as opcoes).
func _set_duck(db: float, secs: float) -> void:
	if _duck != null:
		_duck.kill()
	_duck = create_tween()
	_duck.tween_property(self, "_duck_db", db, secs)


func _set_level(db: float, p: AudioStreamPlayer) -> void:
	_level[p] = db


## Troca de faixa: a nova entra em FADE_S enquanto a antiga sai; a antiga para no fim. Um tween por par (o anterior
## e cancelado: trocas rapidas nao deixam um "parar" atrasado desligar a faixa nova). which: 0 musica, 1 ambiencia.
## A camada (so musica) toca no player gemeo, disparada no mesmo quadro que a base (loops de tamanho multiplo: ficam
## alinhadas para sempre).
func _crossfade(which: int, stream: AudioStream, layer: AudioStream) -> void:
	var pair: Array[AudioStreamPlayer] = _music if which == 0 else _ambience
	var prev: Tween = _fades.get(which)
	if prev != null:
		prev.kill()
	var olds: Array[AudioStreamPlayer] = [pair[0]]
	var news: Array[AudioStreamPlayer] = [pair[1]]
	pair.reverse()                                             # a nova passa a ser pair[0]
	if which == 0:
		olds.append(_layers[0])
		news.append(_layers[1])
		_layers.reverse()
	var tw := create_tween().set_parallel(true)
	_fades[which] = tw
	for i in news.size():
		var p := news[i]
		var s := stream if i == 0 else layer
		p.stop()
		if s != null:
			p.stream = s
			_level[p] = SILENT_DB
			p.play()
			tw.tween_method(_set_level.bind(p), SILENT_DB, 0.0, FADE_S)
	var fading := false
	for p: AudioStreamPlayer in olds:
		if p.playing:
			fading = true
			tw.tween_method(_set_level.bind(p), float(_level[p]), SILENT_DB, FADE_S)
	if fading:
		tw.chain().tween_callback(func() -> void:
			for p: AudioStreamPlayer in olds:
				p.stop())
	elif stream == null:
		tw.kill()


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


func _play(name: String, bus: StringName, db: float = 0.0, pitch: float = 1.0) -> void:
	if not STREAMS.has(name):
		push_warning("som desconhecido: %s" % name)
		return
	var rule: Array = RULES.get(name, RULES.get(_family(name), DEFAULT_RULE))
	var now := Time.get_ticks_msec()
	if _last_start.has(name) and now - int(_last_start[name]) < int(float(rule[1]) * 1000.0):
		skipped[name] = int(skipped.get(name, 0)) + 1
		return
	var i := _voice_for(name, int(rule[0]))
	if i < 0:
		skipped[name] = int(skipped.get(name, 0)) + 1
		return
	var p := _players[i]
	p.stop()
	p.bus = bus
	if VARIANTS.has(name):
		var files: Array = VARIANTS[name]
		var k := _rng.randi_range(0, files.size() - 2)
		if k >= int(_last_variant.get(name, -1)):
			k += 1                                             # nunca o mesmo arquivo duas vezes seguidas
		_last_variant[name] = k
		p.stream = _load(files[k])
		pitch *= pow(RANDOM_PITCH, _rng.randf_range(-1.0, 1.0))
		db += _rng.randf_range(-RANDOM_DB, RANDOM_DB)
	else:
		p.stream = _stream(name)
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()
	_voice_name[i] = name
	_voice_t[i] = now
	_last_start[name] = now
	played[name] = int(played.get(name, 0)) + 1


## Voz para tocar `name`: no limite de instancias, recomeca a mais antiga do mesmo som; senao uma livre; senao rouba a
## mais antiga de prioridade igual ou menor. -1 = nenhuma (todas ocupadas por sons mais importantes).
func _voice_for(name: String, max_same: int) -> int:
	var same: Array[int] = []
	var fam := _family(name)
	for i in VOICES:
		if _players[i].playing and _family(_voice_name[i]) == fam:
			same.append(i)
	if same.size() >= max_same:
		return _oldest(same)
	for i in VOICES:
		if not _players[i].playing:
			return i
	var prio := int(PRIORITY.get(name, 1))
	var lower: Array[int] = []
	for i in VOICES:
		if int(PRIORITY.get(_voice_name[i], 1)) <= prio:
			lower.append(i)
	return _oldest(lower) if not lower.is_empty() else -1


## Familia do som: o nome sem o numero do fim ("crystal_3" -> "crystal"); sem numero, o proprio nome.
static func _family(name: String) -> String:
	var cut := name.rfind("_")
	return name.left(cut) if cut > 0 and name.substr(cut + 1).is_valid_int() else name


func _oldest(idx: Array[int]) -> int:
	var best := idx[0]
	for i: int in idx:
		if _voice_t[i] < _voice_t[best]:
			best = i
	return best


## Diagnostico (testes e build web): modo de reproducao e se cada som pode tocar como sample (musicas: so o tipo,
## para nao carregar faixas inteiras).
func diagnostics() -> Dictionary:
	var not_sampled: Array[String] = []
	var paths: Array = STREAMS.values()
	for v: Array in VARIANTS.values():
		paths += v
	for path: String in paths:
		var s := _load(path)
		if s == null or not s.can_be_sampled():
			not_sampled.append(path)
	for path: String in MUSIC.values():
		if not path.ends_with(".wav") or not ResourceLoader.exists(path):
			not_sampled.append(path)
	return {"web": OS.has_feature("web"), "samples": uses_samples(), "effects_ok": effects_ok,
			"not_sampled": not_sampled, "voices": VOICES}


## Build web com ?audiotest na URL: autoteste do sistema no runtime real (modo Sample) — imprime no console do
## navegador cada etapa: sons como sample, trilha do titulo, voo com camada alinhada, ducking, pausa e rajadas
## (limites de simultaneidade). So verificacao; o jogo normal nunca passa por aqui.
func _web_report() -> void:
	print("[Sound] diag ", diagnostics())
	ui("click")
	sfx("crystal_2")
	await _wait(0.05)
	var voices: Array[String] = []
	for i in VOICES:
		if _players[i].stream != null:
			voices.append("%s:sample=%s:tocando=%s" % [_voice_name[i],
					AudioServer.is_stream_registered_as_sample(_players[i].stream), _players[i].playing])
	print("[Sound] vozes ", voices)
	await _wait(3.0)
	_log_tracks("titulo")
	music("flight", "bolhas")
	ambience("bolhas")
	await _wait(3.0)
	_log_tracks("voo+camada")
	var b := _music[0]
	var l := _layers[0]
	if b.playing and l.playing:
		print("[Sound] camada_alinhada desvio_ms=%.1f" % (absf(fmod(b.get_playback_position(), l.stream.get_length())
				- l.get_playback_position()) * 1000.0))
	jingle("milestone")
	await _wait(0.5)
	print("[Sound] ducking duck=%.1f musica_vol=%.1f" % [_duck_db, _music[0].volume_db])
	await _wait(2.5)
	print("[Sound] fim_do_jingle duck=%.1f musica_vol=%.1f" % [_duck_db, _music[0].volume_db])
	muffle(true)
	await _wait(0.6)
	print("[Sound] pausa musica_vol=%.1f ambiencia_vol=%.1f" % [_music[0].volume_db, _ambience[0].volume_db])
	muffle(false)
	await _wait(0.8)
	print("[Sound] fim_da_pausa musica_vol=%.1f" % _music[0].volume_db)
	played.clear()
	skipped.clear()
	for k in 20:
		ui("click")
	for k in 12:
		sfx("crystal_%d" % (k % 3 + 1))
		await _wait(0.02)
	var busy := 0
	for p: AudioStreamPlayer in _players:
		busy += int(p.playing)
	print("[Sound] rajada tocados=%s ignorados=%s vozes_ocupadas=%d/%d" % [played, skipped, busy, VOICES])
	print("[Sound] WEBTEST FIM")


func _wait(secs: float) -> Signal:
	return get_tree().create_timer(secs, true, false, true).timeout


func _log_tracks(tag: String) -> void:
	var tracks: Array[String] = []
	for p: AudioStreamPlayer in _music + _layers + _ambience:
		if p.playing:
			tracks.append("%s:sample=%s:vol=%.1f:pos=%.2f" % [p.stream.resource_path.get_file(),
					AudioServer.is_stream_registered_as_sample(p.stream), p.volume_db, p.get_playback_position()])
	print("[Sound] %s %s" % [tag, tracks])
