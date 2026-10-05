# Árvore de ajudas (compras de informação, não de potência)

**Mecânica**: upgrades que não mudam stats; mostram informação no voo (seta para o alvo, cor de distância, rota
ideal, sombra/altura, inclinação, queda prevista, gás na chegada). Compra única, persistente no prestígio, em cadeia.

## Fontes
- GMTK, "Roguelikes, Persistency and Progression" — meta-progressão funciona melhor dando opções/acessibilidade
  do que poder bruto (Rogue Legacy pesou demais no poder). https://amara.org/videos/7doGHxwrhRpX/en/3100738
- Bugnet, "How to design a roguelite meta progression" — melhorias permanentes devem ampliar, não trivializar o
  desafio de habilidade. https://bugnet.io/blog/how-to-design-a-roguelite-meta-progression
- Fórum LÖVE (lander com módulos): radar de chão, alerta de proximidade, radar "look ahead".
  https://www.love2d.org/forums/viewtopic.php?p=244228

## Como modelar (Incremental Lander, v9)
- Spec: `upgrades[]` com `assist: "<galho>"`, `ability: true` + `ability_value` pequeno (0,01), `persistent: true`,
  `max_level: 1`, `requires_upgrade` = nó anterior. A raiz grátis não está na spec (GameState.ASSIST_FREE).
- O modelo não ganha skill com as ajudas (conservador): só o custo entra no ritmo. Preços ~ primeira hora
  (80 → 8K créditos; total ~16K): compradas de 5 a 43 min (engaged), atraso de ritmo dentro do ruído entre seeds.
- Calibrar depois com telemetria: se a qualidade média sobe com as ajudas, o skill real dos perfis sobe.

## Armadilhas
- `ability: true` faz a oficina tratar como habilidade (botão sob a nave): filtrar por `assist`.
- Não pagar mais por ter ajuda (pilar "pilotar bem sempre vale mais"); tudo desligável.
