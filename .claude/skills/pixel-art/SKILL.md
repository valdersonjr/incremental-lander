---
name: pixel-art
description: OBRIGATÓRIA para criar, editar ou animar QUALQUER imagem do jogo — sprite, nave/lander, personagem, inimigo, tile, terreno, tileset, item, ícone, UI, efeito (fogo, explosão, fumaça), fundo, parallax ou animação. Pinta pixel art numa grade 16x16/32x32/64x64 via Python (como no Aseprite), travada na paleta Resurrect 64, pesquisando ANTES os padrões do objeto e as técnicas (tile seamless, dithering, clusters, auto-tiling 9-slice/Wang/blob 47) e exportando PNG + recursos Godot 4. Use sempre que o usuário pedir para desenhar, gerar, criar, ajustar, redesenhar ou animar arte, imagem, sprite ou pixel art — mesmo que ele não cite a skill.
---

# Pixel Art — Resurrect 64 → Godot 4

Esta skill transforma pedidos de arte em **scripts Python que pintam pixel por pixel** com
`scripts/pixelart.py`. O script gerador é a "fonte" do asset (como um `.aseprite`); o PNG é o export.

Jogo: **incremental estilo Lunar Lander, visão lateral (side-view), engine Godot 4.**

## Regras invioláveis

1. **Toda imagem do projeto passa por esta skill.** Nada de gerar PNG por outro meio.
2. **Paleta travada: só Resurrect 64** (64 cores) + transparência total. Semi-transparência é proibida.
   A biblioteca lança `PaletteError` para qualquer outra cor e `check_png` valida no save.
3. **Aprender antes de desenhar.** Nenhum pixel é pintado antes da Etapa 2 (pesquisa/biblioteca) estar concluída.
4. **Revisar vendo.** Toda iteração gera prévia ampliada que você DEVE abrir com Read e criticar.
5. **Aprovação do usuário** antes de considerar o asset final.
6. **A biblioteca cresce.** Todo asset termina atualizando `references/patterns/`.

## Pastas do projeto

```
art/                      # tem .gdignore (Godot ignora)
  src/<categoria>/<nome>.py   # script gerador = fonte do asset
  previews/                   # prévias ampliadas, tiled, GIFs, mapas de teste
assets/                   # o que o Godot importa
  sprites/  tiles/  fx/  ui/  bg/
```
Rodar sempre a partir da raiz do projeto: `python3 art/src/<cat>/<nome>.py`.
Cabeçalho de todo script gerador:
```python
import sys; sys.path.insert(0, ".claude/skills/pixel-art/scripts")
from pixelart import *
```

## Guia de tamanhos (escolha e justifique)

| Grade | Use para | Por quê |
|---|---|---|
| **16x16** `Canvas.grid16()` | tiles de terreno, itens, ícones de UI/upgrade, pickups, partículas, projéteis | legível e rápido; tiles de 16 são o padrão da indústria para side-view; força formas icônicas |
| **32x32** `Canvas.grid32()` | **lander/naves**, personagens, inimigos, props, explosões, prédios pequenos | espaço para silhueta + detalhe (cockpit, pernas, propulsor); ponto ideal para sprites principais |
| **64x64** `Canvas.grid64()` | chefes, retratos, estações, planetas, props grandes, pedaços de fundo | detalhe alto; custa muito mais — só quando o objeto é grande na tela |

Regra: **a escala de pixel deve ser igual em todos os assets** (1 pixel de arte = mesmo tamanho na tela).
Um objeto que é 2 tiles de altura no jogo tem 32px. Tamanhos não quadrados são permitidos (`Canvas(48, 24)`)
quando a forma pede, mas justifique. `Canvas.for_kind("lander")` aplica o guia (`pixelart.py sizes`).

## Fluxo obrigatório

### Etapa 0 — Contexto
Leia `references/style-guide.md` (decisões do projeto: luz, contorno, limites de cor) e
`references/palette.md` (rampas). Se precisar ver a paleta: Read em `references/palette-ramps.png`.

### Etapa 1 — Briefing
Defina e confirme com o usuário o que não estiver claro (pergunte com AskUserQuestion se houver dúvida real):
- O que é, função no jogo, onde aparece (em cima de quê — fundo espacial escuro? terreno?).
- Tipo: sprite | tile/tileset | efeito | UI | fundo. Estático ou animado (quais animações)?
- Tamanho da grade (tabela acima) e escala relativa a assets existentes em `assets/`.
- Para tileset: modo de auto-tiling (ver `references/terrain-tiles.md`).

