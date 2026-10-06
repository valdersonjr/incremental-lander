# Ratinhos das missões (um por tipo)

- **Slug**: mission-mice
- **Tipo**: retratos 24x24 (atlas kids: rat_simple, rat_heavy, rat_soft, rat_fast, rat_passenger, rat_tow, rat_double)
  + ícones 16x16 no atlas das cargas (weight, clock, star)
- **Assets**: `assets/ui/kids.png` ← `art/src/ui/kids_ui.py` (MISSION_MICE); `assets/sprites/cargo.png` ← `art/src/sprites/cargo.py`
- **Onde aparece**: pino e cartão do pedido (quem pediu = tipo da missão), aba PEDIDOS da oficina; ícones no HUD/pino.

## Pesquisa
- Silhueta primeiro: encher de preto e reduzir; cada personagem tem que ser reconhecido só pela forma.
- **Um elemento-assinatura** (chapéu/arma/rabo) muda a silhueta; detalhe interno some na distância de jogo.
- 2–3 cores dominantes por personagem; hierarquia primária/secundária/acento.
- Linguagem de formas: redondo = amigável; quadrado = forte/estável; triângulo/inclinado = rápido/perigo.

## Receita
- Base comum `mouse_face(fur, inner, ...)`: orelhonas, cabeça `mc.sphere` (rampa de 4 tons), olhos 2x2 com brilho no
  canto de cima-esquerda, focinho e bochecha rosa, bigode lilac_grey; contorno ink no fim (depois do acessório).
- Simples: branco + capacete gold com lanterna · Pesada: caramelo (honey→rust), cabeça larga (rx 8,4), faixa red ·
  Suave: rosado (cream→rose), chapéu de chef alto (esfera branca) · Rápida: cinza-azulado, boné listrado sky/white com
  aba para a frente + risquinhos · Passageiro: cinza, quepe gold com faixa quadriculada + bandeirinha red · Cabo:
  lavanda, laço hot_pink e cordinha copper com gancho steel · Dupla: chocolate (copper→maroon) com coroa e pedra emerald.

## Revisão
- v1: sobrancelha grossa no ratão = cara brava (mesma lição do gatinho: olhos simples = fofo) → tirada.
- v1: corda enrolada da ratinha do cabo parecia moeda com "+" → cordinha vertical com gancho.

## Decisões do usuário
- 2026-10-06: pediu ratinhos "com características e cores distintas uns dos outros para ficar visual cada missão".

## Fontes
- https://80.lv/articles/character-design-shape-language-and-readability/ — silhueta ~70% do impacto; teste em preto
- https://rocketbrush.com/blog/shape-language-in-game-character-design-how-to-make-characters-readable-and-consistent — formas e elemento-assinatura
- https://openskillindex.com/skills/vibeforge1111-vibeship-spawner-skills-character-design — 2–3 cores dominantes; silhueta → cor → detalhe
