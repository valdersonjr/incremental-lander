# Padrão: cenários e moradores dos mundos novos (Fase 18.5, 2026-10-07)

## O que é
Os 5 mundos depois da Lua (Nuvens, Cogumelos, Sorvete, Jardim, Bolhas): cenário em camadas, figuras dos minijogos,
morador de corpo inteiro na conversa + rostinho 24x24, palco da conversa e planetinha do Mapa.

## Como foi feito (reaproveitar, não redesenhar)
- **Mesmo kit da Lua** (`moon_cute.py`): `art/src/bg/world_scene.py` troca só o TEMA (`THEMES[mundo]`, rampas da
  Resurrect 64) e as PEÇAS do plano do meio; céu/morros/névoa/chão/pedras saem das funções da Lua com `mc.T = tema`.
- Cada mundo tem um **foco** no céu (sol sorridente; lua dormindo à noite nos Cogumelos; sol-flor no Jardim) e uma
  **silhueta própria** no plano do meio (carneirinhos + balões, cogumelos gigantes + sapinhos + vaga-lumes, casquinhas +
  pinguins + iglu, flores gigantes + abelhas + joaninhas, mar + ilhas com coqueiro + baleia).
- Moradores e objetos do fundo desenhados em meia resolução e ampliados com **Scale2x** (ficavam pequenos demais
  em 1x — revisão 1). Grupos em números ímpares, perto dos "ombros" dos morros.
- **Armadilha de cor**: `ice` da paleta é MENTA (#8ff8e2), não azul-gelo — faixas verdes no céu. Use `pale_sky` /
  `lavender` para céu e gelo.
- Figuras de minijogo (`art/src/sprites/minigame_props.py`) no tamanho exato dos números do `world.json` (1 m = 1 px):
  chapéus 56/44/36, caule 14; texturas que repetem (talo, caule, mar, gelo) saem como PNG próprio
  (`AtlasTexture` não repete no Godot).
- Moradores (`art/src/sprites/world_npcs.py`) no molde do ratinho (`mouse_hero.py`): 44x56 em k=1, k=1,25 na conversa,
  virados para a esquerda, poses rest/talk/happy, segurando a carga do pedido do mundo. Rostinho 24x24 = recorte da
  cabeça em k=0,75 (`kids_ui.npc_face`).
- Planetinhas do Mapa (`art/src/ui/map_planets.py`) em **1x** (60 px; antes 24 px ampliado 2x misturava a escala de
  pixel), versões aberto / bloqueado (cinzas por brilho) / completo (anel dourado + bandeira).

## Fontes
- Slynyrd Pixelblog 62 (planos por valor, névoa): https://www.slynyrd.com/blog/2026/5/27/pixelblog-62-landscape-backgrounds
- sprite-ai, fundos em pixel art: https://www.sprite-ai.art/blog/pixel-art-backgrounds
- Scale2x/EPX: https://www.scale2x.it/algorithm
- Método aprovado da Lua: `references/cute-scene-method.md`
