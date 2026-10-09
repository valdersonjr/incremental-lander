# Auditoria da progressão (2026-10-09): escolha dominante, curva das peças, loop fino, ordem da Estrada

- **Slug**: progression-audit
- **Pedido do usuário**: "progressão meio fraca", "só pousar é fraco", "compensa só missão longa (multiplicador muito
  maior)", "cada pequena evolução já aumenta muito o potencial", "ver se os itens que liberam primeiro fazem sentido".
- **Medição**: `balance/sims/2026-10-09-audit-progressao.py` + `econ.py screen` (spec v18).

## O que os números mostram (spec v18, Lua, perfil engaged)
- **Longe + apertada paga ~17× por gás e ~19× por segundo** mais que perto + normal (início); a proporção não muda
  com a nave. Causa: pagamento ∝ d^1,1 × plataforma (até ×2,2) e custo ∝ √d → valor por gás ∝ d^0,6; o
  `run_fatigue` 1,7^n (cada entrega a mais custa mais gás) empurra para poucas entregas longas. Estrela = 1 por
  entrega (favorece curtas) — dinheiro e estrelas puxam para lados opostos, mas o jogador só vê o dinheiro.
- **Curva das peças em degraus, não suave**: 1 nível de Gasolina no começo = **+245%** de renda (alcança "longe");
  do nível 10 em diante cada nível muda a renda < ±4% (todas as distâncias já alcançáveis: teto de 15 km).
- **Gás deixa de existir**: nível 40 = tanque 9.305, salto longo 6,5 → o run vira maratona (run mediano do modelo
  ~23 min; meta 45–240 s); só o cansaço 1,7^n segura.
- **Progressão some depois de ~3 h**: os 6 mundos fecham em 2,9–3,3 h (expert ≈ casual: habilidade pesa pouco);
  depois só a Frota (8M) com paredes de até ~5 h.
- **Ordem da Estrada x necessidade**: "Dá pra chegar?" só no 3º mundo (o aperto de gás é no começo); Turbo no mundo
  de gravidade mais leve (Nuvens 1,15); Bolhas sem ajudas; mundos difíceis pagam MENOS por metro (Jardim ×0,73).

## O que os jogos de referência fazem (pesquisa)
- **Escolha dominante mata a escolha** (balanceamento): opções baixo-risco/baixa-recompensa e alto/alto devem ter
  valor parecido; o "melhor" depende da situação.
- **Corrida curta × longa** (motoristas de app, Euro Truck): pagamento super-linear faz o motorista "escolher a dedo"
  as longas; bônus **fixo por viagem** (aditivo) devolve valor às curtas; ETS2 usa bônus de XP por tipo (+25% longa,
  +30% urgente), não por quilômetro elevado a potência.
- **Idle math** (Kongregate/Pecorella; AdCap): custo exponencial (r 1,07–1,15) contra ganho por nível pequeno e
  polinomial; os **saltos** vêm de marcos (×2/×3 a cada 25/50/100) e de conteúdo novo — cada nível perceptível,
  nenhum nível isolado vira ×3,5.
- **Variedade do loop**: Lunar Lander Beyond (Dotemu) = campanha de 30 missões em 5 luas/planetas (entregar carga,
  recuperar recursos, resgatar pilotos), pilotos com estresse/fadiga, 4 naves e ~12 melhorias; Jetpack Joyride =
  missões ativas (coletar, distância, quase-acerto, ficar no veículo) que sobem o "rank" e tela de recompensa a cada
  morte; roguelites liberam mecânicas uma a uma pela meta-progressão.
- **Ordem de liberação**: deixar o jogador **sentir o problema antes** de dar a ajuda que o resolve; gating por
  "chave" no momento da necessidade; desafio subindo junto com a habilidade (flow).

## Propostas (aguardando decisão do usuário — ver relatório)
1. Pagamento por distância com taxa fixa por entrega + parte ∝ d^~0,5 (valor por gás parecido); risco (plataforma)
   como prêmio separado e menor; bônus de sequência/perfeito por entrega.
2. Gás escasso de novo (tanque e eficiência com retorno decrescente ou alcance que cresce com o mundo) → 5–8
   entregas por run, run 2–4 min; cada nível +3–6% de renda e os saltos nos degraus de 10 (marco) e nos mundos.
3. Mundos em sequência com salto de pagamento e distância (planeta novo = ×3–10) e objetivos depois dos mundos.
4. Objetivos ativos (3 desafios por vez, estilo Jetpack Joyride) e eventos/variações no voo da Lua.
5. Reordenar a Estrada pela necessidade (gás no começo, Turbo nos mundos pesados, ajuda para Bolhas).

## Fontes
- https://joeldignam.substack.com/p/the-timeless-game-design-of-squad — escolhas sem estratégia dominante
- https://www.slideshare.net/slideshow/game-balancing-66908546/66908546 — risco/recompensa assimétrico equilibrado
- https://arxiv.org/pdf/1905.07544 — motoristas escolhem corridas longas; bônus aditivo valoriza as curtas
- https://steamcommunity.com/app/227300/discussions/0/144513524084823554 — ETS2: bônus por tipo de entrega (longa +25%, urgente +30%)
- https://www.slideshare.net/slideshow/quest-for-progress-gdc-europe-2016/65405507 — Pecorella (GDC 2016): matemática dos idle games
- https://www.nuuvem.com/bs-pt/item/lunar-lander-beyond — Lunar Lander Beyond: 30 missões, 5 mundos, carga/recursos/resgate, estresse dos pilotos
- https://en.wikipedia.org/wiki/Jetpack_Joyride — missões variadas que sobem o rank
- https://jboger.substack.com/p/the-emotions-of-rogue-lites — mecânicas introduzidas uma a uma pela meta-progressão
- https://xinyichen.itch.io/learning-the-hard-way — sentir o problema antes de ganhar a habilidade que o resolve
