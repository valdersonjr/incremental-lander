# Prestígio que vale a pena

- **Slug**: prestige-worth-it
- **Onde na spec**: `prestige` (scale, bonuses, keep, min_gain) + `Profile.prestige_ratio`
- **Intenção de design**: resetar deve ser uma decisão empolgante ("vou voltar muito mais forte"),
  nunca uma armadilha que deixa o jogo mais lento.

## Como jogos de referência fazem (pesquisa)
| Jogo | Fórmula / números | Observação |
|---|---|---|
| AdVenture Capitalist | angels = 150·sqrt(lifetime/1e15); +2% por angel | 1º reset com 50–150 angels ⇒ ×2–×4 na próxima partida |
| Regra da comunidade idle | resetar quando dobrar a moeda de prestígio | depois, ≥ 2–3× em fases lentas |
| Realm Grinder / Cookie Clicker | sqrt / cbrt | dobrar exige 4× / 8× ganhos |
| Vários | manter desbloqueios/QoL no reset | reduz a repetição chata |

## Armadilhas conhecidas
- Bônus pequeno (+15%) + reset de desbloqueios ⇒ **prestígio atrasa o jogo**; quem reseta menos "ganha"
  (achado no rascunho v2: sem prestígio todos terminavam mais rápido).
- Checagem obrigatória: simular **com e sem** prestígio. Com prestígio deve terminar mais rápido.

## Modelagem aqui
- Regra do jogador simulado = regra da comunidade: `prestige_ratio` 1.0 (dobrar); casual 1.5, expert 0.7.
- Alvo: 1º prestígio ⇒ ≥ ×2 no pagamento.
- v3: `scale 1e5`, `min_gain 10`, bônus `pay_mult +2%/ponto`, `thrust +0.2%/ponto`; expert override `prestige_ratio 1.0`.

## Efeito medido (simulação, 2026-09-29, v2 → candidato v3)
| Métrica | v2 | Previsto | Medido |
|---|---|---|---|
| Tempo engaged com vs. sem prestígio | 15.1 h vs 14.5 h (prestígio atrasava) | com < sem | 8.5 h vs 14.5 h (só a mudança A) |
| 1º prestígio (pontos → bônus) | 3 pts → +15% | ~50 pts → ×2 | 15 pts → +30% (scale 4e4); v3 final (scale 1e5): 11 pts |
| Expert com regra 0.7 vs 1.0 | — | — | 0.7 empatava com engaged: resetar cedo é jogar pior |
Lições: (1) sem bônus forte, prestígio é armadilha; (2) previsão de pontos errou porque o ganho chega
mais cedo que o estimado — medir, não calcular de cabeça; (3) na v3 o prestígio virou **obrigatório**
(sem ele engaged não termina em 40 h) — decisão de design a confirmar com o usuário.

## Fontes
- https://steamcommunity.com/app/346900/discussions/0/412447331649208445/ — regra "dobrar angels"
- https://www.remodelormove.com/when-should-i-do-my-first-reset-adventure-capitalist/ — 1º reset 50–150 angels ⇒ ×2–4
- https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii — fórmulas de prestígio
- https://www.gamedeveloper.com/design/balancing-tips-how-we-managed-math-on-idle-idol — conferir a causa raiz antes de mexer nos números
