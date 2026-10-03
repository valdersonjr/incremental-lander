// Filtro CRT de tela inteira (opcao "Filtro CRT", ligado por padrao). Roda na resolucao da arte (640x360, antes da
// ampliacao inteira do modo viewport), entao tudo e medido em pixels de arte: linha de varredura = linha de arte
// alternada, sem curvatura (deformaria pixels e texto). Efeitos sutis para nao prejudicar a leitura da interface.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
// Escurecimento das linhas de varredura (linhas de arte impares).
uniform float scanline : hint_range(0.0, 0.5) = 0.12;
// Brilho do fosforo: os vizinhos claros "vazam" luz.
uniform float glow : hint_range(0.0, 1.0) = 0.22;
// Separacao de cor (vermelho de um lado, azul do outro), em fracao de um pixel vizinho.
uniform float chroma : hint_range(0.0, 1.0) = 0.22;
// Escurecimento das bordas e raio dos cantos do tubo (em pixels de arte).
uniform float vignette : hint_range(0.0, 1.0) = 0.28;
uniform float corner_px : hint_range(0.0, 40.0) = 10.0;
// Mascara de fosforo leve (colunas alternadas um pouco mais frias/quentes).
uniform float mask : hint_range(0.0, 0.3) = 0.04;

vec3 tex(vec2 uv) {
	return texture(screen_tex, uv).rgb;
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 uv = SCREEN_UV;
	vec3 c = tex(uv);
	// separacao de cor horizontal
	vec3 l = tex(uv - vec2(px.x, 0.0));
	vec3 r = tex(uv + vec2(px.x, 0.0));
	c.r = mix(c.r, l.r, chroma);
	c.b = mix(c.b, r.b, chroma);
	// brilho: media da cruz de vizinhos, so a parte clara soma
	vec3 u = tex(uv - vec2(0.0, px.y));
	vec3 d = tex(uv + vec2(0.0, px.y));
	vec3 blur = (l + r + u + d) * 0.25;
	c += max(blur - 0.35, vec3(0.0)) * glow;
	// linhas de varredura e mascara de fosforo (em pixels de arte)
	vec2 p = floor(FRAGCOORD.xy);
	c *= 1.0 - scanline * mod(p.y, 2.0);
	c *= mod(p.x, 2.0) < 1.0 ? vec3(1.0 + mask, 1.0, 1.0 - mask) : vec3(1.0 - mask, 1.0, 1.0 + mask);
	// vinheta suave + cantos arredondados do tubo
	vec2 cuv = uv * 2.0 - 1.0;
	c *= 1.0 - vignette * pow(dot(cuv * vec2(0.75, 0.95), cuv * vec2(0.75, 0.95)), 2.0);
	vec2 size = 1.0 / px;
	vec2 q = abs(uv * size - size * 0.5) - (size * 0.5 - corner_px);
	float dist = length(max(q, vec2(0.0))) - corner_px;
	c *= clamp(-dist, 0.0, 1.0);
	COLOR = vec4(c, 1.0);
}
