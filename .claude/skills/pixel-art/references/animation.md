# Animação e efeitos

## Princípios aplicados a pixel art
- **Poucos frames bem escolhidos > muitos frames**. Cada frame custa desenho e revisão.
- **Poses-chave primeiro** (extremos), depois intermediários só se precisar.
- **Timing variável**: segure os extremos (frames mais longos) e acelere o movimento (curtos) → peso.
- **Antecipação** antes de ações fortes (1 frame recolhendo antes de disparar/pular).
- **Squash & stretch** leve (1px) dá vida mesmo a objetos rígidos (pouso do lander).
- **Ação secundária**: partículas, poeira, luzes piscando — mas não roube a leitura da principal.
- **Silhueta e volume estáveis**: o sprite não pode "tremer" de tamanho sem intenção.
- **Loop**: o último frame deve levar ao primeiro sem salto; revise a folha lado a lado.
- **Cuidado com dithering animado**: pontilhado que muda de frame a frame pisca.

## Contagem de frames e tempos (ponto de partida)
| Animação | Frames | Duração/frame | Notas |
|---|---|---|---|
| idle (respiração, luz piscando) | 2–4 | 150–400 ms | sutil, 1px de variação |
| chama de propulsor (loop) | 3–4 | 50–90 ms | tamanho e forma variam; núcleo claro (white/lemon) → gold/amber → orange → brick nas pontas |
| explosão | 6–10 | 40–80 ms início, 100+ ms fumaça | flash branco 1 frame → bola de fogo cresce → fragmenta → fumaça escura se dissipa |
| fumaça/poeira | 4–6 | 80–120 ms | expande, clareia/escurece e some; clusters, não dither |
| pickup girando/brilhando | 4–6 | 80–100 ms | brilho percorre a forma |
| pouso (squash) | 3–4 | 60–100 ms | comprime 1px, volta com overshoot |
| UI (botão, ícone de upgrade) | 2–3 | 100–150 ms | feedback curto |

## Efeitos (FX)
- Fogo/chama: rampa `fire` (maroon → brick → orange → amber → gold → lemon → white). Mais quente/claro
  perto da fonte; pontas escuras e fragmentadas. Formas em "gota/língua", não retângulos.
- Explosão: formas circulares irregulares; o 1º frame pode ser o maior contraste (flash). Fumaça usa
  rampa `neutral` ou `warm_rock` escura. Detritos: 1–2px voando para fora.
- Brilho/energia: rampa `teal`/`blue` com white no núcleo.
- Efeitos normalmente **sem contorno**; usam contraste de valor.

## Exportação
```python
anims = [Animation("thrust"), Animation("idle", loop=True)]
for i in range(4): anims[0].add(frame_i, 70)
save_animations(anims, "assets/sprites/lander.png", tres_path="assets/sprites/lander_frames.tres")
```
- Folha: uma linha por animação, frames em colunas; `.json` com metadados.
- `art/previews/<nome>_sheet_preview.png` para revisar (abra com Read); GIFs por animação para o usuário.
- `.tres` = `SpriteFrames` para `AnimatedSprite2D` (FPS e durações relativas já configurados).
