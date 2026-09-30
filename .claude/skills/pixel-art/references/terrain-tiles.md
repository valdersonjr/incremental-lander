# Terreno e tiles (side-view) — teoria + como fazer com pixelart.py

## 1. Teoria do tile seamless
- Um tile é seamless quando repetido lado a lado **não mostra costura nem padrão de grade**.
- Borda esquerda precisa continuar na direita, topo no fundo (pense na textura como um toro).
- **Esconder a grade**: clusters que atravessam as bordas e "dão a volta" (`clusters(..., wrap=True)`);
  peso visual distribuído por igual; **nada chamativo no centro** (um detalhe único vira padrão repetido).
- **Checagem**: `cv.wrap_shift(S//2, S//2)` traz as costuras para o centro — se aparecer uma cruz, corrija.
  Depois olhe `tiled_preview` (3x3). `lint(wrap=True)` checa órfãos considerando o wrap.
- **Variantes**: crie 2–4 variações do tile de preenchimento (mesmas bordas, miolo diferente) para
  quebrar repetição. No Godot, tiles com os mesmos peering bits são escolhidos aleatoriamente
  (ajuste a `probability` de cada um).
- Fonte: slynyrd.com/blog/2020/5/21/pixelblog-28-side-view-tiles

## 2. Construção de tile side-view (método Slynyrd)
1. **Blocagem de cor**: campos de cor dominantes; defina a orientação do tile.
2. **Clusters grosseiros**: misture clusters nos campos para sugerir a textura.
3. **Detalhes finos**: brilhos e sombras mais fortes, mantendo clusters "gordinhos" (nada de borrão).
- **Luz de cima** (diretamente) em tiles → permite espelhar tiles horizontalmente sem quebrar a luz.
- **Superfície com espessura**: a borda de cima mostra um pouco da face superior (perspectiva 3/4
  leve): 1–3px de faixa mais clara = "chão" que o jogador vê de leve de cima.
- Cantos externos: arredondar/chanfrar 1–2px; cantos internos: sombra no encontro.
- Vegetação/detritos podem ser tiles de sobreposição acima do chão (colisão continua reta).
- Camadas de fundo: várias camadas simples > uma detalhada; contraste menor.
- Tamanho: **16x16** é o padrão (acima de 32 fica trabalhoso demais).

## 3. Dithering e clusters em terreno
- Rocha/regolito: clusters horizontais irregulares (estratos) + poucos pixels de brilho no topo de
  cada cluster (luz de cima) e sombra embaixo.
- Transição superfície → subsolo: dither `noise` ou `bayer4` com 2 cores de luminosidade PRÓXIMA.
- Profundidade (quanto mais fundo, mais escuro): `gradient(...)` com rampa + dither nas transições,
  em tiles de "subsolo" separados (não no mesmo tile, senão quebra o seamless vertical).
- Crateras (lua): elipse achatada, borda de cima iluminada, interior em sombra, anel de brilho embaixo.

## 4. Auto-tiling — sistemas
| Sistema | Tiles | Detecta | Godot 4 | Quando usar |
|---|---|---|---|---|
| **9-slice / 3x3** | 9 (+4 cantos internos = 13) | lados + cantos simples | subset de *Match Corners and Sides* | plataformas retangulares simples |
| **Wang 2 cores de borda / 4-bit** | 16 | só lados (N,E,S,W) | *Match Sides* (`mode="sides16"`) | protótipo, terreno simples, sem cantos internos |
| **Blob 8-bit** | 47 | lados + diagonais | *Match Corners and Sides* (`mode="blob47"`) | **padrão recomendado** — cantos internos e externos suaves |
| **Wang de cantos / dual-grid** | 16 | 4 cantos | *Match Corners* (dual-grid exige script) | transições entre 2 terrenos com poucos tiles |

