## Sons do jogo (arte sonora da skill sound-design: audio/src/** -> assets/audio/**).
## One-shots: Sound.ui("click"|"buy"|"denied") no bus UI; Sound.sfx("landing"|"crash"|"delivered"|"crystal_1..3"|
## "combo_2..5"|"star") no bus SFX (cristal: sobe um grau por cristal do mesmo salto; combo: sobe
## com o tamanho do combo). Variacoes + pitch/volume aleatorios vem dos AudioStreamRandomizer (.tres).
## Trilha: Sound.music("title"|"flight"|"") no bus Music e Sound.ambience(planeta|"") no bus Ambience, com crossfade
## (loops; tocar o que ja toca nao reinicia). Jingles: Sound.jingle("milestone"|"unlock"|"goal") no bus SFX,
## um por vez (o novo corta o anterior) e a musica abaixa enquanto toca. Liberar missao toca "unlock" pelo Events. O propulsor e o alarme de gas moram no Lander.
extends Node

const STREAMS := {
	"click": "res://assets/audio/ui/click.tres",
	"buy": "res://assets/audio/ui/buy.tres",
	"denied": "res://assets/audio/ui/denied.wav",
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
	"milestone": "res://assets/audio/sfx/milestone.wav",
	"unlock": "res://assets/audio/sfx/unlock.wav",
	"goal": "res://assets/audio/sfx/goal.wav",
}
const MUSIC := {"title": "res://assets/audio/music/title.wav", "flight": "res://assets/audio/music/flight.wav"}
const AMBIENCE_DIR := "res://assets/audio/ambience/%s.wav"
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
	Events.road_reached.connect(func(_n: String) -> void: jingle("unlock"))      # parada nova na Estrada das Estrelas


func _new_player(bus: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _exit_tree() -> void:
	for p: AudioStreamPlayer in _players + _music + _ambience + [_jingle]:
		p.stop()
		p.stream = null
	for t: Tween in [_duck] + _fades.values():
		if t != null:
			t.kill()
	var bus := AudioServer.get_bus_index(&"Music")
	for i in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
		if bus >= 0 and AudioServer.get_bus_effect(bus, i) == _duck_fx:
			AudioServer.remove_bus_effect(bus, i)
	_duck_fx = null
	_cache.clear()
	UiKit.clear_cache()


## Musica de fundo (loop) com crossfade; "" silencia. A mesma que ja toca continua de onde estava.
func music(name: String) -> void:
	if name == _music_name:
		return
	_music_name = name
	_crossfade(_music, MUSIC.get(name, ""))


## Ambiencia do mundo (loop) com crossfade; "" silencia. Mundo sem arquivo de ambiencia = silencio.
func ambience(planet_id: String) -> void:
	if planet_id == _ambience_name:
		return
	_ambience_name = planet_id
	var path := AMBIENCE_DIR % planet_id
	_crossfade(_ambience, path if planet_id != "" and ResourceLoader.exists(path) else "")


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
func _crossfade(pair: Array[AudioStreamPlayer], path: String) -> void:
	var key := 0 if pair == _music else 1
	var prev: Tween = _fades.get(key)
	if prev != null:
		prev.kill()
	var old := pair[0]
	var new := pair[1]
	pair.reverse()                                             # a nova passa a ser pair[0]
	if not old.playing and path == "":
		new.stop()
		return
	var tw := create_tween().set_parallel(true)
	_fades[key] = tw
	if path != "":
		new.stream = _load(path)
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


func ui(name: String) -> void:
	_play(name, &"UI")


func sfx(name: String) -> void:
	_play(name, &"SFX")


## Ultimo som tocado por canal (para testes/verificacao): nome -> vezes.
var played: Dictionary = {}


func _play(name: String, bus: StringName) -> void:
	if not STREAMS.has(name):
		push_warning("som desconhecido: %s" % name)
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _stream(name)
	p.bus = bus
	p.play()
	played[name] = int(played.get(name, 0)) + 1
