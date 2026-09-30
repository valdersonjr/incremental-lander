---
name: godot-dev
description: OBRIGATÓRIA para escrever ou alterar QUALQUER código, cena ou configuração do projeto Godot do Incremental Lander — GDScript, arquivos .tscn/.tres, project.godot, input map, autoloads, física do lander, terreno em polígono, câmera, HUD/UI, telas (hangar, prestígio), save/load, telemetria, testes e build. Define a arquitetura (Main/World/GUI, sinais para cima e chamadas para baixo, event bus), o estilo GDScript (tipagem estática, ordem de código), os padrões de física e terreno, e um ciclo de verificação sem editor (checar scripts, testes headless, rodar cenas, capturar frames para revisão visual, consultar a API exata do Godot instalado). Use sempre que o usuário pedir para implementar, programar, criar cena, corrigir bug, integrar asset/economia ou avançar o ROADMAP — mesmo sem citar a skill.
---

# Godot Dev — construção do Incremental Lander (Godot 4.7)

Esta skill é o **padrão de construção do código**. Arte, som e números vêm das outras skills
(`pixel-art`, `sound-design`, `economy-balance`); aqui eles são **integrados**, nunca criados por fora.

## Regras invioláveis

1. **Consultar as skills antes de agir** (CLAUDE.md, Regra 0). Asset visual → `pixel-art`; som → `sound-design`;
   número de economia → `economy-balance` (via `data/economy.json` + `EconMath`). Sem números de economia no código.
2. **API verificada, não lembrada**: antes de usar uma classe/método que não está no código do projeto,
   consulte `gdtool.py api <Classe> [membro]` (API exata do Godot instalado). Docs online são para conceitos.
3. **Tipagem estática sempre** e estilo oficial (`references/gdscript-style.md`). Identificadores em inglês,
   comentários/docstrings em português.
4. **Verificar antes de dizer que funciona**: `check` → `test` → `run` → `capture` (e olhar o frame com Read).
   Nunca declarar pronto algo que não rodou.
5. **Cenas autocontidas**; comunicação: dados descem (pai chama filho), eventos sobem (filho emite sinal);
   entre ramos distantes, `Events` (event bus). (`references/architecture.md`)
6. **Tudo documentado para continuidade**: ao fim de cada item do ROADMAP → atualizar `docs/ARCHITECTURE.md`,
   `docs/ROADMAP.md`, `docs/HANDOFF.md` (e `docs/DECISIONS.md` se decidiu algo) → commit.
7. **Placeholders sem imagem**: antes da arte existir, desenhe com `_draw()`/`Polygon2D`/`ColorRect` usando
   cores da Resurrect 64 (`references/architecture.md` §Placeholders). Imagem nova = skill `pixel-art`.

## Ferramenta: `scripts/gdtool.py` (rodar da raiz do projeto)
```
G=.claude/skills/godot-dev/scripts/gdtool.py
python3 $G api CharacterBody2D            # métodos/props/sinais da versão instalada (4.7.2)
python3 $G api PhysicsBody2D move_and_collide
python3 $G check                          # reimporta + checa todos os .gd (paralelo) — erros com linha
python3 $G test                           # tests/unit (TestCase) + paridade da economia
python3 $G run res://game/main.tscn --frames 600 -- --demo     # roda sem janela, falha se houver ERROR
python3 $G capture res://game/main.tscn --frames 240 --every 40 -- --demo   # frames reais → folha PNG
```
`capture` abre uma janela por 1–3 s (Movie Maker, `--fixed-fps`): avise o usuário se ele estiver usando o Mac.
A folha de frames vai para `.godot/captures/<cena>_sheet.png` — **abra com Read e critique**.
`-- --demo` (e outros) chegam ao jogo por `OS.get_cmdline_user_args()`: cenas de gameplay devem ter um
**modo demo/autopiloto** para poderem ser verificadas sem teclado (`references/testing.md`).

