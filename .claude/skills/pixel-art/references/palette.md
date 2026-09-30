# Paleta Resurrect 64 (travada)

Fonte: https://lospec.com/palette-list/resurrect-64 — 64 cores. Folha visual: `palette-ramps.png`.
Lista completa (índice, nome, hex, rampas): `python3 .claude/skills/pixel-art/scripts/pixelart.py colors`.
Os nomes são apelidos do projeto (a paleta não tem nomes oficiais).

## Rampas (escuro → claro) e uso sugerido no jogo
| Rampa | Cores | Uso |
|---|---|---|
| `neutral` | ink, shadow, slate, lilac_grey, steel, mist, white | **rocha lunar/regolito**, metal pintado, fumaça, UI neutra |
| `warm_rock` | ink, shadow, mauve, rosewood, sand, cream | rocha de planeta quente, poeira marrom, areia |
| `metal` | charcoal, deep_sage, sage, lichen, bone, white | casco metálico esverdeado/militar, peças industriais |
| `fire` | maroon, brick, orange, amber, gold, lemon, white | **chama do propulsor**, explosões, lava, alertas |
| `red` | wine, crimson, red, vermilion, coral, peach | perigo, dano, luzes de alerta, faixas de pintura |
| `rust` | umber, wine, rust, terracotta, copper, honey | ferrugem, Marte, cobre, madeira |
| `olive` | umber, olive, moss, lime, lemon | ácido, radiação, planeta tóxico |
| `green` | deep_sage, pine, green, emerald, leaf, sprout | vegetação alienígena, UI de sucesso |
| `teal` | navy, deep_teal, teal, sea, aqua, ice | cristais, gelo, energia, escudos |
| `blue` | ink, navy, indigo, blue, sky, pale_sky, white | cockpit/vidro, UI, céu, água |
| `purple` | ink, plum_dark, plum, purple, violet, lavender | nebulosas, magia/tech alien, raros |
| `pink` | plum_dark, berry_dark, berry, rose, pink, peach, cream | nebulosas quentes, orgânicos |
| `magenta` | plum_dark, magenta_dark, raspberry, hot_pink, salmon, peach, cream | itens épicos, destaques |
| `space` | ink, shadow, navy, indigo | **fundo espacial** (profundo → menos profundo) |

## Dicas
- `shift("steel", -1)` → lilac_grey; `shift("steel", +1)` → mist. Rampa ambígua? passe `ramp_name`.
- Cores que aparecem em várias rampas (ink, white, peach, plum_dark, navy, umber) são "pontes" —
  ótimas para ligar materiais diferentes e para AA entre eles.
- Sombra fria: escureça indo para `shadow`/`navy`/`plum_dark` em vez de só "mais escuro do mesmo".
- Evite `white` puro em áreas grandes; guarde para brilho especular e núcleo de fogo.
- Fundo espacial (`ink`/`shadow`) é MUITO escuro: contornos `ink` desaparecem sobre ele — sprites
  que voam no espaço precisam de luz de borda (rim light) ou selout claro no lado da luz.
