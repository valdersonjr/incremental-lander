# SFX de gameplay e UI — pacote básico (pouso, batida, entrega, clique, compra, negado)

- **Assets** ← `audio/src/sfx/game_sfx.py`: `assets/audio/sfx/landing_0{1,2,3}.wav` + `landing.tres`, `crash.wav`
  (impact), `delivered.wav` (jingle) · `audio/src/ui/ui_sfx.py`: `assets/audio/ui/click_0{1,2,3}.wav` + `click.tres`,
  `buy_0{1,2,3}.wav` + `buy.tres`, `denied.wav`. Resumo tocado ao usuário: `audio/previews/sfx_reel.wav`.

## Receitas (a partir de sfx-recipes.md)
- Pouso: `p_landing` + clanque FM (ratio 1,41) do trem na plataforma; 3 variações.
- Batida: zap de plasma (FM descendo 2,2k→180 Hz, casa com o flash ciano do FX) + `p_explosion` com `drive` 1,6.
- Entrega: arpejo D5-F#5-A5-D6 em pulso 25% + sino FM na nota final (curto: toca a cada entrega).
- Clique: tom de pulso ~1 kHz na escala, 60 ms, LP 3k + tick de ruído; 3 variações (pitch ±5% no randomizer).
- Compra: `p_coin` com LP 5 kHz (menos estridente); 3 variações. Negado: segunda menor descendo, pulso 12,5%.

## Integração (Godot)
- Autoload `Sound` (`autoload/sound.gd`): `Sound.ui(nome)` (bus UI) / `Sound.sfx(nome)` (bus SFX), 8 vozes.
- Eventos: escolher entrega = click; COMPRAR/MAX = buy ou denied (pelo retorno de GameState); decolar/continuar =
  click; pouso = landing; entrega no alvo = delivered; batida = crash.

## Decisões do usuário
- 2026-10-01: o usuário não quer auditar som por som ("escolhe qualquer 1") → pacote gerado seguindo a skill e tocado
  uma vez em sequência para aprovação geral.

## Fontes
- (receitas e regras de sfx-recipes.md / fundamentals.md; pesquisa de propulsor em thruster.md)
- https://opengameart.org/content/8-bit-sound-fx — referência de SFX 8-bit de lander

## Auditoria v2 (2026-10-09)
- Pouso: thump −8 dB + "tuc" de triângulo A3→D3 (0,12 s) + poeira em banda 250–1500 Hz + clanque −11 dB, passa-baixa 5 kHz: 93% → 25% < 120 Hz, perda no notebook 10 → 3 dB. Entrega: passa-baixa 4,5 kHz e sino tau 0,18 (agudo 16% → 2%, 1,4 → 0,9 s; o combo entra 0,35 s depois por cima). Variações agora sorteadas no Sound (sem .tres). Ver `mix-system`.
