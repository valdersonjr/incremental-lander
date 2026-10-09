# Sistema de mixagem (faixas por família, simultaneidade, limitador, web)

- **Slug**: mix-system
- **kind**: (sistema — vale para todos)
- **Evento/frequência**: todo som do jogo passa por `autoload/sound.gd` (one-shots, jingles, trilhas) ou pelos players
  do Lander/Flight (loops de motor e mecânica)
- **Assets**: nenhum próprio; regras conferidas por `tests/test_audio_assets.py`; limitador web em `web/audio_limiter.js`

## O que caracteriza (auditoria v2, 2026-10-09)
- **Faixas por família** (evita mascaramento; o propulsor toca quase o voo inteiro junto da música):
  - sub < 120 Hz: baixo da música e batidas raras;
  - corpo 150–800 Hz: pouso, propulsor (D3 + quinta A3), tosse do motor — o peso aparece por harmônicos (fundamental
    ausente), não por sub;
  - brilho 1–5 kHz: UI e recompensas; som frequente com ≤ 15% da energia > 5 kHz.
- **Medida de audibilidade no notebook**: loudness com e sem o que está abaixo de 200 Hz (passa-alta). Som frequente
  perde ≤ 5 dB; música/ambiência ≤ 4,5 dB. Antes da v2 o pouso perdia 10 dB e o corte do propulsor 11 dB.
- **Loudness por categoria** continua o do SKILL.md; a categoria tem que ser a certa (o tchibum estava como `impact`,
  3,5 dB acima dos SFX que ele substitui).

## Regras do sistema (Sound)
| Regra | Valor | Por quê |
|---|---|---|
| Vozes de one-shot | 10 | rajadas de minijogo + UI sem roubar |
| Limite por som/família | `RULES` (padrão 3 instâncias, 30 ms) | família numerada (crystal_1..3, combo, sheep, boing, pass) conta junto: 12 cristais davam 9 vozes e estouravam |
| Intervalo mínimo | move 35 ms, click 40 ms, pop 80 ms, denied 100 ms… | dois disparos no mesmo quadro = um som mais alto e embolado |
| Prioridade | UI curta 0 · padrão 1 · respostas importantes 2 | um clique nunca corta batida/entrega/recorde |
| Variações | sorteio sem repetir + pitch ×1,05^±1 + ±1 dB | igual aos AudioStreamRandomizer antigos, mas em WAV puro (web) |
| Ducking (jingle) | −9 dB em 0,15 s, volta em 0,8 s | por volume do player (web não tem efeito de bus) |
| Pausa | −6 dB em todo lugar + passa-baixa 700 Hz só no desktop | idem |
| Master | HardLimiter −1 dB (desktop) · WaveShaper soft-clip −0,3 dBFS (web) | a soma clipava: +0,3 dBTP gravado no desktop, +2,6 dBFS por canal na web |

## Erros / avisos resolvidos
- `AnalyserNode` mistura os canais para mono e infla o pico: medir saída web **por canal** (ChannelSplitter,
  `channelInterpretation = 'discrete'`).
- WaveShaper com `oversample = '2x'` passa do teto (o filtro de reamostragem "toca" depois do clip: +1,7 dB medido);
  como limitador de segurança usar `'none'`.
- `DynamicsCompressorNode` aplica ganho de compensação automático: não serve de limitador transparente.
- Aviso "energia muda X dB na emenda" em música = troca de compasso na janela de 20 ms (salto de amostra 0,0003);
  no gas_alarm é a divisão pelo silêncio entre bipes. Não são defeitos.

## Verificação
- `python3 tests/test_audio_assets.py` (≈ 7 s): loudness/pico/clip/duração/início/fim/agudo/notebook/referências/sem uso
  + limitador web igual no preset. Rodado contra os assets antigos acusa exatamente os 11 defeitos da auditoria.
- `tests/integration/sound_flow.gd`: camada alinhada, pausa e ducking por volume, simultaneidade, prioridade.
- Mixagem real: `godot --path . --write-movie <dir>/f.png --fixed-fps 30 --quit-after 1200 res://game/main.tscn -- --demo`
  grava `f.wav` com o som do jogo (Movie Maker) → medir pico/LUFS/espectro.
- Web: build local + Chrome headless (`--autoplay-policy=no-user-gesture-required`) em `index.html?audiotest` → o
  `Sound._web_report` imprime no console se cada som tocou como sample, camada alinhada, ducking, pausa e rajadas.
  (Aba do Chrome oculta congela o `requestAnimationFrame` e o jogo: usar headless.)

## Feedback do usuário
- Aprovou recriar só os sons com defeito medido (não os 79) e manter o modo Sample na web adaptando o sistema.

## Fontes
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html — modo Sample (padrão sem threads):
  "AudioEffects are not supported"; reverb/doppler idem; autoplay exige gesto do usuário.
- https://webaudio.github.io/web-audio-api/#WaveShaperNode — curva com entrada fora de [-1, 1] presa nas pontas;
  oversample aplica filtros de up/down-sampling.
- https://webaudio.github.io/web-audio-api/#DynamicsCompressorNode — ganho de compensação (makeup) automático.
