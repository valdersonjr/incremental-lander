# Incremental Lander — Documento de Design (GDD)

> Documento vivo. **Números** de economia NÃO moram aqui: a fonte única é `data/economy.json`
> (tabelas abaixo são um retrato da spec **v6**, 2026-09-29). Mudou a spec → atualize o retrato.

## 1. Conceito
Jogo **incremental** estilo **Lunar Lander**, **visão lateral**, feito em **Godot 4.7** para **computador**
(teclado). Cada **run** tem **gás limitado**; o jogador pilota um lander fazendo **entregas** entre
plataformas de pouso para ganhar dinheiro e melhorar a nave (motor/velocidade, tanque, eficiência…),
indo cada vez mais longe até liberar **novos planetas** com física mais dura (ex.: Ares, gravidade forte,
gasta mais gás). Meta-progressão com **prestígio** (loja da Poeira Estelar), **múltiplos recursos**
(créditos, minério), **automação** no fim (frota de drones) e um **megaprojeto final** (Expedição a Titan).

Pilares:
1. **Pilotar bem sempre vale mais** — precisão paga até ×2,2; piloto ruim gasta mais gás. Upgrades ampliam, não substituem.
2. **Sem esperas** — sempre há algo para comprar em minutos; paredes só antes de planeta/prestígio e curtas.
3. **Cada recomeço traz algo novo** — loja de prestígio, planetas mantidos, conteúdo liberado.
4. **Duração total é flexível** (hoje ~5 h até Titan); qualidade do ritmo > horas.

## 2. Loop principal
```
[Hangar/loja] → decolar → escolher entrega (distância × pagamento) → voar (salto balístico) →
pousar na plataforma (qualidade 0..1) → receber → próxima entrega … até o gás acabar (ou bater)
→ resumo do run → [Hangar/loja] comprar upgrades → …
```
- Run termina quando o gás não alcança nenhuma entrega, após **6 entregas** (teto) ou em batida
  (o que já foi ganho fica).
- Entregas **se renovam**: a cada entrega feita, uma nova oferta aparece (o gás é sempre o limite).
- Pagamento cresce com a distância (`d^1.1`), custo em gás cresce com `sqrt(g·d)` → ir mais longe
  compensa, mas exige gás num salto só.

## 3. Pilotagem (física) — **a implementar e calibrar**
- Controles (teclado): girar esquerda/direita, propulsor. (Detalhes finais na skill `godot-dev`/Fase 1.)
- Gravidade do planeta, arrasto/vento, gás consumido por Δv (`efficiency` = m/s por unidade de gás).
- Pouso: velocidade vertical/horizontal, ângulo e distância ao centro da plataforma → **qualidade q (0..1)**.
- O modelo econômico assume salto balístico: `Δv ≈ 2·sqrt(g·d)·(1 + 0.707·g/a)·(1+drag)·desperdício + 2·g·pairar`
  (ver `.claude/skills/economy-balance/references/run-model.md`). O jogo real deve **exportar telemetria**
  para calibrar esse modelo (Fase 10).

## 4. Terreno
**Polígono irregular** (padrão das skills: `pixel-art/references/terrain-tiles.md` §7 + modelo de run da
`economy-balance`): encostas em vários ângulos, **plataformas de pouso planas** como alvos, textura pixel
art contínua (`Polygon2D` com textura seamless) + faixa de superfície na borda.

## 5. Planetas (spec v6)
| Planeta | Gravidade | Arrasto | Distâncias | Pagamento | Recurso extra | Desbloqueio |
|---|---|---|---|---|---|---|
| Lua | 1,62 | 0 | 100–15.000 m | ×1 | — | inicial |
| Ares (gravidade forte) | 5,0 | 0,1 | 150–25.000 m | ×12 | minério | 300K créditos |
| Kronos (atmosfera densa) | 9,0 | 0,3 | 200–40.000 m | ×150 | minério | 1,5B créd. + 2K minério (após Ares) |
| Titan (gigante) | 15,0 | 0,2 | 300–60.000 m | ×2.500 | minério | concluir a Expedição a Titan (8/8) |
Motor mínimo: o lander só decola se a aceleração do motor > ~1,05 × gravidade (Ares exige upgrades de motor).

