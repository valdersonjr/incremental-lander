# Receitas de SFX e UI (pontos de partida — sempre adaptar e pesquisar)

Base: os 7 geradores clássicos do **sfxr/jsfxr** (Pickup/Coin, Laser/Shoot, Explosion, Power-Up,
Hit/Hurt, Jump, Blip/Select), que modelam som retro com poucos parâmetros:
onda (square/saw/sine/noise), envelope (attack, sustain, **punch**, decay), frequência
(inicial, **slide**, delta slide, corte mínimo), vibrato, **arpeggio** (salto de altura no meio),
**duty sweep**, repeat, phaser, LPF/HPF com sweep.
No soundkit: `pulse(f, dur, duty=curva)`, `sweep`, `arp`, `vibrato`, `punch`, `svf(cutoff=curva)`.
Fontes: pyfxr.readthedocs.io, sfxr (DrPetter), jsfxr.

## UI (kind="ui")
| Som | Receita | Notas |
|---|---|---|
| hover/select | `pulse` agudo (nota da escala ~1–1.6 kHz), 40–70 ms, `decay(d, d/3)` | muito frequente → 3 variações, suave |
| clique/confirmar | 2 camadas: tick (ruído HP 3k, 5–10 ms) + tom curto; ou `p_blip` | pitch ±5% no Godot |
| compra/moeda | `p_coin`: 2 notas subindo (4ª ou 5ª), 60 ms + 150–250 ms | "cha-ching" retro |
| erro/negado | 2 notas descendo (2ª menor ou trítono), pulso 12.5%, 150 ms | curto, grave-médio |
| notificação | `inst_bell` (FM) 1–2 notas da escala, cauda 0.4 s | raro → pode ter brilho |
| tick de contador | 20–30 ms, sine/triangle abafado, pitch sobe com o valor | idle: pode tocar muito |

## Gameplay (kind="sfx" / "impact" / "jingle" / "loop")
| Som | Camadas | Notas |
|---|---|---|
| **propulsor (loop)** | ronco `brown` LP 200–400 Hz + sopro `pink` com `svf` modulado por `lfo(random)` + crepitar `chip_noise` HP sutil + tremolo 15–25 Hz | `p_thruster_loop`. No Godot: volume/pitch/cutoff por potência. Fazer também "ignição" (start) e "corte" (stop) como one-shots |
| ignição | whoosh: ruído com LP subindo 200→3k em 0.2 s + thump sub | encadeia no loop |
| pouso suave | `p_landing`: thump sub 90→40 Hz + poeira pink LP curta + rangido FM leve | variações |
| pouso forte/crash | thump mais longo + metal (FM ratio não inteira 1.41/2.76) + detritos | kind="impact" |
| explosão | `p_explosion`: crack HP + corpo ruído com LP caindo 4k→120 + sub 110→35 + rumble brown + crackle | adensar com `drive` p/ alcançar LUFS |
| coleta de recurso | `p_coin` mais grave, ou arpejo de 3 notas rápidas | varia com raridade |
| upgrade comprado | `p_powerup`: arpejo ascendente na escala + vibrato na última nota | kind="jingle" |
| desbloqueio / marco | fanfarra curta: acorde arpejado + sino FM + eco | kind="jingle", ≤ 3 s |
| alarme (combustível baixo) | pulso 2 notas alternando (`arp`), 2–4 Hz, loop | irritante de propósito, mas curto |
| laser/tiro | `p_laser`: pulso com sweep descendente + duty sweep | |
| dano/hit | `p_hit`: serra descendo + chip_noise curto | |
| sonar/scan | seno com eco longo + leve vibrato | ok ter reverb |

## Truques
- **Pitch final na escala**: `snap()` em notas que "param" (fim de arpejo, notificação).
- **Punch**: multiplique o corpo por `punch(dur, .5)` para ataque mais presente sem volume extra.
- **Graves em alto-falante pequeno** (notebook/celular): sub puro some; adicione harmônico
  (drive leve ou triângulo 1 oitava acima) para o "peso" continuar audível.
- **Variações**: mude seed de ruído, ±1–2 semitons de nota base (na escala) e ±10% de duração.
