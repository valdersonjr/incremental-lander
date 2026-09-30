# Prestígio, múltiplos recursos e automação

## Prestígio (reset com bônus permanente)
Propósitos: (1) sensação de "subir a escada" — reset → multiplicador grande → poder; (2) domar o
crescimento exponencial em números administráveis para balancear.

| Jogo | Base | Fórmula | Dobrar a moeda exige |
|---|---|---|---|
| AdVenture Capitalist | ganhos da vida toda | `150·sqrt(c/1e15)` | ~4× ganhos |
| Realm Grinder | ganho máximo | `(sqrt(1 + 8c/1e12) − 1)/2` | 4× |
| Cookie Clicker | ganhos da vida toda | `cbrt(c/1e12)` | 8× |
| Egg, Inc. | ganhos do run | `(c/1e6)^0.14` | ~128× |
| Clicker Heroes | upgrades comprados | ~log | — |
(Fonte: Math of Idle Games III.)

- **Vida toda** (lifetime): pode resetar no mesmo ponto e ainda ganhar (cada vez menos) → incentiva ir
  mais longe. **Por run** (`based_on` + ganhos desde o reset — padrão aqui): resetar no mesmo ponto rende
  o mesmo → incentiva otimizar o run.
- Expoente menor = achata mais o crescimento (bom quando há progresso offline forte).
- `econ.py`: `prestige = {resource, based_on, formula: sqrt|cbrt|pow|log10, scale, mult, min_gain,
  requires_planet, keep: [money|upgrades|planets], bonuses: [{stat, per_point}]}`.
- **Timing ótimo**: resetar quando a velocidade de progresso atual cai abaixo do que o bônus devolve.
  O simulador usa `ganho ≥ prestige_ratio × pontos` (casual espera mais, expert reseta antes).
- Metas de verificação: 1º prestígio na janela do style-guide; ganho por prestígio cresce; intervalo
  entre prestígios não despenca para minutos (senão é "clicar reset" e não jogar).
- Tema no jogo: "Poeira Estelar" ao abandonar a frota/companhia e recomeçar com reputação.

## Múltiplos recursos
- Cada recurso precisa de fonte e dreno próprios; conversões entre eles são **válvulas** de ritmo.
- Uso aqui: **créditos** (tudo), **minério** (vem de planetas novos; paga upgrades avançados e
  desbloqueios) → faz o planeta novo ser necessário, não só "mais dinheiro".
- `resource_value` converte multi-recurso num valor escalar para o ROI do simulador (quanto o jogador
  "sente" 1 minério em créditos). Ajuste se o simulador ignora/abusa de um recurso.
- Riscos: estratégias dominantes em economias interdependentes; conversões ilimitadas quebram o
  equilíbrio → limite taxas de conversão, custos crescentes na conversão.
- Recurso por planeta (Idle Planet Miner): cada mundo com minério próprio + receitas (ligas) é uma boa
  expansão futura.

## Automação (mais tarde no jogo)
- Entra quando o loop ativo já foi dominado (o jogador "sabe" pousar): piloto automático para rotas
  curtas, frota de landers com renda/s.
- Modelagem futura: renda idle = Σ landers × entregas/s × pagamento × eficiência_auto (< humano
  expert, para pilotar continuar valendo). Automação deve **liberar atenção** para metas maiores
  (planeta novo), não substituir o jogo.
- Offline (não pedido por ora): se entrar, limitar (ex.: 2–8 h, eficiência 50%).

## Marcos (milestones)
- AdCap: ×2 em 25/50/100 unidades; Guan: bônus a cada 10 níveis. `effect.op = "milestone"`
  (`value`, `every`). Criam objetivos de curto prazo e picos de renda que quebram paredes.