## 6. Upgrades (créditos; resetam no prestígio, exceto a Expedição)
| Upgrade | Efeito | Observação |
|---|---|---|
| Motor (velocidade) | +0,6 m/s² por nível | vence gravidades maiores, menos perda por gravidade |
| Tanque de gás | ×1,12 gás por nível | alcance |
| Bocais (eficiência) | ×1,07 Δv por gás | alcance |
| Reputação | ×1,1 pagamento | — |
| Trem de pouso | reduz batidas (retorno decrescente) | — |
| Refinaria | ×1,15 eficiência | custa créditos + minério |
| **Marcos** | a cada 25 níveis de Motor/Tanque/Bocais/Reputação: pagamento ×1,5 | estilo AdVenture Capitalist |

## 7. Prestígio — Poeira Estelar
- Recomeçar (após chegar a Ares) converte créditos ganhos em **Poeira Estelar**: `(créditos/800)^0,25`.
- **Nível de prestígio** (poeira ganha na vida toda, nunca diminui): +1% pagamento e +0,1% motor por ponto.
- **Loja da Poeira** (gastar não reduz o nível):
  | Item | Efeito |
  |---|---|
  | Capital inicial | recomeça com +20K créditos por nível (máx 3) |
  | Ficha de piloto | recomeça com +3 motor, +3 tanque, +2 bocais por nível (máx 3) |
  | Cartas de navegação | **planetas desbloqueados permanecem** após o prestígio |
  | Motor de dobra | libera a fase final (frota + Expedição) |
  | Contratos premium | ×1,1 pagamento por nível (repetível) |
- Esperado: ~4 prestígios até o fim, cada um marcante.

## 8. Fase final (após o Motor de dobra)
- **Frota de drones** (mudança de fase): até 10 drones; cada drone rende uma fração da **sua** renda
  média (8% → ~17% com o Software de piloto automático). Pilotar bem treina uma frota melhor.
  Teto: frota ≈ 45–55% da renda.
- **Expedição a Titan** — 8 etapas **persistentes** (não resetam), cada uma com bônus, custo em créditos + minério:
  1. Estação Orbital de Apoio (pagamento ×1,2) · 2. Tanques Criogênicos (tanque ×1,25) ·
  3. Escudo Térmico Ablativo (pagamento ×1,2) · 4. Rede de Satélites de Navegação (eficiência ×1,15) ·
  5. Módulo de Habitação (pagamento ×1,2) · 6. Reator de Fusão Compacto (motor ×1,15) ·
  7. Âncora Gravitacional (piloto automático ×1,3) · 8. **Nave-mãe Aurora** (pagamento ×1,25) → **Titan**.
- Objetivo final: chegar a Titan. (Pós-jogo: a definir.)

## 9. Ritmo esperado (simulado, spec v6)
Expert ~4,3 h · engajado ~4,9 h · casual ~5,6 h até Titan; Ares ~0,7 h; Kronos ~2,7 h; pior espera entre
compras ≤ 30 min. Relatório: `balance/reports/2026-09-29-v6-expedition/`.

## 10. Direção de arte e som
- **Arte**: pixel art, paleta **Resurrect 64** travada, lander 32×32, tiles/texturas 16×16, resolução
  interna **640×360** (escala inteira). Tudo via skill `pixel-art` (`references/style-guide.md`).
- **Som**: retro-synth espacial 100% sintetizado, escala em D, loudness por categoria, via skill
  `sound-design` (`references/style-guide.md`).

## 11. Técnico
Godot 4.7.2 · desktop (Mac/PC) · teclado · 640×360 viewport, escala inteira (janela 1280×720) ·
filtro Nearest · snap de pixel · buses de áudio Master/Music/Ambience/SFX→Engine/UI ·
economia em `data/economy.json` + `scripts/economy/econ_math.gd` (paridade testada com o Python).

## 12. Em aberto
- Controles exatos e sensação de voo (Fase 1). · Geração dos mapas (procedural? quantos por planeta?).
- Pós-jogo após Titan. · Tela de título/menus. · Nome final do jogo.
