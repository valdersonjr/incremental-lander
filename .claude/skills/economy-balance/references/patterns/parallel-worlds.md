# Mundos paralelos + bônus de recorde por mundo

**Mecânica**: mundos novos não substituem os antigos. Mesma nave, mesmas moedas; cada mundo tem física própria e
**recorde próprio**; bater o recorde de um mundo paga um bônus. Referências: Hill Climb Racing 2 (mapas de aventura
com "melhor distância" por mapa e sacos de moedas só ao passar a marca), Clash Royale (arenas = paradas da trilha
única), Cut the Rope / Angry Birds (estrelas abrem mundos). Contra-exemplo: AdVenture Capitalist (Lua/Marte com
economia própria, a Terra vira passado).

## Armadilhas medidas (v16, `balance/sims/2026-10-07-v16-worlds.py`)
- **Sem bônus, um mundo domina** (65–77% dos runs): o jogador simulado sempre joga o de maior renda.
- **Calibrar o pagamento com a nave da hora de abrir é errado**: com motor forte o peso da gravidade (0,707·g/a) cai e
  os mundos pesados passam a render mais que o planejado (Cogumelos dominou). Calibrar com a nave do FIM do jogo:
  o mundo abre um pouco abaixo da Lua (é desafio) e chega a ~1,15×.
- Bônus de 25% vira ~20% da renda (forte demais); 15% (1ª visita 40%) ≈ 15% da renda e já espalha o jogo.

## Regra adotada (v16)
- `planets[].road = true` + parada `world_<id>` na Estrada (24/44/66/88/110 estrelas, rascunho).
- `pay_mult` = 1,15 × renda da Lua ÷ renda do mundo com a nave {thrust 55, tank 40, efficiency 30}.
- `contracts.record_bonus` {frac .15, first_frac .4} sobre o dinheiro do run (só o recorde de dinheiro paga).
- MC 3×3 6 h: mundos abrem 0,5–0,7 / 1,1–1,3 / 1,7–2,0 / 2,2–2,5 / 2,7–3,0 h; runs por mundo: Lua 25–29%, cada
  outro 8–28%; bônus ≈ 15–16% da renda.

## Pendências
- Paredes do fim (35–68 min) = 1–2 runs longos (16–20 entregas; o modelo superestima o tempo por entrega).
- O modelo não tem o relevo nem as regras de voo de cada mundo (perigo só via planet.hazard dv/crash).
