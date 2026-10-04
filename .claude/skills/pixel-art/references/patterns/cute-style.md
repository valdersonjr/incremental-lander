# Estilo fofo (cozy) + gatinho piloto

- **Slug**: cute-style
- **Tipo**: direção de arte (vale para sprites, cenas e UI) + sprite do lander com piloto
- **Grade**: lander continua 32x32 (contrato do jogo: origem (16,16), sapatas na linha y=24)
- **Assets**: `assets/sprites/lander.png` (+ `.json`, `_frames.tres`: idle com piscar 2400/130/1100/130 ms, thrust 4×70 ms)
  ← `art/src/sprites/lander.py` (design em `lander_cute.py`); passo a passo em `art/previews/lander_cute_steps.png`

## Por que o pedido
Usuário (2026-10-04): quer o jogo **todo fofinho/cozy**, referência **Shelldiver** (incremental cozy de pixel art,
tartaruga e águas-vivas fofas). Trocar paleta (teste Resurrect 64 × comfy52) não deu a fofura: ela vem do traço.

## O que torna fofo (análise da referência + pesquisa)
1. **Rosto / personagem**: algo com olhos para o jogador gostar. Olhos grandes, baixos no rosto, afastados
   (≥ 1 olho de distância), com **brilho branco**; nariz e boca mínimos; bochecha rosada.
2. **Proporção chibi**: cabeça ≈ corpo (1:1 a 1:2); membros curtos e redondos ("noodle"/toquinho).
3. **Formas redondas e gordinhas**: curvas em vez de pontas; cantos arredondados; volume "inflado".
4. **Contorno escuro de desenho animado** em tudo que é primeiro plano (personagem, objetos, borda do terreno).
5. **Cor chapada**: 2–3 tons por material, quase sem pontilhado; textura vem de poucos clusters grandes.
6. **Fundo simples**: silhuetas tingidas pela cor do bioma, baixo contraste, sem contorno — o primeiro plano
   contornado "salta".
7. **Vida**: piscar, quiques (squash & stretch), partículas fofas (bolhas, brilhos).

## Gatinho piloto (lander)
- Cúpula de vidro grande (o "capacete") em cima de um casco pequeno e gordinho = proporção chibi.
- Gato laranja (rampa `fire`/`rust`: amber/honey/copper) com focinho `cream`, olhos `ink` 2x2 com brilho `white`,
  nariz `pink`, bochecha `salmon`/`pink`. Orelhas triangulares saindo para cima dentro da cúpula.
- Vidro: fundo `pale_sky`/`ice` atrás do gato, reflexo `white` em arco no canto de cima-esquerda (luz do jogo).
- Casco mantém a identidade do jogo: branco/`mist` + faixa `sea`; pernas curtas com sapatas redondas.
- Animação idle: piscar (olhos fechados 1 quadro ~120 ms a cada ~2 s).

## Erros comuns
- Olhos altos e juntos → cara "esquisita"/assustada. Olhos baixos e afastados → fofo.
- Pontilhado em sprite pequeno vira sujeira e tira a fofura.
- Contorno `ink` some sobre fundo `ink` (espaço): usar fundo de cena mais claro ou borda clara no lado da luz.

## Revisão (v1 → v3)
- v1: orelhas em bloco viraram "hamster"; cabeça enchia a cúpula (não lia como capacete); prévia sobre `ink` sumia
  o contorno; 17 cores. → orelhas em triângulo nos cantos (apex para cima/fora), cabeça rx 5 dentro da cúpula 7.5,
  prévia sobre o céu real do jogo, sem `honey`/`salmon` (15 cores, lint limpo).
- v2 → v3: olhos 2×2 pareciam bravos; **olho 2×3 (mais alto que largo) com brilho no canto de cima-esquerda** = fofo.
- Sombra do casco só na ponta direita (x ≥ 22); corte vertical no meio parecia emenda.

- v3 → v4 (usuário: "difícil identificar o gatinho" e "a nave parece a perna dele"):
  - Gato desenhado em canvas próprio **com contorno `ink`** (separa do vidro), orelhas pontudas, **bigodes brancos**
    sobre o vidro e **ombrinhos** visíveis → lê como personagem *sentado dentro* da cúpula.
  - **Anel escuro** (slate/charcoal) entre cúpula e casco; casco virou **disco largo e achatado** (26 px) com luzinhas,
    pernas mecânicas em diagonal → casco gordinho do tamanho do gato lia como "corpo + patas".
  - Cúpula maior (rx 9.5, ry 8) e orelha 1 px mais curta → sobra vidro acima/ao lado do gato (lê como capacete).
- Lição: em personagem dentro de veículo, **o veículo não pode ter proporção de corpo** (largura ≈ cabeça + pernas
  curtas = bicho). Diferenciar por forma (disco largo), por linha de separação e por contorno do personagem.

## Decisões do usuário
- 2026-10-04: piloto = **gatinho astronauta**; quer o jogo todo fofo (muda a direção "futurista limpa" de 2026-09-30).
- 2026-10-04: v4 aprovada ("gostei do gatinho fofo") e integrada ao jogo; captura em voo confere leitura na escala real.

## Fontes
- https://vaporlens.app/app/3862670/shelldiver.md — Shelldiver: incremental cozy, personagens fofos (tartaruga, águas-vivas)
- https://tips.clip-studio.com/fr-fr/articles/4897?org=1 — chibi: cabeça 1:1–1:2, olhos baixos e afastados, membros curtos
- https://www.skillshare.com/en/classes/how-to-draw-cute-eyes-in-procreate-quickly-and-easily/1994860510 — olho grande, íris redonda, brilho branco
- https://www.deviantart.com/vanmall/art/How-to-make-round-objects-in-pixel-art-347907700 — curvas redondas em pixel art
- https://rumblecade.itch.io/astro-sprites-1b — referência de astronauta 32x32 com capacete
- Análise direta das capturas do Shelldiver enviadas pelo usuário (contorno, cor chapada, fundo em silhueta)