## Fluxo obrigatório (por item do ROADMAP)

### Etapa 0 — Contexto
Ler `docs/HANDOFF.md`, o item em `docs/ROADMAP.md`, `docs/ARCHITECTURE.md` e o `docs/GDD.md` relevante.
`git status` limpo? Identificar outras skills envolvidas (ex.: pouso → `economy-balance` qualidade/pagamento).

### Etapa 1 — Padrões e pesquisa
1. Ler a referência do tema: `architecture.md`, `gdscript-style.md`, `lander-physics.md`, `terrain.md`,
   `ui.md`, `save-telemetry.md`, `testing.md`, `tscn-format.md`.
2. Procurar em `references/patterns/INDEX.md`.
3. **Tema novo ou incerto → pesquisar**: `WebSearch` (≥2 consultas: docs.godotengine.org "stable"/4.x,
   fórum Godot, GDQuest) + `gdtool.py api` para confirmar assinaturas na 4.7.2. Registrar o aprendido em
   `references/patterns/<slug>.md`.

### Etapa 2 — Plano (curto, no chat)
Arquivos a criar/alterar, árvore de nós da cena, sinais/métodos públicos (contratos), dados lidos da spec,
como será verificado (qual teste, qual cena, o que o frame capturado deve mostrar).

### Etapa 3 — Implementar
- Pastas e nomes conforme `architecture.md`; scripts com a ordem/estilo de `gdscript-style.md`.
- `.tscn` escritos como texto (`tscn-format.md`); preferir montar a árvore na cena e lógica no script.
- Constantes de mundo/jogo (escala px↔m, tolerâncias de pouso, input) em `data/world.json` (não economia).
- Lógica pura (cálculos) em funções/estáticos testáveis, separada dos nós.

### Etapa 4 — Verificar (loop até passar)
1. `gdtool.py check` — zero erros.
2. `gdtool.py test` — escrever/atualizar testes da lógica nova (`tests/unit/test_*.gd`).
3. `gdtool.py run <cena> --frames N [-- --demo]` — zero `ERROR`/`SCRIPT ERROR`; revisar warnings.
4. `gdtool.py capture ...` — abrir a folha com Read: a cena mostra o esperado? (posição, escala, HUD legível
   em 640×360, pixel nítido). Descrever o que viu.
5. Se a mudança afeta física/economia: conferir telemetria/valores contra o modelo (`economy-balance`).

### Etapa 5 — Documentar e commitar
- `docs/ARCHITECTURE.md`: cenas/autoloads/sinais/arquivos novos. `docs/ROADMAP.md`: `[x]` + data.
- `docs/HANDOFF.md`: estado, próximo passo, pendências. `docs/DECISIONS.md`: decisões novas.
- `references/patterns/`: o que aprendeu (armadilhas, soluções). Commit (mensagem em português, com a
  linha de coautoria definida pela sessão).

## Referências
| Arquivo | Conteúdo |
|---|---|
| `references/architecture.md` | pastas, árvore Main/World/GUI, autoloads, sinais, event bus, injeção de dependência, placeholders |
| `references/gdscript-style.md` | ordem de código, nomes, tipagem, comentários, warnings |
| `references/lander-physics.md` | física do lander (CharacterBody2D + integração própria), gás = Δv/eficiência, pouso e qualidade q, câmera |
| `references/terrain.md` | terreno em polígono gerado por seed, plataformas, colisão, textura, chunks |
| `references/ui.md` | UI 640×360, tema, fonte pixel (via pixel-art), números (`EconMath.fmt`), telas de incremental |
| `references/save-telemetry.md` | save JSON versionado + migração; telemetria CSV para calibrar a economia |
| `references/testing.md` | TestCase/run_tests, testes de cena, modo demo, captura de frames, paridade |
| `references/tscn-format.md` | como escrever .tscn/.tres à mão (formato 4.x) |
