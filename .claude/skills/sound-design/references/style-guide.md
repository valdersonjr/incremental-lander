# Style guide sonoro do projeto (decisões globais)

> Fonte da verdade para TODO áudio. Itens **(provisório)** devem ser confirmados com o usuário
> no primeiro som do tipo e então atualizados aqui. Mudou algo aqui? Atualize também as constantes
> no topo de `scripts/soundkit.py` (KEY, SFX_SCALE, MODES, LOUDNESS_TARGETS).

## Estilo: retro-synth espacial
- **Por quê**: base de chip (pulso/triângulo/ruído) casa com a pixel art 16/32px; filtros, FM, eco e
  reverb dão o "espaço" que o chip puro não tem; timbres suaves evitam fadiga num jogo incremental
  (horas de cliques). Mais rico que NES puro, assim como a Resurrect 64 é mais rica que a paleta do NES.
- **Paleta sonora (travada)**: só timbres do soundkit — `pulse` (duty 12.5/25/50%), `triangle`,
  `saw`, `sine`, `noise` (white/pink/brown), `chip_noise`, `fm`, `unison`; processamento: filtros,
  `drive`, `bitcrush`/`decimate`, `delay`, `reverb`, `tremolo`, `vibrato`. **Sem samples externos.**
- SFX de gameplay e UI: **secos** (sem reverb assado). Música e ambiência: podem ter eco/reverb.

## Tonalidade
- Centro **D**. SFX tonais: **D pentatônica maior** (D E F# A B) via `snap()`.
- Música: D lídio (voo/exploração), D maior (menu/hangar/vitória), B menor (tensão). Confirmado 2026-10-03.

## Técnico
- WAV PCM 16-bit, 44.1 kHz. SFX/UI/jingle/loop: mono. Ambiência/música: estéreo.
- Alvos de loudness por categoria: ver tabela no SKILL.md (`LOUDNESS_TARGETS`). True peak ≤ −1 dBTP
  (ambiência ≤ −3).

## Hierarquia e fadiga
- Faixas por família (v2, 2026-10-09): sub = música/batidas raras; corpo 150–800 Hz = pouso/propulsor; brilho 1–5 kHz =
  UI/recompensa. Conferido por `tests/test_audio_assets.py` (pattern `mix-system`).
- Sons muito frequentes (clique, compra, tick): 40–150 ms, pouco conteúdo > 5 kHz, 3 variações + pitch
  aleatório ±5%.
- Sons raros e importantes (upgrade grande, marco, desbloqueio): podem ser longos, brilhantes, com eco.

## Identidade (a definir com o usuário)
- Timbre "assinatura" do jogo (ex.: sino FM para recompensas?) **(provisório)**
- Caráter do propulsor: **plasma suave** (zumbido grave afinado em D + sopro de plasma com filtro que respira + brilho
  elétrico leve) — combina com a nave futurista de plasma ciano. (2026-10-01: 3 opções geradas; o usuário delegou a escolha.)

## Identidade — melodia principal
- **Ocarina/flauta** (seno + sopro + vibrato atrasado) é o timbre do tema do jogo (escolha do usuário, 2026-10-09):
  cozy, fofo, "Zelda". Bom candidato para melodias de destaque futuras (vinhetas, mundo completo).

## Decisões registradas
<!-- data — decisão — motivo -->
- 2026-10-01 — propulsor = plasma suave (opção A de `audio/src/sfx/thruster.py`) — usuário: "escolhe qualquer 1"; o usuário prefere não auditar som por som: gerar o pacote seguindo a skill e tocar um resumo para aprovação geral
- 2026-10-03 — pacote de trilha: ambiência por mundo (cama + eventos esparsos, 24 s), música de título/hangar (D maior 84 BPM) e de voo (D lídio 100 BPM), alarme de gás que baixa após 3 s, jingles de marco/mundo/recomeço/final com a música abaixando −9 dB — aprovado pelo usuário ouvindo o resumo ("Aprovado, integra")
- 2026-10-09 — auditoria de som aplicada ("conserte tudo"): gramática da interface (mover quase mudo, confirmar
  sobe, voltar desce, negado plano, balão = pop), pausa abafa música/ambiência, cada coleta com som próprio,
  intensidade física no pouso e no turbo, batida **fofa** (puf + apito de desenho; a explosão antiga fica guardada),
  ambiência nos 6 mundos (Lua sem batalha), voo de 115 s + camada do mundo (mesmo tema, instrumento de cada mundo,
  −24 LUFS, `AudioStreamSynchronized`) — aguarda o usuário ouvir e aprovar
- 2026-10-09 — sistema de áudio v2 (auditoria técnica): faixas por família (sub < 120 Hz só para o baixo da música e batidas raras; pouso/propulsor/tosse no corpo 150–800 Hz com harmônicos; sons frequentes com ≤ 15% > 5 kHz), audibilidade no notebook medida (perda ≤ 5 dB sem o < 200 Hz; música/ambiência ≤ 4,5), limitador do Master (desktop e web), simultaneidade no Sound (pattern mix-system) — usuário aprovou o plano e, ouvindo o A/B, o resultado ("Aprovo")
