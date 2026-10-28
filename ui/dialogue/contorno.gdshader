shader_type canvas_item;

uniform vec4 cor_contorno : source_color = vec4(0.106, 0.106, 0.106, 1.0);
uniform float espessura = 4.0;
uniform float saturacao : hint_range(0.0, 1.0) = 1.0;
uniform float brilho : hint_range(0.0, 1.0) = 0.0;   // clarão da troca de expressão, só no desenho

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float viz = 0.0;
	for (int i = 0; i < 16; i++) {
		float a = float(i) * TAU / 16.0;
		viz = max(viz, texture(TEXTURE, UV + vec2(cos(a), sin(a)) * espessura * TEXTURE_PIXEL_SIZE).a);
	}
	float cinza = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 rgb = mix(mix(vec3(cinza), c.rgb, saturacao), vec3(1.0), brilho);
	COLOR = mix(vec4(cor_contorno.rgb, viz), vec4(rgb, 1.0), c.a);
}
