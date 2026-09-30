# Fundamentos de economia incremental (ler SEMPRE)

## 1. A gangorra: custo exponencial × produção polinomial
- `custo(n) = base × r^n` (r típico **1.07–1.15**; AdCap 1.07; Cookie Clicker 1.15; upgrades de
  "stat" em jogos de run costumam ser mais íngremes, 1.15–1.30).
- `produção = base × quantidade × multiplicadores` — cresce linear/polinomialmente.
- Exponencial sempre alcança o polinômio → o jogador **desacelera**. Multiplicadores (marcos, novos
  planetas, prestígio) "empurram de volta" quando o custo ameaça travar. O jogo é esse vaivém.
- Compra em lote (fechada): `b × r^k × (r^n − 1)/(r − 1)`; máximo acessível:
  `floor(log_r(c(r−1)/(b r^k) + 1))` → `bulk_cost`, `max_affordable`.
- Fonte: Kongregate/Pecorella, "The Math of Idle Games" I–III (gamedeveloper.com).

## 2. Percepção (Lei de Weber)
- Humanos percebem **diferenças relativas**. +10 de gás é enorme no início e invisível depois.
- Por isso efeitos multiplicativos (×1.1/nível) e custos ×1.15/nível (Eric Guan) mantêm cada compra
  perceptível. Efeitos aditivos (motor +0.6 m/s²) são bons quando o stat tem teto físico natural
  (ex.: aceleração precisa só vencer a gravidade com folga).
- Números mostrados: sempre formatados (`fmt`), 3 dígitos significativos.

## 3. Ritmo (pacing) e paredes
- Início: compras a cada poucos segundos/minutos (o jogador aprende o loop). Meio: minutos. Fim: dezenas
  de minutos, **quebrados por eventos** (novo planeta, prestígio, marco).
- **Parede** = intervalo longo sem nada para comprar. Paredes intencionais são aceitáveis antes de um
  grande desbloqueio (sensação de conquista) — paredes acidentais matam a retenção.
- Engajamento decai: sessões ativas de 15–60 min no início → visitas espaçadas depois. Meta de 10–30 h
  significa várias sessões; cada sessão deve terminar com algo "a caminho".
- **Degraus**: renda/min deve subir em saltos perceptíveis (planeta novo = ×10 ou mais no pagamento).
- Hierarquia de metas: curto (próximo upgrade, 1–3 min), médio (próximo planeta, 1–4 h), longo
  (prestígio, objetivo final). Sempre ter as três visíveis.

## 4. Fontes e drenos (faucets & sinks)
- Toda moeda precisa de **fonte** (entregas, minério) e **dreno** (upgrades, desbloqueios, conversões).
- Fonte > dreno por muito tempo = inflação (dinheiro sem uso, compras irrelevantes);
  dreno > fonte = estagnação/frustração. Estoque(t) = estoque(t−1) + entrada − saída.
- Ferramenta clássica de modelagem: Machinations (fontes, drenos, conversores, portões) — aqui o
  `econ.py` cumpre esse papel com simulação de jogador.

## 5. Meta-progressão de runs (roguelite)
- Cada run deve valer algo mesmo que falhe (dinheiro ganho até a batida fica).
- Risco: **curva de dificuldade invertida** (o jogo fica mais fácil a cada upgrade) e "grind to win" no
  lugar de "learn to win" (GMTK). Contra-medidas aqui: planetas novos resetam a dificuldade física
  (gravidade/arrasto), e a habilidade de pilotagem continua multiplicando ganho (qualidade do pouso) e
  poupando gás (desperdício menor).
- Verificação no simulador: **expert deve progredir mais rápido que casual, e casual deve conseguir
  terminar**. Se casual ≥ expert → estratégia/prestígio está pesando mais que pilotar.

## 6. Retorno sobre investimento (ROI) e dominância
- Jogador racional compra o que dá mais renda por custo. O simulador faz isso olhando 1/2/4/8 níveis à
  frente (ganhos de alcance são em degraus: um nível pode não alcançar a próxima entrega).
- **Dominância**: um upgrade que sempre vence o ROI esvazia as escolhas. Métrica: share de níveis
  comprados (não de créditos gastos — compras do fim do jogo dominam em créditos).
- **Inútil**: nunca comprado → custo alto demais, efeito fraco, ou o modelo não captura o valor
  (ex.: trem de pouso reduz batidas; se batidas são raras, vale pouco).

## 7. Retorno decrescente sem teto duro
- `hyper`: `max × L/(L + k)` → rápido no início, satura em `max` (bom para stats de "segurança").
- Equação do foguete (modo `rocket`): tanque maior pesa → alcance cresce com log(massa) → retorno
  decrescente natural e físico.
- Soft cap: acima de X, ganhos pela metade (evitar quebras súbitas; preferir curvas suaves).

## 8. Números
- float64 vai até ~1.8e308 (15–16 dígitos de precisão). Jogo de 10–30 h com prestígio moderado fica
  bem abaixo — o simulador reporta o maior número (`number_class`).
- Formatação: sufixos K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc, depois letras aa, ab... (mais legível
  que nomes latinos), ou científica (1.23e45) como opção do jogador.