### Etapa 2 — Aprender o padrão (OBRIGATÓRIA)
1. Leia **sempre** `references/fundamentals.md`.
2. Leia a referência de técnica do tipo: terreno/tiles → `references/terrain-tiles.md`;
   animação/efeitos → `references/animation.md`.
3. Abra `references/patterns/INDEX.md` e procure o objeto (ou um parente próximo).
4. **Se não existir padrão, ou for raso, ou o pedido tiver algo novo → pesquise:**
   - `WebSearch` com ≥3 consultas em inglês (melhor acervo), ex.:
     `"pixel art <objeto> side view tutorial"`, `"<objeto> pixel art sprite reference"`,
     `"pixel art <material/técnica> <objeto>"` (ex.: "pixel art moon rock texture clusters").
   - `WebFetch` em 1–3 tutoriais/fontes boas (Slynyrd Pixelblog, saint11/Pedro Medeiros, Lospec,
     Pixel Parmesan, pixnote, Aseprite community) extraindo **regras acionáveis**:
     silhueta característica, proporções, materiais, como sombrear, erros comuns, contagem de frames.
   - Se a primeira rodada vier rasa, use `mode: "extended"`.
5. Escreva/atualize `references/patterns/<slug>.md` (modelo em `references/patterns/_TEMPLATE.md`)
   com fontes, e registre no `INDEX.md`.
6. Resuma ao usuário em 3–6 bullets o que aprendeu e como vai aplicar.

### Etapa 3 — Plano
Antes de codar, escreva (no chat, curto):
- Grade, rampas escolhidas e **orçamento de cores** (ver style-guide), direção da luz.
- Silhueta em **esboço ASCII** na resolução real ou em meia resolução.
- Técnicas: contorno/selout, dithering (onde e qual padrão) ou clusters, AA interno.
- Para animação: lista de frames com duração (ms).

> **Cenas/fundos/mundos e qualquer arte do estilo fofo: siga `references/cute-scene-method.md`** (método aprovado
> em 2026-10-04: kit de peças desenhadas em meia resolução + cel + contorno colorido + Scale2x, composição com
> poucos elementos grandes, validação NO JOGO e apresentação em HTML aberto no Chrome).

### Etapa 4 — Construir em passes (como no Aseprite)
Crie `art/src/<categoria>/<nome>.py`. Construa em camadas, **salvando prévia a cada passe relevante**:
1. **Silhueta** em uma cor (`polygon`, `ellipse`, `paint` com ASCII, `mirror_x` para simetria).
   Julgue a silhueta sozinha na prévia 1x — se não for reconhecível, refaça antes de continuar.
2. **Cores base** (blocos planos por material).
3. **Luz e sombra** seguindo a rampa (`shift(cor, ±n)`), luz do style-guide. Formas, não "pillow shading".
4. **Textura**: clusters (`clusters`) ou dithering (`dither`, `gradient`) — com as regras do fundamentals.
5. **Detalhes e brilhos** (poucos, intencionais).
6. **Contorno / selout** (`selout` ANTES de `outline`), **AA interno** manual onde houver jaggies.
7. **Limpeza**: `cv.lint(...)` — trate órfãos, cotovelos de contorno, excesso de cores.

`paint()` com desenho ASCII é o modo preferido para detalhes finos — é literalmente pintar pixel a pixel.

### Etapa 5 — Validar (loop até ficar bom)
- `cv.save(path)` valida paleta e gera `art/previews/<nome>_preview.png` (ampliada + 1x + 2x).
- **Abra a prévia com Read** e critique com o checklist abaixo. Tiles: abra também `_tiled.png` /
  `_fill_tiled.png` e `_testmap.png`. Animação: abra `_sheet_preview.png` (GIF não é visualizável pelo Read).
- Corrija e repita. Não mostre ao usuário algo que falha no checklist.

