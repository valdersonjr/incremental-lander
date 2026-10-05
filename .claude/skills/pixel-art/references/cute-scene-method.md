# Método APROVADO para cenas fofas (2026-10-04)

> Usuário, ao ver a Lua de queijo rodando no jogo: "agora a gente tá conversando.. melhorou PARA UM CARALHO".
> Este é o caminho que deu certo depois de 5 tentativas. **Toda cena/mundo novo segue esta receita.**
> Implementação de referência: `art/src/bg/moon_cute.py` (funções `scale2x`, `profile_from`, `shade_piece`,
> `piece`, `cloud`, `sky_color`, `sphere`, `smoke`, `bunny`, `base_dome`). Histórico do que falhou: `patterns/moon-cute.md`.

## 1. O que NÃO funcionou (não repetir)
| Tentativa | Problema |
|---|---|
| Traço fofo + noite cinza/escura | "tudo muito sério" — fofura precisa de **cor clara/pastel** |
| Lua realista (montanhas facetadas, crateras de verdade) | o mundo não precisa ser fiel à realidade; conto de fadas > realismo |
| Contorno `ink` em tudo | "livro de colorir" / desenho de criança |
| Formas geradas por fórmula (mesma forma repetida, anéis de luz, elementos espalhados por igual) | "sem forma", "mal desenhado" |
| Muitos elementos pequenos (poeira de estrelas, discos, nuvens) | sem foco; o fofo (coelhos) some |
| Céu em listras onduladas serrilhadas | parece papel rasgado |

## 2. A receita
1. **Clima de conto de fadas**: cores claras e pastel, céu de pôr do sol/algodão-doce, coisas "impossíveis" e fofas
   (Lua de queijo com furinhos, coelhinhos da Lua, Terra dormindo de bochecha rosada, alienzinho de olhão).
2. **Kit de peças desenhadas** (não a cena por fórmula): cada morro/nuvem é uma peça com **silhueta definida à mão
   por pontos de controle** `(x, altura)` em **meia resolução**, interpolada por cosseno (`profile_from`). Morros
   **largos e redondos** (x dos pontos ×1,7 — estreitos viram picos pontudos, o oposto de fofo).
3. **Sombreamento cel que acompanha a silhueta** (`shade_piece`): distância até a borda na direção da luz
   (cima-esquerda) → brilho 1 px + faixa clara; borda oposta 1 px de sombra; oclusão de 2 linhas na base.
4. **Contorno**: cenário = tom escuro da própria rampa (`inside=True`); personagens/veículos/objetos = `ink`.
   Fundo distante **sem** contorno.
5. **Ampliar com Scale2x/EPX** (`scale2x`): peça em meia resolução → 2x com bordas arredondadas, **sem cores novas**
   (continua na paleta). Nunca usar upscalers de IA (borram e saem da paleta).
6. **Composição**: poucos elementos e grandes (2 coelhos ~15x18, 3 bases ~44x32, 2–3 nuvens, ~5 brilhos);
   personagens/bases apoiados SÓ na fileira da frente (senão flutuam).
7. **Hierarquia de valor**: céu degradê → morros de trás quase da cor do horizonte (sem contorno, 2 tons) →
   morros da frente saturados com contorno colorido → chão e personagens mais fortes.
8. **Céu** = degradê de ~6 tons com transição bayer **reta** de 16 px; brilhos de 4 pontas sem contorno.
9. **Objetos com volume** via `sphere()` (elipse com normal de bola): nave-mãe, bases, Terra, coelhos.
10. Fumaça = pufes grandes e sobrepostos (uma nuvem só), não "colar de contas".

## 2b. Construção de fundo (pesquisa 2026-10-04: Slynyrd Pixelblog 62, sprite-ai backgrounds)
- **Planeje os planos por valor antes de desenhar**: escada clara → escura do horizonte para a frente
  (dia/pôr do sol: o distante clareia e puxa para a cor do céu; o próximo é mais saturado e contrastado).
  Lua: horizonte creme → cordilheira distante pêssego (camada `far`) → morros de trás rosa → morros da frente
  amora escuros → planície ameixa → chão de queijo claro.
- **Teste em preto e branco** (captura do jogo + `ImageOps.grayscale`): se dois planos têm o mesmo cinza, eles se
  fundem; se o personagem some, corrija valor (não matiz). Personagens/objetos claros sobre plano escuro.
- **Névoa clara** em faixa na base de cada plano distante (liga com o plano de trás).
- **Escala da textura por plano**: covinhas/pedrinhas só no plano da frente; distantes lisos (só massa e silhueta).
- Fundo apagado e com poucas cores; contraste máximo reservado para o que é jogável.
- Fontes: https://www.slynyrd.com/blog/2026/5/27/pixelblog-62-landscape-backgrounds ·
  https://www.sprite-ai.art/blog/pixel-art-backgrounds

## 2c. Composição: o que ter, quanto e onde (pesquisa 2026-10-04: MAGES, Wayline, Clip Studio)
- **1 foco principal + 1 secundário + pequenos**: Lua = Terra grande na linha dos terços (direita-alto) com o
  planetinha de companheiro; nave-mãe secundária no alto. Nada grande colado nos painéis do HUD (cantos de cima).
- **Agrupar em vez de espalhar por igual**: props formam um grupo (vilinha de 3 cúpulas de tamanhos diferentes) e
  um elemento sozinho faz contraste (base atingida com fumaça = destaque vertical).
- **Números ímpares** (3 coelhos, 3 brilhos, grupo de 3 nuvens + 1 solta) e **tamanhos variados**.
- **Sem tangentes**: nada exatamente no pico do morro nem encostado em outro elemento; usar os "ombros".
- **Todo objeto tem um porquê no lugar onde está** (usuário, 2026-10-04: "escada na montanha nada a ver"): escada só
  onde leva a algo (desce num poço), varal/bandeirinha preso nas duas pontas, balão amarrado em algo, nada
  flutuando sem motivo. Antes de posicionar, pergunte "quem pôs isso aqui e para quê?".
- **Espaço negativo**: deixar uma região calma (Lua: direita) — o olho descansa e o jogável aparece.
- Lembrar que o jogo desloca as camadas (parallax): conferir a composição na captura do jogo, não só na prévia.
- Fontes: https://mages.edu.sg/blog/effective-composition-in-concept-art-environments/ ·
  https://wayline.io/blog/less-is-more-why-negative-space-wins-in-game-design · https://tips.clip-studio.com/en-us/articles/1773

## 3. Como validar e mostrar (o que convenceu o usuário)
- Prévia parada engana: **exportar e ver NO JOGO**. Exportar (`--export`), rodar `gdtool.py check` (reimporta os
  PNG — sem isso a captura mostra a arte antiga!) e `gdtool.py capture res://game/main.tscn ... -- --demo`.
- Mostrar sempre numa **página HTML aberta automaticamente no Chrome** (`open -a "Google Chrome" <arquivo>`), com
  comparação antes/depois (tecla/hover para alternar) e zoom — o usuário não quer caçar pasta.
- Autoavaliação honesta quando pedida: listar problemas por gravidade antes de propor correção.
