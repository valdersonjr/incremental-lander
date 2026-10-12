# Obstáculos do céu da Lua (contra o arremesso por cima)

- **Slug**: sky-obstacles
- **Tipo**: sprites (16–46 px), 3 famílias em avaliação (2026-10-11)
- **Fonte**: `art/src/sprites/sky_obstacles.py` · prévias `art/previews/sky_obstacles/index.html`

## Características (pesquisa + revisão)
- Obstáculo precisa contrastar com o céu E com tudo que se pega: na Lua moedas, galões e estrelas são
  amarelo/dourado → obstáculo amarelo (queijo, estrela) se confunde com prêmio. Branco + turquesa (satélite) lê como "coisa".
- Estrela é o prêmio do jogo: nunca usar como perigo.
- Tamanho do sprite = área de batida (o que se vê é o que bate, igual world-hazards).
- Desenho em meia resolução + Scale2x + rosto em resolução final (função `post` antes do contorno) + contorno ink.
- Partes que precisam ficar separadas (orelha × cabeça) com 1 px de folga em meia resolução viram buraco grande;
  encostar e separar pelo tom (sombra da orelha × luz da cabeça).
- Estrela por fórmula (polígono de 10 pontos em meia resolução) virou "casinha"; desenhar à mão em ASCII.

## Fontes
- https://forum.makecode.com/t/engineers-toolbox/44798 — asteroide 16x16: contorno aleatório, 3 tons, bordas irregulares
- https://bugnet.io/blog/how-to-design-environmental-hazards-that-are-fair — perigo legível e evitável
- https://itch.io/post/6890305 — altitude como risco sem recompensa (equilíbrio risco/recompensa ao subir)

## Decisão (2026-10-11)
- Usuário escolheu a família B (satélites dos ratinhos): "ficaram bons". Export `--export` → assets/sprites/sky_obstacles.png
  (+ .json; células 48x28: sat_on/off, probe_on/off, bolt). Áreas de batida em world.json > sky_obstacles.kinds.circles.
- No jogo (captura a 725 m): o branco + turquesa lê bem contra o céu rosa e as colinas; denso no alto.
- Depois: satélites "meio feios" → rodada 2 (asteroides de pedra / emburrados / minas, só prévias) → usuário pediu
  **cachorrinhos** (família G, exportada): cachorrinho inteiro de capacete-bolha (rabinho 2 quadros), cabeça no
  capacete, ossinho. Capacete = só o anel (ice em cima-esquerda, sea embaixo) + 3 brilhos; miolo transparente (sem
  semi-transparência). Mancha marrom num olho (beagle) e orelhas caídas `copper/terracotta/rust` = lê "cachorro" a 32 px.
- Bater explode a nave na hora (usuário).
- Cachorrinhos de capacete: "ficou ruim". Usuário propôs **ossos de pedra** + cachorrinho que vem buscar (aprovado).
  Osso = cápsula + 4 bolotas sombreadas por primitivas (`shade_prims`: normal da primitiva mais "dentro", luz de
  esfera) → volume limpo. Áreas de batida geradas das mesmas primitivas (json "circles").
- Cachorrinho voando: desenhado como UMA peça virou "bolo" (cabeça sumia no corpo); **montar em peças com contorno
  próprio** (corpo, depois cabeça por cima) separou a cabeça. Osso na boca desenhado por cima de tudo, em tons de pedra
  (mist no branco do focinho sumia).
