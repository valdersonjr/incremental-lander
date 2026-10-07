# Run "bata seu recorde" com cansaço do gás

**Mecânica**: o run não tem teto de entregas nem meta imposta; acaba só pelo gás (ou batida) e a meta é o recorde
pessoal (dinheiro do run, entregas, distância). Referências: Hill Climb Racing (combustível + distância recorde por
fase), Learn to Fly (tentativa curta → compra → recorde maior), Tiny Wings.

## Armadilha principal
Em incremental o **tanque cresce exponencialmente** com os níveis e a distância das entregas é limitada. Sem freio, o
número de entregas por run cresce sem limite (o galão de 30% ainda fecha o ciclo). Cansaço geométrico pequeno não
resolve: com custo c·k^n, o máximo é N ≈ log(1 + T(k−1)/c) / log k, e como T/c é exponencial no nível, **N cresce
linear no nível**. Medido (6 h, sim v15): k 1,06–1,22 → 20–40 entregas/run no fim; k 1,4 → ~15–21; 1,6 → 13–17;
1,7 → ~15; 1,8 → 6–11; 2,0 → 6–8 (e o 1º run com 1 entrega só).

## Regra adotada (v15)
- `contracts.run_fatigue` k = 1,7: gás do salto × k^n (n = entregas já feitas); galão devolve gás ÷ k^n (nunca cobre
  o custo para sempre).
- Efeito: entregas/run ~2 → ~15 ao longo do jogo; Gasolina e Eficiência passam a ser compradas (antes o teto de 6
  tornava tanque grande inútil — achado da v7.1).
- O intervalo entre compras ≈ duração de 1 run (compras só entre runs): manter o run curto em tempo real.

## Pendências
- O modelo superestima o tempo por entrega (~100 s): calibrar com telemetria antes de afinar k.
- Mostrar o cansaço ao jogador de forma clara (gás necessário do pedido já inclui o fator).
