# Respostas de gameplay: pouso forte, giro, tosse, coletas próprias, falhas, chegada e resumo

- **Slug**: feedback-sfx
- **kind**: sfx / impact / jingle / loop (mono)
- **Evento/frequência**: cada um no seu evento (auditoria de som 2026-10-09: momentos que estavam mudos ou usavam o
  mesmo `crystal_3`).
- **Assets** ← `audio/src/sfx/feedback_sfx.py --export`: `assets/audio/sfx/landing_heavy.wav`,
  `assets/audio/sfx/rcs_loop.wav`, `assets/audio/sfx/sputter.wav`, `assets/audio/sfx/chest.wav`,
  `assets/audio/sfx/gas_glug.wav`, `assets/audio/sfx/gift_coin.wav`, `assets/audio/sfx/squeak.wav`,
  `assets/audio/sfx/target_hit.wav`, `assets/audio/sfx/oops.wav`, `assets/audio/sfx/splash.wav`,
  `assets/audio/sfx/retry.wav`, `assets/audio/sfx/aboard.wav`, `assets/audio/sfx/world_arrive.wav`,
  `assets/audio/sfx/summary_end.wav`, `assets/audio/sfx/record.wav`, `assets/audio/sfx/crash_soft.wav`

## O que caracteriza o som (pesquisa)
- **Cada evento com leitura própria**: um som reaproveitado para 5 coisas (baú, galão, presente, ratinho, curling)
  apaga a informação; coletas diferentes = timbres diferentes da mesma família (sinos/pulso na escala).
- **Intensidade física**: pouso/impacto escalam volume e peso com a velocidade (padrão de jogos com física); acima
  de um limiar entra uma camada de pancada (metal, chocalho), não só "mais alto".
- **Motor**: estados contam história — ignição, loop, corte e **tosse** quando o combustível acaba (pitch caindo =
  perda). Turbo = mais agudo e mais brilhante (pitch + filtro abrindo, ver godot-audio.md). Jatos de giro (RCS) =
  sopro curto e baixo, porque toca muito.
- **Público infantil + arte fofa**: perda sem susto — "puf" + apito de desenho caindo em vez de explosão com estalo
  agudo e muito sub; falha de regra = "uá-uá" grave-médio, nunca buzina.
- **Bolha** sintetizada: seno 30–90 ms com pitch subindo ×2–2,4 e decaimento rápido (glub, tchibum, bolhas).
- Chegada num mundo: vinheta curta (≤ 2,5 s) que soa como "cortina abrindo" (glissando na escala + acorde de sino),
  como a chegada num reino em Mario Odyssey.

## Receita final (camadas)
| Som | Camadas | kind |
|---|---|---|
| landing_heavy | seno 75→32 Hz + triângulo 150→64 Hz (harmônico p/ notebook) −2 + FM ratio 1,41 em snap(380) −6 + chocalho BP 0,9–3k −16 | sfx |
| rcs_loop | rosa BP 1,6–2,6k respirando (2 ciclos/1 s) + branco HP 3k −26 + tremolo 30 Hz; loop 1 s | loop |
| sputter | 3× (marrom LP 700 + pulso 140→90 Hz caindo), cada um −3 dB e mais espaçado + suspiro rosa 1500→300 Hz | sfx |
| chest | FM ratio 2,76 snap(620) −6 + madeira (marrom LP 900 + triângulo A3) −3 + sino FM A5 | sfx |
| gas_glug | 3 bolhas 220/280/360 Hz (×2,4) + triângulo D6 −8 | sfx |
| gift_coin | pulso 50% B5 → E6 + brilho FM −14 | sfx |
| squeak | 2 chirps seno (1500→F#6, 1700→A6) com vibrato 28 Hz + triângulo A5 −6 | sfx |
| target_hit | 2 sinos FM F#5 → A5 | sfx |
| oops | triângulo B4 → A4 → F#4, cada nota escorrega −5%; LP 2,5k | sfx |
| splash | branco com LP 5k→400 + seno 120→45 −4 + 9 bolhas espalhadas (−8…−16) | impact |
| retry | triângulo A5, F#5, A5→B5 (pergunta) | sfx |
| aboard | pulso 25% D5 → A5 + seno A6 −12 | sfx |
| world_arrive | glissando triângulo pentatônica D4→D6 em 0,4 s (−2) + acorde de sinos D5-F#5-A5-D6 + eco 0,21 s | jingle |
| summary_end | pulso A5 → D6 + sino D6 | jingle |
| record | arpejo D5-F#5-A5-D6-F#6 + trinado A6/B6 + sino D6 + eco | jingle |
| crash_soft | rosa com LP 2,5k→150 (puf) + seno 100→38 −2 + apito seno 1400→300 com vibrato −9 + 3 tlins F#5-D5-A4 | sfx |

## Integração (Godot)
- Pouso: `Flight._landing_sound(k)`, k = vy/max_vy: `landing` com −9…0 dB e pitch 1,06…0,94; k > 0,6 soma
  `landing_heavy`. Aprendiz parando fora da plataforma = k 0,2.
- Batida: `crash_soft` (a explosão antiga `crash.wav` fica como alternativa); no mar (`reason == "mar"`) = `splash`.
- Lander: `rcs_loop` (−15 dB) enquanto gira em voo; tosse no `ThrustFx` quando o gás zera com o motor ligado (sem o
  corte normal); turbo = pitch 1,122 (+2 semitons), +2,5 dB e o passa-baixa do bus Engine 4k → 8k, deslizando.
- Resumo: contagem 0 → total em 0,9 s com `Sound.tally`, depois `summary_end` (ou `record` se bateu o recorde).
- HUD: `retry` em "TENTE DE NOVO!", `aboard` em "A BORDO!", `pop` em "OUTRA MISSÃO!"; `world_arrive` com o nome do mundo.

## Feedback do usuário (o que mudou e por quê)
- 2026-10-09: "conserte tudo" após a auditoria. A batida fofa é a recomendação para o público de 6 anos; voltar
  para a explosão antiga é trocar `crash_soft` por `crash` no `Flight`.

## Erros / avisos resolvidos
- Subida da vinheta de chegada escondida sob o acorde → glissando −8 → −2 dB.
- Pouso forte com 95% abaixo de 250 Hz sumiria no notebook → harmônico em triângulo uma oitava acima.
- `Sound.sfx` no `lander.gd` quebrou os testes unitários (autoload não existe no `--script`) → a tosse usa o player do
  próprio lander.

## Fontes
- https://arxiv.org/pdf/2011.05538 — bolha/gota: seno curto com pitch modulado (10–20 ms), base das bolhas
- https://www.audiokinetic.com/en/generating-rain-with-pure-synthesis — gotas e água por síntese pura
- https://bugnet.io/blog/ui-sound-design-for-indie-games — diferenciar ações grandes; perda/erro suaves mas distintos
