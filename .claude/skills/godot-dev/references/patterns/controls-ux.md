# Controles e "não consigo controlar a nave"

- **Tema**: Input/UX · **Atualizado**: 2026-10-01
- **Arquivos**: `game/run/offer_panel.gd`, `tests/integration/controls_test.*`

## O que aconteceu
O usuário relatou "não consigo controlar a nave no Godot". O código estava certo (teste com teclas reais passou):
a nave fica travada no chão até **escolher uma entrega** (1–8), e nada avisava isso; e o teclado numérico não era aceito.

## Solução
- Escolher entrega por **teclas 1–9 (fileira de cima ou numérico) ou clique do mouse** (linha com destaque ao passar).
- Linha fixa de instrução no painel + **aviso piscando** se o jogador aperta W/A/D antes de escolher.
- `tests/integration/controls_test.tscn`: abre o jogo normal, injeta eventos reais (`Input.parse_input_event`):
  W cedo → não decola e o aviso pisca → clique (ou `-- --numpad`) → W decola → A gira. Roda no `gdtool test`.

## Armadilha do Godot 4.7 (editor)
Ao dar Play no editor, o jogo roda **embutido na aba "Game"**; o teclado só chega ao jogo depois de **clicar dentro
da tela do jogo** (ou desligar "Embed Game" / rodar em janela própria). Sempre lembrar o usuário disso.
