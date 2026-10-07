# Janela de conversa do pedido (gatinho herói × ratinho de corpo inteiro)

- **Slug**: mouse-dialogue
- **Tipo**: sprites animados + ui (palco, botão verde)
- **Grade**: gatinho k=1.15 (73x82); ratinhos k=1.25 (55x70); palco 408x112
- **Assets**: `assets/sprites/talk_cat.png`, `assets/sprites/talk_mouse_<tipo>.png` (+ `_frames.tres`, 7 tipos),
  `assets/ui/talk_stage_luna.png`, `assets/ui/luna/button_go.png`, `button_go_hover.png` ← `art/src/ui/mission_talk.py`
  (usa `art/src/sprites/cat_hero.py` e `art/src/sprites/mouse_hero.py`); maquete aprovada:
  `art/previews/mission_talk/index.html` ← `art/src/ui/mission_talk_mockups.py`

## Por que o pedido
Usuário (2026-10-07): "melhorar a cena de aceite de missão onde estaria o gatinho laranja astronauta conversando com o
ratinho e não apenas uma nave parada numa plataforma" → escolheu "janela de conversa" (não zoom no mapa).

## Pesquisa
- Chibi animal: cabeça 60–70% da altura, corpo de pera, membros curtos e cegos, olhos grandes, simplificar.
- Diálogo com 2 retratos: cada um de um lado, virados para o meio (conversa "calorosa"); separação entre eles.
- Retrato falando: poucos quadros (boca aberta/fechada + piscar) bastam; pulinho dá vida.

## Receita
- `mouse_hero.Mouse(kind, k)`: mesmas primitivas do gatinho (`sphere`/`capsule`), virado para a ESQUERDA (focinho e
  olhos deslocados), orelhonas com miolo, rabinho fino rosa enrolado, barriguinha clara; **corpo contornado antes da
  cabeça** (senão a cabeça "flutua"); carga do cargo.py (16 px) centrada na barriga com as mãozinhas por cima.
  Pelo/acessório = o rostinho 24x24 do mesmo tipo (mission-mice), em escala.
- Gatinho: poses novas `thumb` (braço erguido + polegar aqua) e `worried` (sobrancelha rust inclinada, boca "o",
  gotinha de suor no vidro).
- Palco: só céu + nuvens + Terra + morros distantes (a camada do meio tem moinho/casas/varal = poluído atrás dos
  personagens); Terra ATRÁS dos morros, com o rosto à vista. Chão de queijo = faixa da UI.
- Botão de aceitar = botão principal recolorido (violeta → verde da paleta).

## Revisão (o que o usuário corrigiu)
- Dinheiro em cada botão = poluído → **só o valor final embaixo** ("Você ganha").
- Perguntas ("Pra onde?") → **rótulos** ("Distância", "Tamanho da plataforma", "Dificuldade"); botões só com texto.
- Clicar na plataforma para partir → **botão ACEITAR MISSÃO**.
- "Desorganizado": 2 balões soltos + rótulos à esquerda → **1 balão** (pedido / regra) e **colunas** (título em cima,
  opções empilhadas), rodapé alinhado.
- 3 mineiros iguais na fila = parecia duplicado → **um rostinho por ratinho**; distâncias viram coluna.
- Fila sempre com **todos** os ratinhos; os não liberados em silhueta (álbum de figurinhas).
- Recorte do mapa trouxe um poste da mina para o lado do gatinho → olhar as bordas do recorte.

## Fontes
- https://tips.clip-studio.com/ko-kr/articles/4895?org=1 — proporções chibi
- https://adventurecreator.org/node/150 — retratos de personagens em diálogo
- https://humbird0.com/makes/experiments/character_portraits/content.htm — retrato animado (boca/olhos em poucos quadros)
