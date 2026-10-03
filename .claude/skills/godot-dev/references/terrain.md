# Terreno em polígono (decisão do projeto: polígono irregular + plataformas planas)

Fontes: skill pixel-art (`terrain-tiles.md` §7), docs Godot (Polygon2D, CollisionPolygon2D, StaticBody2D,
Geometry2D, FastNoiseLite), projetos de lander em Godot 4 (terreno por seed com plataforma garantida).

## Geração (determinística por seed)
1. Linha de relevo (ridgeline): pontos a cada `step` px ao longo de x; altura por `FastNoiseLite`
   (ou deslocamento de ponto médio) com amplitude por planeta.
2. **Plataformas**: trechos planos de largura `pad_width` nas distâncias das entregas ofertadas
   (as distâncias vêm do run/`EconMath`); marcar cada uma com `pad_id`.
3. Fechar o polígono para baixo (base fora da tela). Limitar inclinação máxima para não gerar paredes
   impossíveis.
4. Mesmo `seed` ⇒ mesmo terreno (testes, demo, telemetria reproduzível).

## Nós
```
Terrain (Node2D, terrain.gd)
├── Body (StaticBody2D)
│   └── Collision (CollisionPolygon2D)   # mesmo polígono da visual
├── Fill (Polygon2D)                      # textura seamless (pixel-art), texture_repeat ENABLED
├── Surface (Line2D)                      # faixa de superfície (pixel-art), modo de textura tile
└── Pads (Node2D)                         # uma Area2D/marker por plataforma (pad_id, centro, largura)
```
- Placeholder (antes da arte): `Polygon2D` com cor sólida + `Line2D` clara na borda.
- Colisão: `CollisionPolygon2D` com `build_mode` sólido; polígonos muito longos → dividir em **chunks**
  (ex.: 2048 px) gerados/liberados conforme a câmera, para física e desenho eficientes.
- Detecção de plataforma: comparar a posição de contato com os intervalos x das plataformas (mais simples e
  determinístico que Area2D para o pouso).

## Planetas
Parâmetros visuais/relevo (amplitude, rugosidade, cor/textura) por planeta em `data/world.json`; física e
distâncias (gravidade, arrasto, faixa de distância) sempre de `data/economy.json`.

## Verticalidade (Fase 11.2, 2026-10-03)
- **Crista entre plataformas seguidas**: lombada em cosseno no meio do trecho (meia-largura 25% da distância),
  pico ≥ `crest.frac` (12%) da distância acima da plataforma mais alta; a inclinação extra é limitada por
  `max_bump_slope`. O arco de 45° sobe d/4 → passa com folga; voar rente obriga a subir (custa gás).
- **Tipos de plataforma** (`terrain.pad_tiers`): largura e `lift_m` (> 0 pico/platô, < 0 vale), encostas com
  `pad_side_slope`; altura da plataforma decidida no relevo de base (antes das cristas); topo re-aplanado no fim.
  Vizinha perto demais → sem elevação (evita degraus impossíveis).
- **Ar denso perto do chão** (`atmosphere`): `LanderPhysics.drag_at()` por passo, com a altitude sobre o relevo.
- Verificar o formato: `godot --headless --path . --script res://tests/tools/dump_terrain.gd` (JSON) + plot em PIL.
- Armadilha: o arco do demo voa 200–350 m acima do chão, e a 1 px/m a tela (360 px) não mostra o relevo no meio do
  salto — captura de frames não serve para ver cristas; use o perfil.
