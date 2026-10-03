# Ícone do jogo (app icon)

- **Slug**: app-icon
- **Tipo**: ícone de aplicativo (janela, dock/barra de tarefas, executável) — grade 32x32, exportado também x16 (512).
- **Assets** ← `art/src/ui/app_icon.py --export`: `assets/ui/icon.png`, `assets/ui/icon_512.png`
  (`project.godot > config/icon` e `export_presets.cfg > application/icon`, interpolação vizinho mais próximo).

## Pesquisa (regras)
- Silhueta primeiro: o ícone é lido de relance e em tamanho pequeno; teste em uma cor. Clareza > detalhe; corte o
  que vira borrão em 1x.
- Alto contraste entre o herói e o fundo; poucas cores.
- macOS: ícone "boxed" = tudo dentro de um retângulo arredondado, com margem transparente (o sistema põe a sombra);
  tela de 1024. Windows/Steam: vários tamanhos (16–256); 32x32 é base comum.
- Ampliar pixel art só por vizinho mais próximo (múltiplo inteiro), sem suavização.

## Receita final
- Retângulo arredondado 30x30 (raio 5, margem 1 px) com contorno `ink`.
- Céu em faixas `ink → shadow → navy → indigo` com transições em checker (linguagem da cena da Lua).
- Halo sólido `indigo` (elipse) atrás das pernas e da chama: as pernas `lilac_grey` sumiam no azul escuro.
- Nave = `lander_styles.b_body()` + `b_flame(1)` (plasma ligado), 2 px acima do contrato do sprite. 5 estrelas.
- 15 cores, lint limpo.

## Erros corrigidos na revisão
- Topo do casco encostando na borda (subia 3 px) → 2 px.
- Planeta no canto sobrepunha o casco e depois virou 3 px cortados pelo arredondamento → removido.
- Halo em bayer4 virou ruído (23 órfãos; dither em sprite pequeno) → forma sólida.

## Decisões do usuário
- 2026-10-03: aprovado.

## Fontes
- https://bugnet.io/blog/how-to-make-pixel-art-that-reads-clearly — silhueta em uma cor; clareza > detalhe em tamanho pequeno
- https://developer-rno.apple.com/design/human-interface-guidelines/foundations/app-icons — macOS: retângulo arredondado, perspectiva frontal, sombra do sistema
- https://bootcamp.uxdesign.cc/creating-app-icons-for-macos-11-and-up-1132ccd479bc — tela 1024, ícone 824 com raio ~185, margem transparente
- https://developer.valvesoftware.com/wiki/Icon_Creation — tamanhos de ícone (16/32 até 256) para desktop