- **Regra dos cantos (blob)**: uma diagonal só importa se os dois lados vizinhos existirem → 256 → 47.
- Bits: N=1, NE=2, E=4, SE=8, S=16, SW=32, W=64, NW=128 (`canonical_mask`).
- Fontes: redblobgames.com/articles/autotile, docs.godotengine.org (Using TileSets), Godot terrain 47.

## 5. Método das 5 peças (como a biblioteca monta 47 tiles)
Você desenha 5 tiles; `TileTemplate.compose(mask)` monta qualquer tile combinando **quadrantes**:

| Peça | Vizinhos | Fornece |
|---|---|---|
| `fill` | todos | miolo (precisa ser seamless) |
| `island` | nenhum | cantos externos |
| `hstrip` | só E e W | borda de cima (superfície!) e de baixo |
| `vstrip` | só N e S | paredes esquerda e direita |
| `inner` | 4 lados, sem diagonais | cantos internos |

Regras para as 5 peças baterem:
- Construa todas a partir da MESMA base (função `base(seed)` → `fill`), só adicionando bordas.
- As bordas do `island` devem ser idênticas às do `hstrip` (topo/fundo) e do `vstrip` (lados).
- O quadrante de cada peça deve ser "neutro" nos cortes (x = S/2 e y = S/2): evite clusters que
  cruzem o meio do tile em elementos de borda, senão aparecem cortes ao combinar quadrantes.
- Tamanho par (16 → quadrantes de 8x8).
- Revise sempre `_testmap.png` (mini-mapa com ilhas, buracos, degraus e cantos internos).

```python
S = 16
def base(seed=1):
    c = Canvas(S, S, "slate")
    reg = {(x, y) for y in range(S) for x in range(S)}
    c.clusters(reg, "shadow", 10, (2, 5), seed=seed, wrap=True)
    c.clusters(reg, "lilac_grey", 6, (2, 3), seed=seed + 1, wrap=True)
    return c
def edges(top, bottom, left, right):
    c = base()
    if top:    c.hline(0, S-1, 0, "mist"); c.hline(0, S-1, 1, "steel")
    if bottom: c.hline(0, S-1, S-1, "ink")
    if left:   c.vline(0, 0, S-1, "ink")
    if right:  c.vline(S-1, 0, S-1, "ink")
    return c
fill = base(); inner = fill.copy()  # + sombras nos 4 cantos
t = TileTemplate(fill, edges(1,1,1,1), edges(1,1,0,0), edges(0,0,1,1), inner)
save_tileset(t, "assets/tiles/moonrock.png", mode="blob47",
             tres_path="assets/tiles/moonrock.tres", terrain_name="moonrock")
```

## 6. Godot 4 — setup
- Arraste o `.tres` gerado para o `TileSet` do `TileMapLayer`; pinte na aba *Terrains* com o terrain set 0.
- Project Settings → Rendering → Textures → **Default Texture Filter = Nearest** (senão borra).
- Rendering → 2D → **Snap 2D Transforms/Vertices to Pixel** = on; Window stretch mode `viewport`
  com escala inteira para pixels uniformes.
- Import do PNG: sem compressão com perdas (Lossless), mipmaps off.

## 7. Terreno de Lunar Lander — alternativa ao tilemap
Lunar Lander clássico usa terreno em **polígono irregular** (encostas em vários ângulos), não blocos.
Se o jogo for por esse caminho, os assets viram:
- **Textura de preenchimento seamless** (tile `fill`, 16 ou 32) para `Polygon2D` com `texture_repeat`.
- **Faixa de superfície** (tile horizontal seamless, ex.: 16x8) aplicada ao longo da borda via `Line2D`
  com textura em modo tile, ou sprites de borda por inclinação (0°, ~27° (1:2), 45° (1:1)).
- **Plataformas de pouso** como sprites/tiles separados (destaque de cor: são interativas).
**Decidido (2026-09-29): este jogo usa polígono irregular** (ver style-guide.md). Não perguntar de novo.
