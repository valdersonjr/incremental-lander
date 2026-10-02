# UI (640×360, pixel art, incremental)

Fontes: docs Godot (Using fonts, ResourceImporterImageFont, Themes, Control), design de incrementais
(economy-balance: mostrar alcance, "comprar máx.", próxima meta).

## Base
- Resolução 640×360, `stretch mode viewport` + escala inteira (project.godot): a UI é desenhada em pixels
  reais da arte — tamanhos em múltiplos de 1 px, sem escalas fracionárias.
- `Control` + containers (`VBoxContainer`, `GridContainer`, `MarginContainer`); um **Theme** único
  (`assets/ui/theme.tres`) com fonte, cores (Resurrect 64) e estilos (StyleBoxTexture/Flat).
- **Fonte pixel** (feita): proporcional com acentos, `assets/ui/font.fnt` (BMFont, importador `font_data_bmfont`),
  tamanho 11 (1x) ou 22 (2x; `fixed_size_scale_mode = INTEGER_ONLY`). **Nunca** `font_size` 10/12 em override (escala
  fracionária borra) — use as variações do tema.
- **Tema por mundo**: `UiKit.theme_for(planeta)` (scripts/ui/ui_kit.gd) monta o Theme a partir de `assets/ui/` (contrato
  `ui_kit.json`): painéis 9-slice com miolo em TILE, botões 4 estados + `PrimaryButton`, barras (`GasBar`, `WarnBar`,
  `DangerBar`, `XpBar`), rótulos (`TitleLabel`, `SectionLabel`, `DimLabel`, `ValueLabel`, `MoneyLabel`, `DustLabel`,
  `BadLabel`, `GoodLabel`). A `main` aplica o tema do planeta em HUD/ofertas/resumo/final; o hangar troca no `refresh()`.
  Tema não atravessa CanvasLayer: aplicar em cada tela raiz. Ícones: `UiKit.icon(nome)`, `UiKit.icon_label(...)`.
- Cores com significado são fixas (dinheiro dourado, perigo vermelho, gás ciano); só o destaque muda por mundo.

## Padrões de interação (auditoria de UX 2026-10-02 — valem para toda tela nova)
- **Foco de teclado sempre visível**: o tema desenha moldura de 1 px fora do botão (cor `title` do mundo; branca no
  `PrimaryButton`). Toda tela navegável por setas/Tab/Enter dá `grab_focus()` no botão principal ao abrir.
- **Telas refeitas no `refresh()`** (hangar): botões levam `set_meta("focus_key", ...)` e o foco volta ao mesmo botão
  se a última entrada foi teclado; se foi mouse, volta ao botão principal (Enter continua = ação principal).
- **Destrutivo** (apagar save, recomeçar): `DangerButton` (texto coral), 2 cliques com texto "…? Clique de novo",
  **Esc cancela** a confirmação antes de qualquer outra coisa. Botão desabilitado não fica com foco.
- **Modais** (resumo, final): raiz `Control` em tela cheia → `ColorRect` escurecendo (ink, alfa `UiKit.DIM_ALPHA`)
  + `CenterContainer` + painel. Estatísticas em `UiKit.stat_row(ícone, nome, valor, variação)`.
- **Feedback**: compra = som + `UiKit.pulse` na linha (meta `row_key`) e no saldo; custo inacessível mostra
  "faltam X" no tooltip; nomes cortados (`clip_text`) têm tooltip com o texto inteiro.
- **Opções**: volume só por `UiKit.volume_row(bus)` (- / barra / + / %), igual no título e no hangar.
- **Texto do jogador, não id**: motivos (`vertical_rapido` …) passam por `UiKit.crash_text`; botão diz para onde
  leva ("IR AO HANGAR", não "novo run" se abre o hangar). Dica de teclas dentro de painel, nunca solta sobre o cenário.
- Tooltip e barra de rolagem usam o tema (`TooltipPanel`/`TooltipLabel`, `VScrollBar`) — nada com a cara padrão do Godot.
- **Pausa** (2ª auditoria, 2026-10-02): Esc no voo ou janela sem foco abrem `PauseMenu` (`game/pause/`, modal,
  `PROCESS_MODE_ALWAYS`, `SceneTree.paused`): volumes + lista de controles + CONTINUAR (Esc/Enter). Nunca no demo nem na
  gravação de quadros. O autoload `Sound` roda com o jogo pausado (cliques do menu). Pausa não mexe no run.
- **Rodapé do HUD** (dica de teclas / resultado) num `SlimPanel` (painel de 1 linha) no `Footer`, nunca solto no cenário.
- **Modais** bloqueiam o clique no que está atrás (`Dim` com mouse_filter STOP). Botão de modal que aparece no meio do
  voo ganha foco com atraso (`RunSummary.FOCUS_DELAY`): Espaço do propulsor não fecha a janela sem querer.
- Tabelas com **cabeçalho de colunas** (ofertas: distância / gás / pagamento). Stats do mesmo valor no mesmo formato em
  toda a tela (`Hangar._num`: 2 casas < 10, 1 casa até 1000 sem ",0" em inteiros, depois `EconMath.fmt`). "MÁX", não "MAX".
- Só caracteres que a fonte tem (sem "—", "²", setas): conferir `assets/ui/font.fnt` antes de usar símbolo novo.

## Hangar (layout aprovado 2026-10-02)
- Abas NAVE (padrão ao abrir) | MUNDOS | PRESTÍGIO, trocadas com Q/E ou clique; aba atual = `PrimaryButton`,
  outra aba com algo comprável = texto dourado + "!". A meta (Expedição) fica fixa no cabeçalho, fora das abas.
- Tudo em **tabelas com colunas de largura fixa** (`COL_*`) e ação à direita; botões largos de linha inteira só para
  ações únicas. Item atual (mundo) em verde "VOCÊ ESTÁ AQUI", nunca cinza (cinza = indisponível).
- Um só botão principal por tela (DECOLAR); ações destrutivas (prestígio, novo jogo) com 2 cliques e sem destaque cheio;
  opções/novo jogo fora da tela de compras (Esc).
- Feedback do voo (entrega/batida) em aviso central grande **com painel**, entre o painel de stats e o de ofertas; o
  rodapé volta à dica de controles na decolagem seguinte (não fica com o resultado velho).

## Números
Sempre `EconMath.fmt(valor)` (K, M, B, T, Qa… aa) — nunca `str(float)` na tela. Tempo: formato curto (2m05s).

## Telas de incremental (padrões)
- **Hangar**: lista de upgrades (nome, nível, efeito atual → próximo, custo), botão comprar e **comprar máx.**
  (`EconMath.max_affordable`), destaque do que é acessível, progresso para o próximo **marco** (25 níveis).
- **Meta visível**: barra para o próximo planeta/etapa da Expedição (barra **segmentada** — gradiente de meta).
- **Alcance estimado** com o gás atual (usa `EconMath.estimated_hop_dv`) — ensina o valor de tanque/eficiência.
- **Resumo do run**: entregas, qualidade média, créditos (e minério), melhor salto.
- **Prestígio**: ganho previsto de Poeira Estelar antes de confirmar; loja com o que muda no recomeço.
- Feedback de compra imediato (som `sound-design` + animação curta); nada de tela que exige esperar.

## HUD de voo (legível em 640×360)
Gás (barra + número), velocidade vertical/horizontal com cor de segurança (verde/amarelo/vermelho segundo as
tolerâncias de pouso), altitude, distância/direção da plataforma alvo, pagamento da entrega.
