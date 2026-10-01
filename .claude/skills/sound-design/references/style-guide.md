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
- Música: D lídio (exploração), D maior (menu/vitória), B menor (tensão). **(provisório)**

## Técnico
- WAV PCM 16-bit, 44.1 kHz. SFX/UI/jingle/loop: mono. Ambiência/música: estéreo.
- Alvos de loudness por categoria: ver tabela no SKILL.md (`LOUDNESS_TARGETS`). True peak ≤ −1 dBTP
  (ambiência ≤ −3).

## Hierarquia e fadiga
- Sons muito frequentes (clique, compra, tick): 40–150 ms, pouco conteúdo > 5 kHz, 3 variações + pitch
  aleatório ±5%.
- Sons raros e importantes (upgrade grande, marco, desbloqueio): podem ser longos, brilhantes, com eco.

## Identidade (a definir com o usuário)
- Timbre "assinatura" do jogo (ex.: sino FM para recompensas?) **(provisório)**
- Caráter do propulsor: **plasma suave** (zumbido grave afinado em D + sopro de plasma com filtro que respira + brilho
  elétrico leve) — combina com a nave futurista de plasma ciano. (2026-10-01: 3 opções geradas; o usuário delegou a escolha.)

## Decisões registradas
<!-- data — decisão — motivo -->
- 2026-10-01 — propulsor = plasma suave (opção A de `audio/src/sfx/thruster.py`) — usuário: "escolhe qualquer 1"; o usuário prefere não auditar som por som: gerar o pacote seguindo a skill e tocar um resumo para aprovação geral
