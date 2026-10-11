# Peças em degrau + empuxo sentido com teto (v20, 2026-10-11)

**Mecânica**: (1) upgrades de nível com efeito só ao completar o degrau (`effect.step`); (2) a física de voo usa um
empuxo "sentido" com teto suave, separado do empuxo cru que a economia compra.

**Referências**: Clash Royale / Brawl Stars (barra de cartas/pontos enche, o nível sobe de uma vez); Lunar Lander 1979
(alavanca de empuxo variável) e Lunar Lander Beyond (landers diferentes com física própria em vez de "a mesma nave,
mais forte"); queixas em incrementais de upgrades de velocidade que tornam o controle ingovernável (itch.io).

**Fórmulas**: nível efetivo = ⌊nível/step⌋×step. felt(a, g) = a se a − g ≤ knee; senão g + knee + (max − knee)·(1 −
e^(−(a − g − knee)/(max − knee))). knee 3,5 / max 8 m/s². Regras de decolagem (a > g × twr) usam o empuxo cru.

**Armadilhas**: o jogador simulado precisa olhar "até completar o degrau" (lookahead com k = step − nível%step), senão
compra parcela nenhuma; o teto aumenta a perda gravitacional nos mundos pesados (+10–20% de gás) — medir.

**Efeito medido** (6 h, 3 perfis × 2 seeds): degrau sozinho ≈ neutro; com o teto, mundos completos ~15% mais tarde,
paredes ≤ 10 min, 1ª compra igual. Decisão do usuário: "faz o que precisar pra deixar divertido"; degrau pedido por ele.
