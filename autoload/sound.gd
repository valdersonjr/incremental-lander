## Sons one-shot do jogo (arte sonora da skill sound-design: audio/src/** -> assets/audio/**).
## Sound.ui("click"|"buy"|"denied") no bus UI; Sound.sfx("landing"|"crash"|"delivered") no bus SFX.
## Variacoes + pitch/volume aleatorios vem dos AudioStreamRandomizer (.tres). O propulsor (loop) mora no Lander.
extends Node

const STREAMS := {
	"click": "res://assets/audio/ui/click.tres",
	"buy": "res://assets/audio/ui/buy.tres",
	"denied": "res://assets/audio/ui/denied.wav",
	"landing": "res://assets/audio/sfx/landing.tres",
	"crash": "res://assets/audio/sfx/crash.wav",
	"delivered": "res://assets/audio/sfx/delivered.wav",
}
const VOICES := 8

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS                    # cliques do menu de pausa tocam com o jogo pausado
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func _exit_tree() -> void:
	for p in _players:
		p.stop()
		p.stream = null
	_cache.clear()
	UiKit.clear_cache()


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
	if not _cache.has(name):
		_cache[name] = load(STREAMS[name])
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _cache[name]
	p.bus = bus
	p.play()
	played[name] = int(played.get(name, 0)) + 1
