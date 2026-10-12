# Cachorrinho que vem buscar o osso (latido + encontrão)

- **Slug**: dog-sfx · **kind**: sfx · **Fonte**: `audio/src/sfx/dog_sfx.py` → assets/audio/sfx/dog_bark.wav, assets/audio/sfx/dog_bump.wav
- **Quando toca**: bater num osso de pedra no céu da Lua (raro; uma vez por batida). Latido quando o cachorrinho entra,
  encontrão quando ele derruba a nave.

## Receita
- **Latido "au-au"**: pulso 25% com a altura subindo 3 semitons em 20 ms e caindo 10 (a sílaba), filtro passa-faixa
  (svf bp, Q 2,5) que fecha de 1,8 kHz para 700 Hz ("a" → "u", o formante é o que faz soar como boca) + sopro de ruído
  rosa no mesmo filtro; envelope seco (ataque 4 ms, cai para 55% em 35 ms). 2 latidos D5/E5 a 170 ms. Drive leve.
- 1ª versão com envelope plano soou como bipe: latido precisa de ataque forte + queda rápida + pitch que cai bastante.
- **Encontrão**: "vush" de ruído rosa com passa-faixa subindo (400 → 2,6 kHz) e descendo + baque triângulo D3→A2 + ruído
  marrom curto.
- Alternativa B (oitava abaixo, D4/E4) gerada para o usuário comparar (audio/previews/dog_bark_B.wav).

## Fontes
- https://github.com/danja/dogbox — síntese de latido por formantes (F1–F3, envelope de amplitude e de filtro)
- https://electro-music.com/forum/topic-68637.html — "Bark or Bleat": latido lo-fi de chip (precedente retrô)
- https://harrycharltonssoundnotes.myblog.arts.ac.uk/?p=257 — latido retrô: graves fora, agudos realçados, compressão, bitcrush
