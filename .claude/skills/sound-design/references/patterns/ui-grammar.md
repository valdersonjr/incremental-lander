# Gramática da interface: mover, confirmar, voltar, negado, balão, contagem

- **Slug**: ui-grammar
- **kind**: ui (mono, −20 LUFS; o jogo ainda abaixa o cursor −7 dB e o tique −5 dB)
- **Evento/frequência**: `move` a cada seta/Tab que muda o foco (muito frequente); `click` confirma; `back` ao
  voltar/fechar/Esc; `denied` sem dinheiro; `pop` quando um balão/aviso aparece (Spotlight, "OUTRA MISSÃO!");
  `tally` em cada tique da contagem do resumo (o jogo sobe o pitch grau a grau na pentatônica).
- **Assets** ← `audio/src/ui/ui_sfx.py`: `assets/audio/ui/move_01.wav`, `assets/audio/ui/move_02.wav`,
  `assets/audio/ui/move_03.wav` (+ `assets/audio/ui/move.tres`), `assets/audio/ui/back.wav`,
  `assets/audio/ui/pop.wav`, `assets/audio/ui/tally.wav` (o click/buy/denied estão em game-sfx)

## O que caracteriza o som (pesquisa)
- Gramática que o jogador já conhece: **confirmar sobe, voltar desce, negado é plano e abafado, mover é quase
  silencioso**. Inverter isso deixa o menu "estranho" sem o jogador saber por quê.
- Derivar o conjunto de uma fonte só (mesmo timbre, mudando altura/duração/filtro): uma família de pitch é coerente.
- Todo som de navegação precisa ser agradável na centésima repetição: na dúvida, mais curto e mais baixo. O erro
  amador é dar som a tudo no volume cheio (hover "metralhando" quando o cursor cruza o menu).
- Diferenciar as ações grandes (compra, marco) das de navegação.
- Contagem de pontos: tiques curtos que **sobem de pitch** com o valor (mais brilhantes perto do fim) e um
  fechamento ao terminar (Balatro, Peggle, telas de resultado).
- Bolha/gota sintetizada: seno curto (10–30 ms) com o pitch subindo rápido = "pop" de balão.

## Receita final (camadas)
| Som | Fonte | Faixa | Duração | Envelope / movimento |
|---|---|---|---|---|
| move | triângulo, nota da escala 560–760 Hz, LP 2,2k | médio-grave | 35 ms | decay 9 ms; 3 variações + pitch ±5% |
| back | pulso A5 (50 ms) → triângulo E5 (70 ms), LP 2,4–2,8k | médio | 110 ms | duas notas descendo (o clique ao contrário) |
| pop | seno 500 → 1500 Hz (30 ms) + triângulo E6 −6 dB | médio | 110 ms | bolha + nota curta |
| tally | seno + triângulo D6, LP 4k | médio | 28 ms | decay 8 ms; o jogo sobe 0,2,4,7,9,12,14,16,19 semitons |

## Integração (Godot)
- `Sound._input` marca o quadro de cada ui_up/down/left/right/focus_next/prev; `Viewport.gui_focus_changed` até 1 quadro
  depois toca `move`. Assim `grab_focus()` de tela nova e o hover do mouse **não** soam (só o jogador navegando).
- `Sound.back()` no Esc/voltar (pausa, título, mapa, balão da NAVE, desistir de confirmação, fechar lista de saves).
- `Sound.tally(n)`; `Sound.preview(bus)`: ao mudar o volume, amostra no próprio canal (Efeitos = cristal; Música e
  Ambiente já estão tocando).
- Pausa: `Sound.muffle(true/false)` liga um passa-baixa (700 Hz, 0,25 s) nos buses Music e Ambience (Spelunky, FEZ).

## Feedback do usuário (o que mudou e por quê)
- 2026-10-09: auditoria de som ("conserte tudo") — antes só havia o clique para tudo e a navegação era muda.

## Erros / avisos resolvidos
- `in` num `Array[AudioEffectLowPassFilter]` com um efeito de outro tipo dá erro de tipo no Godot → `is` + `has()`.

## Fontes
- https://bugnet.io/blog/ui-sound-design-for-indie-games — confirmar sobe, voltar desce, negado plano; família de pitch; hover quase mudo
- https://www.audiokinetic.com/en/approaching-ui-audio-ui-design-perspective-2 — sons separados por estado do botão; ações grandes mais ricas
- https://wiki.gdevelop.io/gdevelop5/extensions/score-counter/ — contagem com pitch subindo (fator por tique)
- https://itooh.itch.io/sound-horizons/devlog/749469/devlog-11-menus-part-2 — menu com a música abafada por passa-baixa
