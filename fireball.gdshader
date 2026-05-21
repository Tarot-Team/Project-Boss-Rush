shader_type canvas_item;
render_mode blend_add;

uniform float glow_strength : hint_range(0.0, 3.0) = 1.2;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 warm = tex.rgb * vec3(2.2, 1.15, 0.35) * glow_strength;
	float a = tex.a;
	COLOR = vec4(warm, a);
}
