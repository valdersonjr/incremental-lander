# Protótipo de voo (Fase 1)

- **Slug**: flight-prototype
- **Onde no projeto**: `game/flight/`, `scripts/world/autopilot.gd`, `scripts/world/lander_physics.gd`
- **Problema**: fazer o lander voar, pousar e ser verificado automaticamente (modo `--demo`).

## Soluções adotadas
- Física própria em `LanderPhysics.step()` (pura): gás = Δv/eficiência, teste garante o contrato com a economia.
- Autopiloto por **velocidade desejada** → aceleração desejada → empuxo necessário (`a_des − g`) → ângulo do
  nariz (`atan2(Tx, −Ty)`) e propulsor liga/desliga quando o empuxo projetado passa de 35% do máximo.
- Decolagem: enquanto a < 25 m do chão e longe do alvo, subir na vertical (pousado o lander não gira).
- Pouso: `move_and_collide(motion, false, 0.08, true)` — `recovery_as_collision=true`.

## Armadilhas
- Autopiloto que já nasce querendo inclinar trava no chão (nunca alinha, nunca liga o motor).
- Pouso lento encostado não gera colisão com `recovery_as_collision=false` (padrão).
- `run` headless sem `--fixed-fps` roda menos tempo de física do que parece (corrigido no gdtool).
- Autopiloto desce devagar demais (0,3–0,6 m/s nos últimos metros) → gasta mais gás que o modelo prevê.

## Atualização (Fase 4): autopiloto para gravidade forte
- Voar "pairando em cruzeiro" custa g × tempo de Δv: barato na Lua, proibitivo em Ares (tanque inteiro).
  Solução: **arco balístico** — velocidade desejada = a que leva ao alvo sob gravidade em T = sqrt(2|dx|/g)+1,
  mirando um ponto ACIMA da plataforma (40 + 8g m) para sobrar espaço de frenagem; motor só corrige desvios.
- Motor liga/desliga com limiar fixo fica "sempre ligado" quando pairar exige mais que o limiar (Ares) → sobe
  sem parar. Solução: **sigma-delta** (acumula fração empuxo_pedido/empuxo_max; liga quando passa de 1).
- Armadilha de verificação: no zsh, `$VAR` com vários argumentos NÃO é quebrado — o jogo recebeu um único
  argumento. Passe os argumentos literalmente (ou use arrays). O jogo agora valida `--planet`.
