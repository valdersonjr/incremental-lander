# Lua em guerra — narrativa de fundo

- **Slug**: moon-war
- **Tipo**: bg (assado nas camadas, animado por quadros) + sprites para a dinâmica no Godot
- **Grade**: disco 24x10 (4 quadros) · disco distante 12x6 (2) · clarão 16x16 (6) · nave-mãe 212x62 no céu
- **Assets**: `assets/bg/luna_sky.png` (6 quadros, nave-mãe), `assets/bg/luna_mid.png` (4 quadros, bases),
  `assets/bg/luna_plain.png` (4 quadros, disco abatido), `assets/sprites/war_saucer.png`, `assets/sprites/war_saucer_far.png`,
  `assets/sprites/war_blast.png` ← `art/src/bg/moon_war.py` (exportado por `moon_scene.py --export`)

## Características visuais (pesquisa)
- Batalha de fundo = menos contraste e escala menor que o primeiro plano (lander/terreno sempre leem primeiro).
- Lados com cores fixas: alienígenas verde-ácido (lime/leaf/green/pine), humanos ciano nas janelas + traçantes âmbar/dourado.
- Disco voador side-view: cúpula de vidro + disco metálico + luzes da borda correndo + brilho embaixo (Kenney/OpenGameArt).
- Projéteis = riscos claros curtos; explosões distantes: clarão branco → bola dourada → anel laranja → fumaça.
- Nave-mãe: silhueta colossal, escura (contra a luz), borda de cima clara e barriga com reflexo do chão (senão some no céu).

## Como construir
1. Nave-mãe: perfil de cima (casco + cúpula), cinturão com janelas em onda, barriga shadow/charcoal com borda slate,
   anel de luzes e núcleo pulsando; posição entre os painéis do HUD e a Terra (x 196–408).
2. Bases: assentadas no topo da camada mid (varre a 1ª linha opaca); cúpula r=8 + torre de comando + torre de canhão
   (cano diagonal; a boca vira "muzzle" no contrato) + antena com luz vermelha; uma base destruída com fogo.
3. Fogo/fumaça: fumaça ESCURA (ink/shadow com borda slate) em puffs que sobem e derivam; fumaça cinza clara some na montanha.
4. Dinâmica (WarFx): discos cruzam a faixa do céu, laser 2 px até a base mais próxima (+ clarão), torres disparam
   rajadas de 3–5 traçantes no disco mais próximo, acerto = clarão, 30% derruba (cai com rastro de fumaça e explode).

## Erros comuns / o que deu errado na revisão
- Nave-mãe fina = "chapéu"; barriga ink some no céu ink → barriga shadow + borda slate.
- Nave-mãe no canto superior esquerdo ficou atrás do painel de gás no jogo → centro do céu.
- Fumaça slate/shadow sumia sobre a montanha slate; fumaça descolada do fogo (começava alta demais).
- Texturas reexportadas: rodar `gdtool check` (reimporta) antes de `capture`, senão o Godot usa o cache antigo.

## Decisões do usuário
- 2026-10-02: escolheu "guerra alienígena" entre guerra/colônia/ruínas/guerra de brinquedo; aprovou a prévia animada.

## Fontes
- https://opengameart.org/node/13519 — disco voador animado simples (cúpula, disco, luzes)
- https://ansimuz.itch.io/battle-backgrounds-pack-5 — fundos de batalha em camadas/parallax
- https://budgetpixel.com/p/39567 — nave-mãe colossal pairando, silhueta contra o céu
