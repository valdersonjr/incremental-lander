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
