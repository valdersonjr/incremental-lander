# Takes de trailer — Incremental Lander

Gravados em 2026-10-03 com o jogo real (Movie Maker do Godot, 60 fps, 640×360 ampliado ×3 sem filtro → **1920×1080**,
H.264 + áudio do jogo em AAC). Filtro CRT ligado (como o jogo abre). Arquivos em `trailer/takes/` (fora do git);
folha de quadros de cada take em `trailer/takes/sheets/`. Montagem bruta na ordem sugerida (90 s, só para mostrar o
ritmo): `trailer/montagem_sugerida.mp4`.

Regravar: `python3 tests/tools/trailer_capture.py --all -j 4` (~3 min; as janelas do jogo abrem lado a lado) ·
um take: `... trailer_capture.py t07_cristais_no_arco` · montagem: `python3 tests/tools/trailer_montage.py`.
O roteiro (argumentos, cortes) fica no fim de `tests/tools/trailer_capture.py`; quem "joga" é
`tests/visual/trailer_director.tscn` (escolhe as entregas, pilota pelo arco dos cristais, sincroniza os perigos).
Nenhuma regra do jogo foi alterada e o save real nunca é tocado.

## Ordem sugerida para o vídeo

| # | Parte | Arquivo | O que acontece | Dur. | Uso / corte |
|---|---|---|---|---|---|
| 1 | Abertura forte | `t01_abertura_lua_guerra.mp4` | Lua sem HUD: nave parada na plataforma sob a nave-mãe e a Terra, discos atacando as bases ao fundo; decola e faz o arco pegando cristais | 8,5 s | Primeiro plano do trailer. Os primeiros 1,5 s (nave parada + guerra) servem para título/logo por cima |
| 2 | Abertura (logo) | `t02_titulo_lua.mp4` | Menu inicial "INCREMENTAL LANDER — pouse, entregue, evolua" sobre a Lua em guerra | 5 s | Cartão de título logo após a abertura (ou só 2–3 s) |
| 3 | Exploração | `t03_silvania_voo.mp4` | Silvânia (floresta): salto sem HUD entre árvores gigantes com raios de sol, folhas da rajada passando, pouso numa plataforma estreita | 9,5 s | Revelação do 2º mundo; corte 1–6 s |
| 4 | Exploração | `t04_docelandia_voo.mp4` | Docelândia sem HUD: pirulitos, rosquinha no céu, gêiser de calda subindo ao lado da nave, pouso | 9 s | Revelação do 3º mundo; o gêiser aparece por volta de 2,5 s |
| 5 | Exploração | `t05_quarto_voo.mp4` | O Quarto sem HUD: nave minúscula num quarto gigante (estante, bola, robô de brinquedo), bloquinho caindo, pouso | 7,5 s | Revelação do mundo final; o efeito "a nave é minúscula" funciona bem |
| 6 | Gameplay principal | `t06_escolha_entrega.mp4` | Painel de ENTREGAS com distâncias, gás e multiplicadores ×1,5/×2,2; escolhe a plataforma apertada e decola | 6,5 s | Explica o "risco × recompensa"; os primeiros 2 s mostram a tabela |
| 7 | Gameplay principal | `t07_cristais_no_arco.mp4` | Lua com HUD: arco balístico pegando 3 cristais roxos (estouro, nota que sobe, "+12" flutuando) | 8 s | Mecânica central: o arco ideal |
| 8 | Gameplay principal | `t08_pouso_estreita_lua.mp4` | Frenagem e pouso suave na plataforma estreita: feixe do alvo, poeira, "ENTREGA! +934 · plataforma ×1,5 · cristais" | 6 s | Recompensa; cortar até ~5 s (no final o painel de ofertas volta) |
| 9 | Variedade | `t10_rajada_silvania.mp4` | Silvânia com HUD: a rajada lateral (folhas e traços) empurra a nave, que corrige e pousa | 8,5 s | Perigo nº 1 |
| 10 | Variedade | `t11_geiser_docelandia.mp4` | Docelândia: gêiser de calda irrompe do chão no caminho; pouso e "ENTREGA! +202K" | 8,5 s | Perigo nº 2; o gêiser aparece por volta de 2,4 s |
| 11 | Variedade | `t12_brinquedo_por_um_triz.mp4` | O Quarto: bloquinho de brinquedo despenca e passa raspando atrás da nave; pouso, "+1,98M" | 7 s | Perigo nº 3 (tensão); o bloco aparece por volta de 1,5–2,5 s |
| 12 | Variedade (progressão) | `t13_hangar_upgrades.mp4` | Hangar de Silvânia: compra motor, tanque, bocais, reputação, trem de pouso (números sobem, botões piscam) e abre a aba MUNDOS (Lua, Silvânia, Docelândia) | 6,5 s | Mostra o lado incremental; usar 3–4 s acelerado se precisar |
| 13 | Momento de impacto | `t14_batida_explosao.mp4` | Lua sem HUD: a nave desce rápido demais e explode ao lado da plataforma | 5,5 s | Explosão por volta de 3,9 s; bom para um corte seco no som |
| 14 | Momento de impacto | `t15_brinquedo_acerta.mp4` | O Quarto: o bloquinho acerta a nave em cheio → explosão, "BATEU! atingido por um brinquedo" | 4 s | Impacto + humor; segue logo após o t14 |
| 15 | Clímax | `t09_combo_sequencia.mp4` | Silvânia: 3º pouso seguido numa plataforma apertada, estalo de combo, "ENTREGA! plataforma ×2,2 · combo ×1,2 · cristais" | 9 s | Clímax de habilidade (pousos encadeados) |
| 16 | Clímax | `t16_quarto_apertada_combo.mp4` | O Quarto: 2º salto seguido, decola, cruza o quarto e pousa na plataforma apertada ×2,2 com combo ×1,1: "+6,59M" | 9,5 s | O desafio mais difícil + números grandes |
| 17 | Clímax | `t17_docelandia_numeros.mp4` | Docelândia: arco com cristais e pouso em plataforma apertada com combo; o saldo pula de 146K para 404K e as ofertas chegam a 9,86M | 9,5 s | "Números que crescem" — fecha o clímax |
| 18 | Encerramento | `t18_pouso_calmo_lua.mp4` | Lua sem HUD: a nave desce devagar e pousa no feixe da plataforma; a guerra segue ao fundo | 7,5 s | Respiro antes do cartão final |
| 19 | Encerramento | `t19_titulo_docelandia.mp4` | Menu inicial com a cor de Docelândia | 5 s | Cartão final (logo + "Lista de desejos na Steam") |

## Observações do diretor
- **Melhores para thumbnail/GIF**: t04 (gêiser + pirulitos), t05 (quarto gigante), t01 (guerra na Lua).
- Takes com HUD terminam com o painel de ofertas voltando depois do pouso: corte cerca de 1,5 s depois do "ENTREGA!".
- O áudio de cada take é o som real do jogo (propulsor, cristais, pouso, explosão, combo). A trilha do trailer vai por cima.
- A nave ocupa poucos pixels (estilo do jogo, 640×360): no 1080p ela fica nítida, mas evite reduzir o vídeo abaixo de 720p.
