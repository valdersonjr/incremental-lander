# Pista "Mais longe" (distância como pontuação)

**Jogos de referência:** Hill Climb Racing 1/2 (Fingersoft), Learn to Fly, Tiny Wings.
**Usado em:** `contracts.track` (v21, 2026-10-11).

## O padrão
- A viagem é um caminho contínuo só para a frente; a distância alcançada é a pontuação e o recorde fica visível no
  chão (bandeira). O jogador entende em 5 segundos: "ir mais longe que da última vez".
- HCR2 (modo Aventura): os galões de gasolina ficam **mais espaçados** conforme avança; sacos de moedas por distância
  (o 1º do melhor geral em ~200 m paga 1.000; os seguintes +50 cada, teto 3.000 em ~8.500 m). Moedas por run
  dependem da distância.
- Recompensa de 1ª vez por marco (por fase) + moedas no caminho = o "ir mais longe" sempre paga algo novo.

## Como aplicamos (números v21)
- Pouso paga `track_base(x do começo)` = 43 × (0,3 + (x/400)^0,7) × qualidade × plataforma; pular uma = +25%.
- **Armadilha (medida):** num lander balístico, salto longo gasta MENOS gás por metro (Δv ∝ √d). Se a dificuldade
  vier só de vãos maiores, a nave forte voa para sempre (runs de 30+ min). A viagem acaba porque o **relevo sobe**:
  Δv × (1 + x/rough_scale) — no jogo, morros e desníveis maiores quanto mais longe (visível, como as subidas do HCR).
- Gravidade baixa (Nuvens) pede `rough_scale` menor, senão o mundo domina a renda.
- Galões: 35% do tanque, 1º a 350 m, depois a cada 450 × (1 + x/1000) m.
- Marcos a cada 250 m: 3 × base na 1ª vez por mundo → 7–16% das moedas (casual recebe mais em proporção).
- Estrelas = nota do pouso (1 + bom + perfeito) → ~2 por pouso; as Estradas por mundo subiram ×5.

## Efeito medido
Ver `balance/CHANGELOG.md` v21: 1ª compra ~110 s, intervalo mediano ~5 min, run ~250 s (engajado), mundos em
0,4–2,5 h (engajado), expert < engajado < casual, ~1/3 dos pousos pulam uma plataforma.

## Fontes
- https://hillclimbracing2.fandom.com/wiki/Adventures (galões mais espaçados; sacos de distância)
- https://www.macworld.com/article/671066/how-to-win-at-hill-climb-racing.html (marcos com bônus na 1ª vez; moedas por distância)
