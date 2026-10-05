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

## 3. Como validar e mostrar (o que convenceu o usuário)
- Prévia parada engana: **exportar e ver NO JOGO**. Exportar (`--export`), rodar `gdtool.py check` (reimporta os
  PNG — sem isso a captura mostra a arte antiga!) e `gdtool.py capture res://game/main.tscn ... -- --demo`.
- Mostrar sempre numa **página HTML aberta automaticamente no Chrome** (`open -a "Google Chrome" <arquivo>`), com
  comparação antes/depois (tecla/hover para alternar) e zoom — o usuário não quer caçar pasta.
- Autoavaliação honesta quando pedida: listar problemas por gravidade antes de propor correção.
