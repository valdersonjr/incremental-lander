// Estados de interface DENTRO da paleta Resurrect 64 (auditoria de UX 2026-10-08: modulate cinza e alfa criavam
// cores fora da paleta). Usado por UiKit.set_locked / UiKit.silhouette / UiKit.dim_rect.
//   mode 1 = bloqueado: o brilho de cada pixel vira um dos 4 tons da rampa fria (ink, #3e3546, lilac_grey, steel).
//   mode 2 = silhueta: todo pixel visivel vira uma cor so (fill).
//   mode 3 = escurecer atras de janela: xadrez de 1 px em ink (metade dos pixels), sem semitransparencia.
//   mode 4 = contorno externo de 1 px na cor fill (o heroi se destaca de cenarios carregados); miolo intacto.
// Alfa: pixel com alfa >= 0.5 fica opaco, o resto some (a arte nunca e semitransparente).
shader_type canvas_item;

uniform int mode = 1;
uniform vec3 fill : source_color = vec3(0.180392, 0.133333, 0.184314);
uniform vec3 ramp0 : source_color = vec3(0.180392, 0.133333, 0.184314);   // #2e222f ink
uniform vec3 ramp1 : source_color = vec3(0.243137, 0.207843, 0.274510);   // #3e3546
uniform vec3 ramp2 : source_color = vec3(0.498039, 0.439216, 0.541176);   // #7f708a lilac_grey
uniform vec3 ramp3 : source_color = vec3(0.607843, 0.670588, 0.698039);   // #9babb2 steel (texto bloqueado ainda legivel)

void fragment() {
	vec4 c = COLOR;
	if (mode == 4) {
		if (c.a >= 0.5) {
			COLOR = vec4(c.rgb, 1.0);
		} else {
			vec2 px = TEXTURE_PIXEL_SIZE;
			float n = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
					+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
			if (n < 0.5) {
				discard;
			}
			COLOR = vec4(fill, 1.0);
		}
	} else if (mode == 3) {
		ivec2 p = ivec2(floor(FRAGCOORD.xy));
		if ((p.x + p.y) % 2 == 0) {
			discard;
		}
		COLOR = vec4(ramp0, 1.0);
	} else {
		if (c.a < 0.5) {
			discard;
		}
		if (mode == 2) {
			COLOR = vec4(fill, 1.0);
		} else {
			float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
			vec3 o = l < 0.2 ? ramp0 : (l < 0.42 ? ramp1 : (l < 0.66 ? ramp2 : ramp3));
			COLOR = vec4(o, 1.0);
		}
	}
}