**Checklist de revisão**
- [ ] Silhueta legível em 1x? O objeto é reconhecível sem cor?
- [ ] Luz consistente com o style-guide em todas as partes?
- [ ] Clusters limpos (sem ruído/pixels órfãos sem função)? Sem banding (degraus paralelos iguais)?
- [ ] Linhas e contornos pixel-perfect (sem cotovelos), curvas com degraus progressivos (1-2-3, não 1-3-1)?
- [ ] Contraste suficiente contra o fundo onde vai aparecer (espaço escuro / terreno)?
- [ ] Orçamento de cores respeitado? Rampas coerentes (hue shift, não só preto/branco)?
- [ ] Tile: sem costura visível no tiled, sem "feature" centralizada que denuncia a grade?
- [ ] Animação: loop sem salto, silhueta estável, timing variado onde precisa de peso?

### Etapa 6 — Aprovação e export
Mostre ao usuário o caminho da prévia e um resumo das decisões. Após aprovação:
- Sprite: `cv.save("assets/sprites/<nome>.png")`.
- Animação: `save_animations([...], "assets/sprites/<nome>.png", tres_path="assets/sprites/<nome>_frames.tres")`
  → spritesheet + JSON + GIFs + `SpriteFrames` para `AnimatedSprite2D`.
- Tileset: `save_tileset(template, "assets/tiles/<nome>.png", mode="blob47", tres_path="assets/tiles/<nome>.tres", terrain_name="<nome>")`
  → folha + `TileSet` com terrain set e peering bits prontos.
- Rode `python3 .claude/skills/pixel-art/scripts/pixelart.py check assets/**/*.png`.

### Etapa 7 — Alimentar a biblioteca
Atualize `references/patterns/<slug>.md` com o que funcionou, o que foi corrigido na revisão e
decisões do usuário. Se surgiu decisão global (ex.: "contorno sempre `ink`"), grave em `style-guide.md`.

## API rápida (`scripts/pixelart.py`)

```python
cv = Canvas.grid32()                         # grid16 / grid64 / Canvas(w, h) / Canvas.for_kind("tile")
cv.px(x, y, "steel");  cv.pxs(pontos, "ink")
cv.rect(x, y, w, h, cor, fill=True); cv.hline(x0, x1, y, cor); cv.vline(x, y0, y1, cor)
cv.line(x0, y0, x1, y1, cor)                 # Bresenham pixel-perfect
cv.ellipse(cx, cy, rx, ry, cor, fill=True)   # diâmetro par -> centro .5
cv.polygon([(x, y), ...], cor, outline=None); cv.flood_fill(x, y, cor)
cv.paint(["..ab..", ".abba."], {"a": "ink", "b": "steel"}, x=0, y=0)   # desenho ASCII
cv.stamp(outro, x, y); cv.mirror_x(); cv.flip_h(); cv.rotate90(); cv.crop(x, y, w, h)
cv.wrap_shift(dx, dy)                        # tiled mode: centraliza a costura p/ corrigir
cv.dither(regiao, a, b, level, pattern="bayer4"|"checker"|"bayer2"|"noise"|"hstripe"|"vstripe"|"diag")
cv.dither_rect(x, y, w, h, a, b, level); cv.gradient(x, y, w, h, [cores], vertical=True)
cv.clusters(regiao, cor, count, size=(2, 4), seed=0, wrap=True)   # textura orgânica
cv.scatter(regiao, cor, density, seed, min_dist)                  # estrelas, poeira
cv.selout(light_dir=(-1, -1)); cv.outline("ink"); cv.drop_shadow(cor)
cv.where(cor); cv.opaque(); cv.replace(a, b)
cv.lint(max_colors=12, wrap=False, outline_color="ink"); cv.colors_used(); cv.orphans()
cv.save(path, tiled=False); cv.preview(path); cv.tiled_preview(path)
shift("steel", -2)  # anda na rampa (escurece 2)   ramp("fire")  RAMPS  COLOR_NAMES
Animation("idle").add(frame, ms)             save_animations([...], png, tres_path=...)
TileTemplate(fill, island, hstrip, vstrip, inner)  save_tileset(...)  terrain_test_map(t, layout)
```
CLI: `pixelart.py colors | sizes | palette out.png | check *.png | lint x.png [--wrap] | preview x.png [--tiled]`.

Cores aceitas: nome (`COLOR_NAMES`), hex da paleta (`"#9babb2"`), índice 0–63, ou `"clear"`.
Scripts devem ser **determinísticos** (use `seed`), para que rodar de novo reproduza o mesmo asset.
