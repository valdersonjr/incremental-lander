# Integração com Godot 4

## Formatos
- **WAV** (o que o soundkit gera): leve na CPU (centenas de vozes simultâneas), suporta loop com
  início E fim (e ping-pong/backward). Ideal para SFX e loops curtos.
- **Ogg Vorbis**: menor em disco, mais CPU; só "loop begin". Bom para música longa (requer ffmpeg
  para gerar — não instalado; alternativa: WAV + compressão **QOA** na importação).
- 16-bit / 44.1 kHz basta (24-bit e > 48 kHz não trazem ganho audível em jogo).
- Reverb/efeitos de espaço: preferir **no Godot** (bus com AudioEffectReverb) a assar no arquivo — exceto
  música/ambiência, onde o espaço faz parte da composição.
- Fonte: docs.godotengine.org → Importing audio samples.

## Import (aba Import do WAV)
- Loop: o soundkit grava o chunk `smpl` → Godot detecta o loop (Loop Mode: Detect From WAV).
  Para forçar: Loop Mode = Forward, Loop Begin/End em amostras.
- Force Mono: SFX já saem mono. Compress: QOA (bom custo/benefício) para arquivos grandes.

## Nós e recursos
- `AudioStreamPlayer` (UI/música, sem posição), `AudioStreamPlayer2D` (SFX no mundo — side-view:
  explosões e propulsores com pan pela posição).
- **AudioStreamRandomizer** (`.tres` gerado por `save_variations`): sorteia entre variações e aplica
  `random_pitch` / `random_volume_offset_db` — obrigatório para cliques/compras frequentes.
- **AudioStreamPlaylist**: sequência/aleatório de faixas (ambiente, rádio).
- **AudioStreamInteractive**: música por estados com transições (menu → voo → tensão).
- **AudioStreamSynchronized**: stems tocando juntos; ligar/desligar camadas por volume (`song.stems()`).

## Buses sugeridos
```
Master
├── Music      (-6 dB base, ducking leve quando jingle toca)
├── Ambience
├── SFX        (AudioEffectLimiter no fim)
│   └── Engine (LowPassFilter controlado pela potência do propulsor)
└── UI
```
- Volume final do jogo se ajusta nos buses; arquivos ficam nos alvos de loudness do style-guide.
- Opções do jogador: sliders por bus (Music/SFX/UI) — padrão em incremental games.

## Propulsor controlado por código (exemplo)
```gdscript
@onready var thrust: AudioStreamPlayer2D = $ThrustLoop
func _process(delta):
    var p := throttle  # 0..1
    thrust.volume_db = lerp(-30.0, 0.0, p)
    thrust.pitch_scale = lerp(0.85, 1.15, p)
    var fx := AudioServer.get_bus_effect(AudioServer.get_bus_index("Engine"), 0) as AudioEffectLowPassFilter
    fx.cutoff_hz = lerp(400.0, 4000.0, p)
```
