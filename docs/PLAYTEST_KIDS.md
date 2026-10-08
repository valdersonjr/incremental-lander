# Teste com crianças — primeiros 10 minutos

Roteiro curto para ver o começo do jogo pelos olhos de quem nunca jogou (auditoria dos primeiros minutos, B1;
relatório https://claude.ai/artifact/Eme3BchGnN7iMng1rGbNSg). Base: Budge Studios (narração sozinha não guiou as
crianças, pista visual sim) e Toca Boca (observar a criança jogando, sem explicar).

## Antes
- Build de depuração (a telemetria de sessão só grava nele): abra o projeto no editor e rode, ou exporte em debug.
- Um **jogo novo** num espaço vazio (Jogar → "+ Novo jogo").
- Som ligado, tela cheia (F11). Um adulto senta ao lado só para observar e anotar.

## Durante (10 minutos, sem ajudar)
- A única frase permitida: "Pode jogar do jeito que quiser." Se a criança pedir ajuda, responda "O que você acha que
  faz?" e anote o momento.
- Ajude de verdade só se ela travar por mais de 1 minuto. Anote o que você disse.
- Anote, com o minuto:

| Minuto | O que aconteceu | O que ela disse/fez (rosto, mãos, "como faz?") |
|---|---|---|
| | descobriu o motor (sozinha / com a teclinha / com ajuda) | |
| | descobriu como girar | |
| | 1º pouso na plataforma | |
| | 1ª batida e a reação ao "TENTE DE NOVO!" | |
| | entendeu a tela NAVE e comprou algo | |
| | tentou clicar em algo que não é clicável | |
| | quis parar (e por quê) | |

## Depois
- Pergunte só três coisas: "O que você mais gostou?", "O que foi difícil?", "Quer jogar de novo amanhã?".
- Rode o funil: `python3 .claude/skills/godot-dev/scripts/ftue.py` (tempos até decolar, 1ª entrega e 1ª compra;
  batidas e tentativas antes da 1ª entrega; onde a sessão terminou).
- Compare com as metas do GDD §8: decolar ≤ 10 s, 1ª entrega ≤ 60 s, 1ª compra ≤ 4 min, 10 min sem ajuda de adulto.
- Guarde as anotações e o `session.csv` em `balance/telemetry/` com a data e a idade da criança (sem nome).

## Meta
3 crianças diferentes (5 a 8 anos), cada uma jogando 10 minutos sem ajuda de adulto.
