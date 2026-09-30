# Fundamentos de pixel art (ler SEMPRE antes de desenhar)

Regras acionáveis. Cada uma tem um "como aplicar com pixelart.py".

## 1. Silhueta primeiro
- O objeto precisa ser reconhecível **só pela silhueta, em 1x**. Detalhe não salva forma ruim.
- Exagere a característica principal (ex.: pernas abertas do lander, bocal do motor).
- Aplicar: passe 1 em uma única cor; abra a prévia e olhe o recorte 1x/2x à direita.

## 2. Clusters (aglomerados)
- Cluster = grupo de pixels da mesma cor formando uma forma. Clusters limpos = leitura fácil.
- **Ruído**: pixels soltos/órfãos sem função → o olho não consegue agrupar → imagem "suja".
- Clusters devem ter forma intencional e tamanho variado (grande/médio/pequeno), não pontinhos iguais.
- Evite clusters-chave encostando uns nos outros (vira massa confusa).
- Aplicar: `cv.clusters(...)` para textura; `cv.lint()` reporta órfãos (> 2% dos pixels = revisar).
  Órfãos aceitáveis: brilho especular, estrela, olho, faísca.

## 3. Linhas e jaggies
- Jaggies = degraus irregulares que quebram a curva/diagonal pretendida.
- Curvas boas têm **degraus progressivos**: 1-1-2-3-4 ou 4-3-2-1 (monotônicos). Evite 1-3-1-3.
- Diagonais limpas: razões 1:1, 1:2, 2:1, 1:3 (padrões repetíveis).
- **Pixel-perfect**: linhas de 1px sem "cotovelos" (L com pixel redundante no canto).
- Aplicar: `cv.line()` já é pixel-perfect; `cv.lint(outline_color=...)` acha cotovelos.

## 4. Anti-aliasing (AA)
- AA suaviza jaggies com cores intermediárias **de valor (luminosidade) entre** as duas áreas.
- Escolha a cor de AA pela luminosidade; puxe o matiz para uma das pontas (evita cor lamacenta).
- "Quanto maior o degrau, maior o AA": degraus longos recebem 2+ pixels de AA.
- **Não faça AA na borda externa** de sprites que andam sobre fundos variados (use AA interno).
- Em 16x16 geralmente AA vira ruído — use pouco ou nenhum.
- Fonte: pixelparmesan.com/anti-aliasing-fundamentals-for-pixel-artists

## 5. Banding e pillow shading (evitar)
- **Banding**: faixas de cores paralelas e de mesma largura seguindo o contorno → reforça a grade.
  Varie a largura das faixas.
- **Pillow shading**: sombra seguindo o contorno de todos os lados (luz "de frente") → forma chapada.
  Sombreie pela **forma e pela direção da luz**, não pelo contorno.

## 6. Luz, valor e rampas
- Uma direção de luz para o jogo inteiro (ver style-guide.md).
- Valor (claro/escuro) importa mais que matiz para leitura. Teste mental: a imagem funciona em cinza?
- Rampas com **hue shifting**: sombras vão para matizes frios/roxos, luzes para quentes/amarelos.
  Saturação máxima no meio da rampa; pontas menos saturadas.
- 3–4 tons por material bastam em 16/32px (sombra, base, luz, brilho).
- Aplicar: `shift(cor, -1/-2/+1)` anda na rampa já com hue shift embutido (ver palette.md).

## 7. Contorno (outline) e selout
- Contorno escuro externo melhora leitura sobre fundos variados (sprites interativos).
- **Selout** (selective outline): contorno interno que usa a própria cor do material escurecida no
  lado da sombra e clareada/omitida no lado da luz → sprite mais suave e com volume.
- Contorno de 1px, sem cotovelos, cantos arredondados (4-vizinhos) na maioria dos casos.
- Aplicar: `cv.selout(light_dir)` ANTES de `cv.outline("ink")`.

## 8. Dithering (pontilhado)
- Mistura duas cores em padrão para simular uma intermediária ou criar textura.
- Padrões: `checker` (50% uniforme), `bayer2/bayer4` (gradientes suaves, céu, água), `noise` (terra,
  rocha, sujeira orgânica), `hstripe/vstripe/diag` (madeira, tecido, movimento).
- Gradiente suave ≈ 5 estágios: A → 75/25 → 50/50 → 25/75 → B.
- **NÃO usar**: em sprites ≤16x16 (vira sujeira), entre cores de brilho muito diferente (tremula),
  em contornos, com 3+ cores ao mesmo tempo, em áreas enormes, e com cuidado em animação (pisca).
- Preferir clusters a dither para textura de materiais em sprites pequenos.
- Fonte: pixnote.net/en/learn/dithering

## 9. Leitura no jogo
- Elementos interativos (lander, pickups, perigos) têm **mais contraste e saturação** que o fundo.
- Fundos/parallax: menos contraste, cores mais frias e escuras, menos detalhe.
- Não coloque textura agitada ao lado de outra textura agitada.

## 10. Orçamento de cores
- Menos cores = mais coesão e decisões mais claras. Ver limites no style-guide.md.
- Reutilize as mesmas rampas entre assets → o jogo parece um todo.

Fontes gerais: slynyrd.com (Pixelblog), pixelparmesan.com, pixnote.net/en/learn, saint11.org/blog/pixel-art-tutorials
