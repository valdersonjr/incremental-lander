# Recompensas em cadeia: coleta de cristal e estalo de combo

- **Assets** ← `audio/src/sfx/reward_sfx.py --export`: `assets/audio/sfx/crystal_1.wav`, `crystal_2.wav`,
  `crystal_3.wav` (sfx), `assets/audio/sfx/combo_2.wav` … `combo_5.wav` (sfx). Resumo: `audio/previews/reward_reel.wav`.

## Receita
- Cristal: sino de vidro FM (ratio 3,5; índice 2,2 → 0,2) na nota + seno na quinta (−9 dB) + tique de ruído HP 4 kHz
  (12 ms, −16 dB); decaimento τ 85 ms, 0,32 s; LP 7 kHz. Notas A5 → B5 → D6 (graus seguidos da pentatônica de D):
  o 1º, 2º e 3º cristal do mesmo salto sobem — a cadeia "se ouve".
- Combo: arpejo de 3 notas pulando um grau (pulso 12,5%, 45 ms por nota) + faísca FM na oitava; começa em D5/E5/F#5/A5
  para combo 2/3/4/5. Toca logo depois do jingle de entrega.

## Pesquisa (regras)
- Ações encadeadas: subir o pitch a cada passo reforça o tamanho da cadeia e a satisfação (gamedeveloper.com).
- Coleta clássica (sfxr Pickup/Coin): nota + quinta, ataque rápido, decaimento exponencial.
- Combo: feedback que escala (som mais agudo/intenso a cada passo) acompanha o multiplicador sem precisar olhar.
- Sons frequentes: curtos, sem brilho > 8 kHz (aqui < 1% acima de 8 kHz), secos.

## Integração
- `Sound.sfx("crystal_%d" % n)` na coleta (n = 1..3 no salto); `Sound.sfx("combo_%d" % mini(streak, 5))` ao pousar
  com streak ≥ 2.

## Decisões do usuário
- Usuário prefere não auditar som por som (2026-10-01): resumo tocado uma vez (2026-10-03).

## Fontes
- https://www.gamedeveloper.com/audio/the-power-of-pitch-shifting — pitch subindo em cadeias/combos
- https://pyfxr.readthedocs.io/en/stable/generating.html — gerador Pickup/Coin do sfxr
- https://www.vinzius.com/snippets/coin-pickup-sound-effect-godot-4/ — "ding" = nota + quinta, ataque rápido, decaimento exponencial
- https://bugnet.io/blog/how-to-build-a-combo-system-that-feels-good — feedback de combo que escala

## Auditoria v2 (2026-10-09)
- crystal: índice FM acompanha a altura (`(B5/nota)^4`, até B5 = igual): o D6 tinha 23% > 5 kHz contra 6–7% dos irmãos → 8%. Cristais 1 e 2 idênticos byte a byte. No Sound, a família conta junta no limite de instâncias (3). Ver `mix-system`.
- 2026-10-09: `combo_2..5` apagados — o pouso perfeito ganhou som próprio (`step-sfx` perfect, escolhido pelo usuário).
