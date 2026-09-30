# Física do lander, pouso e câmera

## Decisão: `CharacterBody2D` + integração própria (não `RigidBody2D`)
- `RigidBody2D` só aceita forças; o solver decide o resto (quiques, atrito, rotação por contato) — ótimo
  para simulação livre, ruim para: (a) contabilizar gás **exatamente** como o modelo econômico
  (`gás = Δv / eficiência`), (b) regras de pouso determinísticas, (c) repetir o mesmo voo em teste/demo.
- `CharacterBody2D` com velocidade própria integrada em `_physics_process` e `move_and_collide()`
  (herdado de `PhysicsBody2D`: `move_and_collide(motion, test_only, safe_margin, recovery_as_collision)
  -> KinematicCollision2D`) dá controle total e determinismo. É o padrão escolhido.
- Tick de física fixo (60 Hz, padrão). Movimento e gás só em `_physics_process`.

## Integração (por tick `dt`)
```
aceleração = gravidade(planeta) + direção_do_nariz * thrust * acelerador - arrasto(planeta) * v
v += aceleração * dt
gás -= (thrust * acelerador * dt) / efficiency        # Δv do motor / eficiência  (= modelo "arcade")
colisão = move_and_collide(v * dt)
```
- `thrust` (m/s²), `tank` (gás), `efficiency` (m/s de Δv por gás) vêm de `EconMath.ship_stats()`; gravidade,
  arrasto e distâncias vêm do planeta na spec. Converter m ↔ px com `WorldConfig.PX_PER_M` (`data/world.json`).
- Rotação: velocidade angular fixa por input (sem inércia no início; decidir no protótipo e registrar).
- Sem gás: propulsor desliga, o lander cai (run termina ao pousar/bater).
- Decolagem exige `thrust > gravidade` — o modelo econômico usa a mesma regra (a > 1,05 g).

## Pouso, batida e qualidade `q` (0..1)
Ao colidir com o terreno (`KinematicCollision2D`: normal, posição, collider):
- **Batida** se: velocidade vertical > `max_vy`, horizontal > `max_vx`, inclinação > `max_tilt`, ou fora
  de uma plataforma (terreno comum). Tolerâncias em `data/world.json`; `gear` (trem de pouso) as amplia.
  Referência histórica: Atari Lunar Lander (1979) batia com vertical > 15 ou horizontal > 31 (unidades do jogo).
- **Pouso** na plataforma: `q` combina velocidade vertical, horizontal, inclinação e distância ao centro,
  cada termo normalizado 0..1 (1 = perfeito). Função pura e testada (`LandingRules.quality()`), porque ela
  define o pagamento (`EconMath.contract_pay(..., q)`) e a telemetria que calibra `skill` na economia.
- Após pousar: travar o lander, emitir `landed(pad_id, quality)`; após bater: `crashed(reason)`.

## Câmera
- `Camera2D` seguindo o lander com `process_callback` = Physics; limites verticais do terreno.
- Pixel art + movimento suave: ativar **physics interpolation 2D** (Project Settings → Physics → Common) e
  manter "Snap 2D Transforms/Vertices to Pixel" (já no project.godot). Ao teleportar (novo run), chamar
  `reset_physics_interpolation()`. Suavização da câmera baixa; jitter → ver fórum/`PixelPerfectSmoother`.
- Saltos longos (até dezenas de km no modelo): câmera acompanha; zoom-out opcional só se ainda legível
  em 640×360 — testar com `capture`.

## Escala do mundo (decidir na Fase 1.5 e registrar em DECISIONS)
- O modelo econômico mede em "metros do modelo". O jogo escolhe `PX_PER_M` e o fator de tempo para que um
  salto típico cruze algumas telas e dure segundos, não minutos. Depois, a telemetria (Fase 10) recalibra o
  modelo (`economy-balance` → `calibrate()`), não o contrário.

## Modo demo (verificação automática)
Com `--demo` nos args do usuário, um piloto simples controla o lander (ex.: sobe, inclina para a plataforma,
freia) — permite `gdtool.py capture ... -- --demo` e testes de cena sem teclado.
