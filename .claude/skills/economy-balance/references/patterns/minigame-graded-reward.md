# Minijogo com recompensa graduada (crédito parcial + bônus por estrela)

**Usado em:** `planets[].mission_bonus` (lista por estrela), `planets[].partial_frac_model`, `planets[].takeoff_twr`,
`EconMath.fail_pay` (v18, 2026-10-08).

## Problema
- Regra tudo-ou-nada (errou 1 de 5 = errou 5): depois do 1º erro o resto do minijogo vale zero → o jogador para.
- Estrela que paga mais sem exigir nada (Simples ★3 ×1,3 sem queijinho) = escolha dominante, estrela sem sentido.
- Minijogo sem nenhum efeito no pagamento (quique dos Cogumelos) = promessa quebrada.

## Padrão
- **Gradiente de meta** (Kivetz, Urminsky & Zheng 2006, JMR 43): o esforço sobe perto da meta e cai quando ela fica
  inalcançável → pagar pela parte cumprida mantém o esforço depois do erro.
- **Avaliação graduada** (Angry Birds/Candy Crush: 1–3 estrelas por desempenho) em vez de passa/falha.
- **Coletável opcional perto do risco** (Subway Surfers: moedas tentam o jogador perto do perigo; nunca obrigatórias
  para progredir) → o bônus vem dos itens, não da estrela escolhida.
- Fórmula: `fail_pay = fail_mult + (1 − fail_mult) × parte` (parte 0 = o fail_mult antigo; 1 = cumpriu).
- Estrela = mais bônus possível (lista por estrela), não multiplicador grátis.
- Folga de empuxo por mundo (`takeoff_twr`): só oferecer a estrela que a nave controla (vento/carga no cabo).

## Números finais (v18) e efeito medido
- Lua [0,15, 0,40, 0,75]: valor/gás da ★3 −4/−4/−5% (engaged/expert/casual) para quem pega `skill` da trilha;
  quem pega tudo ganha mais que na v17. [0,15, 0,35, 0,6] deixava o casual ~7% mais lento (descartado).
- Mundos abrem ±10% da v17. Jardim: Pesada só a partir do Motor ~10 (thrust 10 > 4,9 × 1,3 × 1,3).

## Fontes
- https://business.columbia.edu/sites/default/files-efs/pubfiles/1200/goalgradient.pdf
- https://gamificationnation.com/blog/completes-3-star-level/
- https://mechanicsofmagic.com/2025/04/08/short-exercise-mda-8-kinds-of-fun-29/
