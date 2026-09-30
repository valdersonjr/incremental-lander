# Loja de prestígio (recomeço que traz novidade)

- **Slug**: prestige-shop
- **Onde na spec**: `prestige.shop`, `prestige.bonuses`, `planets.<id>.requires_shop`, `targets.prestige_count`
- **Intenção de design**: cada recomeço deve trazer algo novo (escolhas, conveniências, conteúdo), não
  "fazer tudo de novo igual". Poucos prestígios (4–6 até o fim), cada um marcante.

## Como jogos de referência fazem (pesquisa)
| Jogo | Mecânica | Números / detalhes |
|---|---|---|
| Cookie Clicker | nível de prestígio = cbrt(cookies da vida toda / 1e12); +1% CpS por nível (nunca diminui) | heavenly chips 1:1 com níveis, gastos na loja SEM reduzir o bônus passivo |
| Cookie Clicker (loja) | Legacy (1), Heavenly cookies +10% (3), caixas de cookies (25 cada), Starter kit (começa com 10 cursores), Permanent upgrade slot (carrega upgrade p/ o próximo ciclo), mecânicas novas (dragão, estações) | 1º ascend mirando ~365 chips para os itens-chave |
| Egg Inc | soul eggs (bônus passivo) + epic research permanente (reduz custos, aumenta bônus) | mantém pesquisa épica, permits, artefatos; reseta fazenda, veículos, pesquisa comum |
| Military Incremental Complex | loja com multiplicadores de renda primeiro, depois automação e desbloqueios | escolha de estilo (ativo × passivo) na loja |
| Idle Planet Miner | vender a galáxia → créditos gastos em upgrades permanentes | planetas re-comprados rápido |
| Padrão geral (reset milestones) | coisas liberadas só após N resets ou com moeda de prestígio | conteúdo novo por camada |

## Armadilhas conhecidas
- Prestígio só com multiplicador passivo ⇒ ciclos idênticos (medido na v3: 3 ciclos iguais até Ares).
- Muitos resets curtos (25–45 min) viram "clicar reset", não jogar.
- Itens de loja que tiram a habilidade do jogo (ex.: piloto automático perfeito) contrariam
  `skill-stays-relevant` — automação deve ser pior que o humano bom.

## Modelagem aqui (candidato v4e)
- Nível passivo: +1% pagamento e +0.1% motor por ponto de Poeira ganho na vida toda (gastar não reduz).
- Fórmula `pow 0.25`, `scale 800`, `min_gain 20` — com a regra "dobrar", o expoente define quantos
  prestígios cabem no jogo: sqrt (dobrar = 4× créditos) deu ~12; cbrt (8×) deu 8–9; **0.25 (16×) deu 4–6**.
- Loja (prioridade): Capital inicial (20K créditos/nível, 2·2^n, máx 3) → Ficha de piloto (+3 motor,
  +3 tanque, +2 eficiência por nível, 4·2^n, máx 3) → Cartas de navegação (manter planetas, 20) →
  Motor de dobra (portão de Titan, 60) → Contratos premium (×1.10 pagamento, 8·2^n, repetível).
- `planets.titan.requires_shop = warp_drive`; `targets.prestige_count = [4, 6]`.

## Efeito medido (simulação, MC 3 seeds, 2026-09-29)
| Métrica | v3 | Previsto | Medido v4e |
|---|---|---|---|
| Prestígios até o fim | ~12 (ciclos 1–3 idênticos) | 4–6 | casual 4, engaged 5, expert 5 ✓ |
| Término casual / engaged / expert | 18.4 / 15.2 / 11.1 h | ordem mantida | 25.4 / 15.0 / 11.8 h ✓ (casual/expert 2.1) |
| Loja | — | — | Cartas ~5–8 h, Motor de dobra ~4–12 h conforme o perfil |
| Platô final | — | — | **~8 h sem compras antes de Titan (engaged)**: falta conteúdo no fim do jogo |
Lições: (1) "Contratos premium" ×1.25/nível gerou avalanche (8–9 prestígios) → ×1.10; (2) o jogador
simulado precisava de 2 regras racionais (comprar o que se paga antes da meta; não resetar a < 2 h do
fim) — sem elas, paredes e tempos eram artefatos; (3) com o recomeço consertado, o que sobra é
**falta de conteúdo tardio**, que número nenhum resolve sem virar grind.

## Fontes
- https://cookieclicker.wiki.gg/wiki/Prestige — fórmula, +1%/nível, chips 1:1, itens e custos iniciais
- https://www.pocketgamer.com/cookie-clicker/heavenly-chips-guide — itens da loja celestial
- https://egg-inc.fandom.com/wiki/Prestige?oldid=9210 — o que o Egg Inc mantém/reseta
- https://commonsensegamer.com/military-incremental-complex-prestige-guide-what-to-unlock-and-when/ — ordem de compra na loja
- https://forum.quartertothree.com/t/discuss-idle-clickers/149577 — Idle Planet Miner: vender a galáxia → upgrades permanentes
