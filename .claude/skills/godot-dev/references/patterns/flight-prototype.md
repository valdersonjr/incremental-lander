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
