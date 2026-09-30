# UI (640×360, pixel art, incremental)

Fontes: docs Godot (Using fonts, ResourceImporterImageFont, Themes, Control), design de incrementais
(economy-balance: mostrar alcance, "comprar máx.", próxima meta).

## Base
- Resolução 640×360, `stretch mode viewport` + escala inteira (project.godot): a UI é desenhada em pixels
  reais da arte — tamanhos em múltiplos de 1 px, sem escalas fracionárias.
- `Control` + containers (`VBoxContainer`, `GridContainer`, `MarginContainer`); um **Theme** único
  (`assets/ui/theme.tres`) com fonte, cores (Resurrect 64) e estilos (StyleBoxTexture/Flat).
- **Fonte pixel**: monoespaçada, desenhada pela skill `pixel-art` como folha de glifos PNG e importada como
  *Font Data (Monospace Image Font)*; filtro Nearest (já global). Até existir, usar a fonte padrão.

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
