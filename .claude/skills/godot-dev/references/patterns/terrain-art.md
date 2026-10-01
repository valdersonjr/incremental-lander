# Arte do terreno e fundo em camadas (integração pixel-art → Godot)

- **Tema**: Visual · **Atualizado**: 2026-10-01
- **Arquivos**: `scripts/world/terrain_art.gd` (lógica pura), `game/terrain/terrain.*`, `game/background/backdrop.*`,
  `data/world.json` (`background`), contrato `assets/bg/<planeta>_layers.json` (gerado pela skill pixel-art)

## Solução
- **Faixa cisalhada, não Line2D**: Line2D em modo tile gira a textura ao longo dos segmentos (pixels tortos).
  Cada segmento do contorno vira um quad paralelogramo (lados verticais, altura = `strip_depth`) num `Polygon2D`
  por face (`lit`/`flat`/`shade`), com `polygon` + `uv` (pixels da textura; x do mundo → repete com
  `texture_repeat = ENABLED`) + `polygons` (um `PackedInt32Array` de 4 índices por quad). Paralelogramo → mapeamento
  afim exato, cada coluna desce reta = pixel-perfect.
- Face por inclinação do segmento (luz de cima-esquerda): sobe para a direita = `lit`; desce = `shade`.
- Abaixo da faixa: o `Fill` (polígono inteiro) em `deep_color`. Faixas e fill com `show_behind_parent`, então
  `Terrain._draw()` (pedregulhos, plataformas) desenha por cima.
- Pedregulhos: `draw_texture_rect_region` do atlas no `_draw` (um nó só, centenas de pedras), posições
  determinísticas por seed, fora das plataformas.
- **Fundo**: `CanvasLayer` (layer -1) com `Sprite2D` por camada; laço horizontal = `region_enabled` +
  `texture_repeat` e rolagem mudando `region_rect.position.x`; vertical = a camada desce quando a câmera sobe
  acima da altura do chão da partida. `TerrainArt.layer_offset(cam, ref_y, fator)` é pura e testada.
  Usar `camera.get_screen_center_position()` (posição suavizada real), não `global_position`.
- `Parallax2D` existe na 4.7.2, mas a doc não define bem o comportamento vertical com câmera que sobe/desce
  muito; o fundo próprio é simples e testável. Reavaliar se precisar de zoom.
- Planeta sem `<planeta>_layers.json` → `TerrainArt.load_meta` devolve `{}` → placeholder (polígono + Line2D).

## Armadilhas
- Assets nomeados pelo id do planeta (`luna`), não "moon".
- Câmera centrada na nave = terreno em meia tela: a faixa precisa ser funda (176 px), senão sobra bloco chapado.

## FX de uma vez (explosão, poeira) — 2026-10-01
- `Flight._spawn_fx(frames, anim, pos, centered)`: AnimatedSprite2D filho da Flight (desenha por cima do lander),
  `animation_finished -> queue_free`; SpriteFrames com `loop: false` (gerado pela pixel-art).
- Batida: esconder o lander, tocar a explosão e **só então** emitir `delivery_finished` (senão o resumo do run cobre).
- Prévias que forçam situações raras: `tests/visual/crash_preview.tscn` precisa de `WorldConfig.register_input()`
  (as ações de teclado são registradas pela main). Para pouso suave, soltar a 2 px do chão — 12 px de queda já passa
  do limite de 3 m/s (é a regra funcionando, não bug).

## Parallax vertical sem vãos — 2026-10-01
- Camadas que se apoiam umas nas outras (far, mid, plain) precisam do **mesmo fator y**: fatores diferentes abrem vão
  e mostram o fim do céu por baixo (base reta "flutuando"). Profundidade só no fator x.
- Limitar o deslocamento vertical (`TerrainArt.layer_offset(..., min_y, max_y)`): o fundo desce no máximo até sobrar
  `ground_margin` px de planície na tela e sobe no máximo até o fim da textura da planície.
- Verificar em altitude alta (`--dev_levels=thrust:60,...` — formato chave:valor! `--dev_levels=40` não faz nada e a
  demo volta para a Lua sem gás).

