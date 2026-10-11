# Biblioteca de padrões de economia

Um arquivo por mecânica/sistema (`<slug>.md`, modelo em `_TEMPLATE.md`). Antes de modelar qualquer
mecânica, procure aqui; se não houver ou estiver raso, pesquise (SKILL.md, Etapa 2) e registre.

| Slug | Mecânica | Jogos de referência | Usado em (spec) | Atualizado |
|---|---|---|---|---|
<!-- ex.: | planet-gate-gravity | Planeta novo como portão de física | Frontier Lander, Idle Planet Miner | planets.ares | 2026-09-30 | -->
| prestige-worth-it | Prestígio que vale a pena (bônus ≥ ×2, regra de dobrar) | AdVenture Capitalist, Realm Grinder, Cookie Clicker | prestige | 2026-09-29 |
| skill-stays-relevant | Habilidade continua importando (base + multiplicador de precisão, gás como limite) | GMTK roguelites, Idle Idol, jogos com multiplicador | contracts | 2026-09-29 |
| prestige-shop | Loja de prestígio: nível passivo + itens (capital, ficha, manter planetas, portão de conteúdo) | Cookie Clicker, Egg Inc, Military Incremental Complex, Idle Planet Miner | prestige.shop | 2026-09-29 |
| automation-fleet | Frota de drones que repete as rotas do jogador (+ lições sobre marcos de upgrade) | Idle Mine, Clicker Heroes, AdCap | upgrades.fleet/autopilot, milestones | 2026-09-29 |
| delivery-reward-variety | Variedade na recompensa das entregas (plataforma difícil, carga, prazo, combo, cristais) | Lunar Lander 1979, Jupiter Lander, Cargo Please!, SS14 | contracts.pad_tiers/combo/pickups | 2026-10-03 |
| staged-final-project | Megaprojeto final em etapas persistentes (Expedição a Titan) | Universal Paperclips, Space Station Designer, gradiente de meta | upgrades.exp1..exp8, planets.titan | 2026-09-29 |
| assist-tree | Árvore de ajudas de voo (informação, não potência; compra única persistente) | GMTK roguelites, landers com radar | upgrades[assist] | 2026-10-05 |
| mission-unlocks | Liberação gradual dos tipos de pedido (jogando, não comprando) + cliente visual por tipo | Slay the Spire, Hades II, Death Stranding, Good Pizza Great Pizza | (proposta) contracts.cargo/pad_tiers | 2026-10-06 |
| progression-road | Estrada das Estrelas: estrelas acumuladas liberam prêmios visíveis desde o início; Reputação +10% | Clash Royale, Fortnite, Hades, Kingdom Rush | progression.road, contracts.reputation | 2026-10-07 |
| run-fatigue-records | Run sem teto, meta = recorde pessoal; cansaço geométrico do gás para o run acabar | Hill Climb Racing, Learn to Fly, Tiny Wings | contracts.run_fatigue | 2026-10-07 |
| parallel-worlds | Mundos paralelos (mesma nave/moedas) com recorde próprio + bônus por bater a marca | Hill Climb Racing 2, Clash Royale, Cut the Rope | planets[].road, contracts.record_bonus | 2026-10-07 |
| minigame-graded-reward | Minijogo com recompensa graduada (crédito parcial, bônus por estrela, folga de empuxo) | Angry Birds, Subway Surfers, gradiente de meta | planets[].mission_bonus/partial_frac_model/takeoff_twr | 2026-10-08 |
| novice-profile | Perfil novato (batida alta que cai com a prática) + regra do aprendiz (bater no começo repete o salto) | Celeste, Super Meat Boy, Super Guide, Bandura | profiles novice; world.json onboarding.apprentice_stars | 2026-10-08 |
| progression-audit | Auditoria da progressão: missão longa dominante (17× por gás), curva das peças em degraus (+245% e depois ~0), gás infinito, progressão some após ~3 h, ordem da Estrada × necessidade; propostas | Lunar Lander Beyond, Jetpack Joyride, AdCap (Pecorella), ETS2, apps de transporte | v18 (diagnóstico; nada aplicado) | 2026-10-09 |
| stepped-upgrades-felt-thrust | Peças que só melhoram no degrau + empuxo sentido com teto (motor forte continua pilotável) | Clash Royale, Lunar Lander 1979/Beyond | upgrades[].effect.step, physics.feel | 2026-10-11 |
| distance-track | Pista só para a frente: distância = pontuação, relevo crescente encerra a viagem, galões, marcos de 1ª vez, estrelas = nota do pouso | Hill Climb Racing 1/2, Learn to Fly, Tiny Wings | contracts.track | 2026-10-11 |
