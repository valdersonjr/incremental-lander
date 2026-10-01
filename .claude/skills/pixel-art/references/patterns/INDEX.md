# Biblioteca de padrões

Um arquivo por objeto/família (`<slug>.md`, modelo em `_TEMPLATE.md`). Antes de criar qualquer asset,
procure aqui; se não houver ou estiver raso, pesquise (SKILL.md, Etapa 2) e registre.

| Slug | Objeto | Tipo | Grade | Assets gerados | Atualizado |
|---|---|---|---|---|---|
<!-- ex.: | lunar-rock-terrain | Terreno de rocha lunar | tileset blob47 | 16 | assets/tiles/moonrock.png | 2026-09-29 | -->
| explosion | Explosão da batida (plasma → fogo → fumaça + destroços) e poeira do pouso | fx | 64 / 48x16 | assets/sprites/explosion.png, assets/sprites/landing_dust.png | 2026-10-01 |
| landing-pad | Plataforma de pouso + feixe e marcador do alvo | sprite + anim | 80x28 | assets/sprites/landing_pad.png, assets/sprites/target_beam.png, assets/sprites/target_marker.png | 2026-10-01 |
| moon-scene | Cena da Lua em camadas (céu em faixas, Terra com halo, montanhas facetadas, terreno rico) | bg + terreno | 640x360 | assets/bg/luna_sky.png, assets/bg/luna_planet.png, assets/bg/luna_far.png, assets/bg/luna_mid.png, assets/bg/luna_plain.png, assets/tiles/luna_ground_lit.png, assets/tiles/luna_ground_flat.png, assets/tiles/luna_ground_shade.png, assets/sprites/luna_rocks.png | 2026-10-01 |
| moon-terrain | Terreno da Lua v1 minimalista — REPROVADO (ver moon-scene) | textura + faixa | 64 | assets/tiles/moon_fill.png, assets/tiles/moon_surface.png (pendente aprovação) | 2026-09-30 |
| lander | Nave do jogador (futurista, 32x32 + plasma; Apollo = alternativa) | sprite + anim | 32 | assets/sprites/lander.png | 2026-09-30 |
