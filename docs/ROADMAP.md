# Roadmap de construção

> Marque `[x]` ao concluir, com data. Ao fim de cada **etapa** (fase ou bloco grande): atualizar
> `docs/HANDOFF.md`, fazer commit (ver CLAUDE.md). Cada fase lista a(s) **skill(s) obrigatória(s)**.
> Arte e som podem ser intercalados a partir da Fase 1 (placeholders geométricos até lá — sem imagens
> fora da skill `pixel-art`).

## Fase 0 — Fundação ✅ (2026-09-29/30)
- [x] 0.1 Skills: `pixel-art`, `sound-design`, `economy-balance` (com biblioteca de padrões)
- [x] 0.2 Economia v6 aplicada em `data/economy.json` (simulada e validada)
- [x] 0.3 Git local + `.gitignore`
- [x] 0.4 `project.godot` (640×360, escala inteira, Nearest, snap) + `default_bus_layout.tres`
- [x] 0.5 `scripts/economy/econ_math.gd` validado contra o Python (`python3 tests/test_econ_parity.py`)
- [x] 0.6 Skill `godot-dev` (2026-09-30): arquitetura, estilo, física do lander, terreno, UI, save/telemetria,
      testes; ferramenta `gdtool.py` (api/check/test/run/capture); executor de testes em `tests/`
- [x] 0.7 Documentação de continuidade (CLAUDE.md, GDD, ROADMAP, HANDOFF, DECISIONS, ARCHITECTURE)

## Fase 1 — Protótipo de voo (sem arte final) ✅ (2026-09-30) · skills: `godot-dev`, `economy-balance` (física ↔ modelo)
- [x] 1.1 Cena de voo: lander `CharacterBody2D` com integração própria (godot-dev `lander-physics.md`), gravidade, girar + propulsor; `data/world.json` + `WorldConfig`
- [x] 1.2 Consumo de gás por Δv (`efficiency`), tanque, HUD mínimo (gás, velocidade, altitude)
- [x] 1.3 Terreno em polígono irregular gerado (encostas + plataformas planas), colisão
- [x] 1.4 Detecção de pouso/batida + **qualidade q (0..1)** (velocidades, ângulo, centro da plataforma)
- [x] 1.5 Câmera lateral acompanhando o salto; escala do mundo `PX_PER_M` decidida e registrada em DECISIONS
- [x] 1.6 **Telemetria** de cada entrega → CSV (formato em `economy-balance/references/godot-integration.md`)
- [x] 1.7 Modo `--demo` (piloto automático) para verificação com `gdtool.py run/capture`
- Pronto quando: dá para decolar, voar até uma plataforma a X m, pousar/bater, o CSV registra o salto, e `check`/`test`/`run`/`capture` passam.

## Fase 2 — Loop do run · skills: `godot-dev`, `economy-balance`
- [ ] 2.1 Ofertas de entrega (distância × pagamento via `EconMath.contract_pay`), escolha pelo jogador
- [ ] 2.2 Encadear entregas no mesmo run, renovação de ofertas, teto de 6, fim por gás/batida
- [ ] 2.3 Resumo do run (entregas, qualidade média, créditos)
- [ ] 2.4 `GameState` (autoload): recursos, níveis, planetas; formatação `EconMath.fmt`

## Fase 3 — Hangar e upgrades · skills: `godot-dev`, `economy-balance`, `pixel-art` (UI)
- [ ] 3.1 Tela de hangar entre runs: lista de upgrades, custo, comprar, comprar máx.
- [ ] 3.2 Mapear `EconMath.ship_stats` → parâmetros físicos (thrust→aceleração, tank→gás, efficiency→Δv/gás, gear→tolerância)
- [ ] 3.3 Mostrar "alcance estimado" com o gás atual

## Fase 4 — Planetas · skills: `godot-dev`, `economy-balance`, `pixel-art`
- [ ] 4.1 Parâmetros por planeta (gravidade, arrasto/vento, distâncias) vindos da spec
- [ ] 4.2 Desbloqueio de Ares/Kronos, seleção de planeta, minério

## Fase 5 — Prestígio e loja da Poeira Estelar · skills: `godot-dev`, `economy-balance`
- [ ] 5.1 Tela de prestígio (ganho previsto, confirmação), reset via `EconMath.prestige_reset_state`
- [ ] 5.2 Loja da Poeira (capital, ficha, cartas, motor de dobra, premium)

## Fase 6 — Fase final · skills: `godot-dev`, `economy-balance`, `pixel-art`, `sound-design`
- [ ] 6.1 Frota de drones (renda = drones × autopilot × média da renda do jogador)
- [ ] 6.2 Expedição a Titan (8 etapas persistentes, barra segmentada) → Titan → final

## Fase 7 — Save/load e opções · skill: `godot-dev`
- [ ] 7.1 Save (versão da spec + migração), autosave · 7.2 Opções (volume por bus, controles)

## Fase 8 — Arte · skill: `pixel-art` (obrigatória para TODA imagem)
- [ ] Lander 32×32 + animações (propulsor, pouso, explosão) · texturas de terreno por planeta ·
      plataformas · fundos/parallax · UI (painéis, ícones de upgrade) · FX

## Fase 9 — Áudio · skill: `sound-design` (obrigatória para TODO som)
- [ ] Propulsor (loop controlado pela potência) · pouso/batida · UI (clique, compra com variações) ·
      jingles (upgrade, planeta, prestígio) · ambiências por planeta · músicas

## Fase 10 — Calibração, polimento e build · skills: `economy-balance` (Etapa 10), `godot-dev`
- [ ] 10.1 Jogar, exportar telemetria, `calibrate()` → `profiles_override` → re-simular
- [ ] 10.2 Game feel (tremor, partículas, feedback) · 10.3 Export desktop (Mac/PC)
