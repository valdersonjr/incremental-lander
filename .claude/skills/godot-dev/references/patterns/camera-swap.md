# Trocar a Flight (Camera2D) com a interpolação de física ligada

**Sintoma (2026-10-06):** no 1º voo de um jogo novo (menu → cartão vazio → voo direto, sem hangar) a nave subia e a
tela ficava parada; um Esc (pausar/despausar) consertava.

**Causa:** `Main._clear_run` faz `queue_free` na Flight do fundo do menu e adiciona a nova no mesmo quadro. A Camera2D
nova entra na árvore com a antiga ainda como câmera atual. Com `physics/common/physics_interpolation=true`, a Camera2D
só liga o próprio processamento interno se já for a atual quando isso é avaliado (`_update_process_callback`). A antiga sai e a nova
vira a atual, mas o processamento continua desligado, então o canvas não anda. Pausar/despausar reavalia e liga.

**Solução:** `camera.make_current()` explícito ao posicionar a nave (`Flight._place_on_start_pad`).

**Verificação:** medir `get_viewport().canvas_transform.origin` (o que aparece na tela). `camera.global_position` e
`get_screen_center_position()` andam normalmente mesmo com o bug, por isso não servem. Teste:
`tests/integration/camera_follow.tscn` (falha sem a correção).
