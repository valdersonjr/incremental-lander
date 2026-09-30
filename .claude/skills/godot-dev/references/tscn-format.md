# Escrever .tscn / .tres à mão (Godot 4.x)

Claude não usa o editor: cenas são arquivos de texto. Depois de escrever, **sempre** `gdtool.py check`
(reimporta) e `gdtool.py run` na cena.

## Cena
```
[gd_scene format=3]

[ext_resource type="Script" path="res://game/flight/lander.gd" id="1_lander"]
[ext_resource type="PackedScene" path="res://game/terrain/terrain.tscn" id="2_terrain"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_body"]
size = Vector2(12, 14)

[node name="Flight" type="Node2D"]

[node name="Terrain" parent="." instance=ExtResource("2_terrain")]

[node name="Lander" type="CharacterBody2D" parent="."]
position = Vector2(80, 120)
script = ExtResource("1_lander")

[node name="Shape" type="CollisionShape2D" parent="Lander"]
shape = SubResource("RectangleShape2D_body")

[node name="Hud" type="CanvasLayer" parent="."]
unique_name_in_owner = true

[connection signal="landed" from="Lander" to="." method="_on_lander_landed"]
```
Regras:
- Primeiro `[node]` é a raiz (sem `parent`). Filhos: `parent="."` (raiz) ou caminho relativo à raiz
  (`parent="Lander"`, `parent="Hud/Panel"`).
- `ext_resource` antes de `sub_resource`, antes dos nós; ids são strings únicas no arquivo.
- `uid="uid://..."` é opcional ao escrever à mão — o Godot adiciona/gerencia; **commitar os `.uid`** que ele cria
  para scripts (Godot 4.4+).
- Valores: `Vector2(x, y)`, `Color(r, g, b, a)`, `Rect2(...)`, `PackedVector2Array(x1, y1, x2, y2, ...)`,
  strings com aspas duplas, `&"nome"` para StringName.
- Propriedades só quando diferentes do padrão. Conferir nomes com `gdtool.py api <Tipo>`.
- Preferir conectar sinais no código (`_ready`) quando a conexão depende de lógica; `[connection]` na cena
  para ligações fixas.

## Resource (.tres)
```
[gd_resource type="Theme" format=3]

[ext_resource type="FontFile" path="res://assets/ui/font.png" id="1_font"]

[resource]
default_font = ExtResource("1_font")
default_font_size = 8
```
