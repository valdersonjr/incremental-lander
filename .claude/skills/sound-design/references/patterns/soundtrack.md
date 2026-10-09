# Trilha: tema do gatinho (tela inicial), Mapa/NAVE e voo

- **Slug**: soundtrack
- **kind**: music (estéreo, −18 LUFS; bus Music −6 dB no jogo; abaixa −9 dB durante jingles)
- **Evento/frequência**: `title` no menu inicial e no hangar; `flight` durante o run. Crossfade de 1,2 s; a mesma faixa
  não reinicia ao voltar (`Sound.music`).
- **Assets** ← `audio/src/music/soundtrack.py --export [title flight layers]`: `assets/audio/music/title.wav`,
  `assets/audio/music/flight.wav`, camadas `assets/audio/music/layer_luna.wav`, `assets/audio/music/layer_cogumelos.wav`,
  `assets/audio/music/layer_bolhas.wav`, `assets/audio/music/layer_jardim.wav`, `assets/audio/music/layer_sorvete.wav`,
  `assets/audio/music/layer_nuvens.wav`
- **Tema do gatinho** (2026-10-09, "a tela inicial deveria ter uma música"): `assets/audio/music/theme.wav`, só na
  tela inicial. A faixa calma (`title`) tinha 83% da energia < 250 Hz e só pad + sino: no notebook (−22,4 LUFS acima de
  200 Hz, −28 efetivo com o bus) parecia não haver música. Tema: D maior, 92 BPM, 24 compassos A B A' (62,6 s);
  I–IV–vi–V; motivo de 2 compassos F#–A–B–A–F# / E–D–B (pergunta) repetido como resposta; B sobe até D6 e respira
  um compasso antes da volta. Baixo triângulo saltitante (tônica–quinta–oitava) + harmônico de pulso uma oitava acima
  com drive (o peso aparece no notebook: −18,8 LUFS acima de 200 Hz). Opções: **A caixinha de música** (sino FM +
  dobra de pulso −20, violãozinho de pulso dedilhado, bumbo/chocalho leves) — exportada; **B chiptune fofo** (pulso
  25% com vibrato + eco de sino uma oitava acima, "pom-pá" de pulso nos contratempos, bateria de chip) —
  `THEME_PICK` no script. **Escolhida: D ocarina/flauta** (usuário, "MUUUITO melhor"): seno 80% + triângulo 20%,
  vibrato 5 Hz/0,18 st entrando após 0,18 s, sopro de ruído rosa em banda (0,8–2,5× a nota) no ataque, ataque 40 ms,
  −6 dB, eco 0,22. **Andamento 68 BPM e só o bumbo bem baixo** (usuário, com a tela Noite de história: "tem que
  diminuir um pouco o ritmo"; comparou 92/76/68/60 com a cena no navegador). `theme(opt, bpm, drums)`. As outras opções do mesmo arranjo (C marimba, E piano elétrico FM, F harpa) ficam no script.
- **2026-10-09 (auditoria)**: título 16 → 32 compassos (~91 s, parte B Gmaj7–A7–F#m7–Bm7); voo 16 → 48 compassos
  (~115 s, 3 blocos sobre a mesma progressão: A / A' com melodia nova e chimbal ativo / A'' sem bumbo nos 4 primeiros,
  arpejo invertido e a melodia antiga no fim); **camada do mundo** = contramelodia esparsa (tempos 2 e 4, nota longa
  no 2º compasso) de 16 compassos (1/3 do voo, cabe 3× exato: 1.693.440 × 3 amostras) em instrumento próprio, mono,
  −24 LUFS, tocada junto por `AudioStreamSynchronized` (Lua sinos FM · Cogumelos marimba · Bolhas seno que borbulha
  · Jardim flautinha de pulso 12,5% · Sorvete celesta FM 7 uma oitava acima · Nuvens pad de triângulo). O tema
  "troca de roupa" por mundo (Kirby/Mario/Banjo-Kazooie).

## O que caracteriza o som (pesquisa)
- Jogo incremental = sessões longas: música calma, sem melodia gritante, BPM baixo; "loop, depois varie" (A A' B A'').
- Instrumentos melódicos suaves (sino/vibrafone-like) acalmam sem tirar o foco; camadas que entram e saem seguram a
  atenção sem fadiga.
- D lídio = espaço/maravilha (II maior E); D maior = menu/progresso.

## Música
- **title**: D maior, 84 BPM, 16 compassos (45,7 s). Pad Dmaj7–Bm7–Gmaj7–A(add9) (2 compassos cada) −7, baixo triângulo
  −8, sino FM com motivo de 8 compassos respondido (A A') + eco pingue-pongue de 3/4 de tempo −12, sem bateria;
  reverb 0,8 + LP 9k no master.
- **flight**: D lídio, 100 BPM, 16 compassos (38,4 s) = D D E E ×2 | Bm Bm A A | D D E E. Arpejo pulso 25% em colcheias com
  eco pingue-pongue −13, pad −11, baixo triângulo sincopado −6, bumbo nos tempos 1 e 3 −9, chimbal em contratempo −21;
  melodia de pulso 12,5% só nos compassos 13–16 (variação) −15.

## Feedback do usuário (o que mudou e por quê)
- 2026-10-09: tema na caixinha de música "parece ser bom (quase o que eu quero), mas ainda tá ruim… outro instrumento";
  6 timbres na página `audio/previews/theme_options.html` (troca mantendo o ponto da música) → ocarina venceu de longe.
  Lição: para escolher timbre, comparar no mesmo trecho lado a lado ajuda muito mais que tocar em sequência.
- 2026-10-03: aprovado no resumo do pacote de áudio.
- 2026-10-09: auditoria — voo de 38 s igual em todos os mundos cansava; pedido "conserte tudo".

## Erros / avisos resolvidos
- Passa-baixa depois de `render(loop=True)` criou clique na emenda (filtro começa do zero) → filtro dentro do `master_fx`.
- Aviso "energia muda 11 dB na emenda" no voo: é o tempo 1 (bumbo + baixo) começando o loop — musical, não defeito
  (salto de amostra 0,0005).

- Aviso de loudness das camadas (−24 vs alvo −18 da música): proposital — são camada, não faixa.
- Emendas 3–6 dB nas camadas/título: nota do tempo 1 começando a frase (musical).

## Fontes
- https://www.tunee.ai/music-generator/menu-music — música de menu: primeira impressão, loop sem emenda, deixar espaço para a UI
- https://www.audiogang.org/composing-signature-game-themes/ — o tema é a marca do jogo: motivo, gancho, paleta por estilo
- https://www.sonarworks.com/blog/learn/make-your-mix-sound-great-on-small-speakers — alto-falante pequeno: harmônicos no médio
- https://splice.com/blog/adaptive-music-video-games/ — camadas por local (Banjo-Kazooie), música por fase (Mario)
- https://blog.criware.com/index.php/2020/04/20/dynamic-music-with-adx2-part1-vertical-layering/ — stems sincronizados, camadas entram/saem
- https://payhip.com/b/BdMWQ — música de idle: suave, não intrusiva, para sessões longas
- https://wondera.ai/tools/x-default/ugc/silent-snowfall-idle-game-ambient — BPM baixo, sino/kalimba, camadas que alternam
- https://payhip.com/b/cFzDI — trilha de idle em camadas que se combinam/alternam (trilha adaptativa sem fadiga)

## Auditoria v2 (2026-10-09)
- title e flight: baixo = `_bass_inst` (o do tema: triângulo + harmônico de pulso) e −3 dB; voo com bumbo 140→55 Hz −10 dB; passa-alta 35 Hz no master. Grave < 120 Hz: title 68% → 50%, flight 72% → 52%; perda no notebook 4,4/5,8 → 3,3/4,0 dB. Tema da ocarina e camadas intactos. A camada toca num player gêmeo (não mais AudioStreamSynchronized). Ver `mix-system`.
