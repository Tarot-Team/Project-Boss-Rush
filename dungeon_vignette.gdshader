shader_type canvas_item;

uniform float dim : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_power : hint_range(0.1, 4.0) = 2.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 1.414;
	float vig = pow(clamp(d * 1.15, 0.0, 1.0), vignette_power);
	COLOR = vec4(0.0, 0.0, 0.0, vig * dim);
}
