# Áudio na web em modo Sample (Godot 4.7, export sem threads)

- **Tema**: Áudio / build web
- **Atualizado**: 2026-10-09

## Problema
O preset Web é single-threaded (`variant/thread_support=false`), então `audio/general/default_playback_type.web = 1`
(Sample): cada som vira um nó do Web Audio. Nesse modo **efeitos de bus não funcionam** (Amplify, LowPass, Limiter,
HardLimiter) e streams que não são "sampleáveis" (`AudioStreamRandomizer`, `AudioStreamSynchronized`) caem no modo
Stream, mixado no thread principal (latência e estalos). No desktop tudo funcionava, então nada acusava.

## Solução (autoload/sound.gd)
- Variações sorteadas no próprio `Sound` (`VARIANTS`: WAV puro) em vez de `AudioStreamRandomizer` (`.tres` apagados).
- Camada musical do mundo = **segundo player** disparado no mesmo quadro da base (loops de tamanho múltiplo ficam
  alinhados; medido 0,0 ms na web) em vez de `AudioStreamSynchronized`.
- Ducking e pausa = **volume dos players**, composto em `_process` (crossfade + duck + pausa). Efeito de bus só como extra
  quando `Sound.effects_ok` (desktop).
- Limitador do Master na web: `web/audio_limiter.js` no `html/head_include` do preset Web (intercepta
  `AudioNode.connect(destination)` e põe um WaveShaper soft-clip na frente). Fonte única no arquivo; o teste
  `tests/test_audio_assets.py` confere que o preset tem a cópia igual.
- `Sound.uses_samples()` lê `audio/general/default_playback_type.web` (padrão 1).

## Verificação
- `Sound.diagnostics()` lista sons que não podem tocar como sample (`can_be_sampled()`); o teste `sound_flow` exige vazio.
- Build local + Chrome headless em `index.html?audiotest` → `Sound._web_report` imprime as etapas no console
  (`AudioServer.is_stream_registered_as_sample`, posições, volumes). Aba do Chrome **oculta** congela o
  `requestAnimationFrame` e o jogo inteiro: use `--headless=new` (com `--autoplay-policy=no-user-gesture-required`).
- Para medir a saída de verdade, injete um tap por canal (ChannelSplitter + Analyser `discrete`) numa cópia do
  `index.html`; o Analyser estéreo mistura os canais e infla o pico.

## Armadilhas
- `tween_property` em variáveis do script funciona (`_duck_db`, `_muffle_db`); `tween_method(_set_level.bind(p), …)`
  para o nível de cada player.
- Tween paralelo sem nenhum tweener dá erro ao processar: matar (`kill()`) quando não há o que animar.
- O servidor `python3 -m http.server` deixa o navegador cachear o `.pck`: servir com `Cache-Control: no-store` ao testar.
