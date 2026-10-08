# Biblioteca de padrões (godot-dev)

Um arquivo por solução/armadilha aprendida na prática (`<slug>.md`, modelo em `_TEMPLATE.md`).
Antes de implementar algo, procure aqui; ao resolver algo não óbvio, registre.

| Slug | Tema | Resumo | Atualizado |
|---|---|---|---|
| verification-loop | Ferramentas | check/test/run/capture validados no Godot 4.7.2 (erros detectados, frames legíveis) | 2026-09-30 |
| flight-prototype | Voo | autopiloto precisa decolar na vertical (pousado não gira); pouso lento exige recovery_as_collision; demo só chega ao fim com --fixed-fps | 2026-09-30 |
| visual-preview-scenes | Verificação | telas tardias (final etc.) verificadas com cena de prévia mínima em tests/visual/, não com capturas enormes | 2026-09-30 |
| terrain-art | Visual | faixa de terreno cisalhada (Polygon2D+uv por face), pedregulhos em _draw, fundo em CanvasLayer com region+repeat | 2026-10-01 |
| controls-ux | Input/UX | nave travada até escolher entrega: aviso piscando, clique e numérico; foco do jogo embutido no editor 4.7; teste de controles com eventos reais | 2026-10-01 |
| rope-tow | Física | carga pendurada por cabo (Thrust): restrição de comprimento máximo + impulso dividido pelas massas, sem RigidBody | 2026-10-05 |
| camera-swap | Câmera | trocar de cena com Camera2D + interpolação de física: a câmera nova só processa se já for a atual → `make_current()` explícito; testar pelo canvas_transform | 2026-10-06 |
| onboarding-ftue | UX/fluxo | primeiros minutos: aprendiz (batida repete o salto), 1º salto já aceito, Coach sem texto, revelação por etapas, funil session.csv | 2026-10-08 |
