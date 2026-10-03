# Alarme de gás baixo

- **Slug**: gas-alarm
- **kind**: loop (mono, −18 LUFS, 0,8 s)
- **Evento/frequência**: em voo, gás < 15% do tanque (mesma faixa da barra vermelha do HUD); para ao pousar, bater ou
  zerar o gás. Desligado no piloto automático.
- **Assets** ← `audio/src/sfx/progress_sfx.py --export`: `assets/audio/sfx/gas_alarm.wav`

## O que caracteriza o som (pesquisa)
- Alarme clássico = bipes curtos de 2 tons alternando, 2–4 Hz; urgência sobe com frequência e taxa.
- Bipe que repete sem parar irrita e faz o jogador jogar pior; jogos atuais **baixam o alarme depois de alguns
  segundos** (o jogador já sabe) mas mantêm audível.

## Receita final
- B5 (0,11 s) e F#5 (0,13 s, −1 dB) a 0,17 s de distância; pulso 25% + triângulo, LP 4k, ataque 6 ms; pausa até 0,8 s.
- No Godot (`Lander`): 0 dB nos primeiros 3 s, depois cai para −14 dB em 1,5 s.

## Erros / avisos resolvidos
- Aviso "energia muda na emenda": o loop termina em silêncio e começa no bipe — é o desenho do alarme (salto de
  amostra 0).

## Fontes
- https://innovations-report.com/?p=26097 — som com significado funciona melhor que bipe monótono
- https://tvtropes.org/pmwiki/pmwiki.php/Main/CriticalAnnoyance — alarme de vida baixa irrita; jogos modernos baixam o bipe após alguns segundos
- https://fis.tu-dresden.de/portal/en/publications/designing-effective-warning-sounds-psychoacoustical-considerations(5a33c041-e227-4641-820f-67bd0308c37f).html — urgência x incômodo: frequência, taxa de pulsos, forma de onda
