shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec3 light_tint : source_color = vec3(1.0, 0.94, 0.82);
uniform float strength : hint_range(0.0, 0.35) = 0.09;
uniform float falloff_power : hint_range(0.5, 4.0) = 2.2;

void fragment() {
	vec2 c = UV - vec2(0.5);
	float d = length(c) * 2.0;
	// Circular mask: 1 at centre, 0 past the circle (no square corners).
	float k = 1.0 - smoothstep(0.0, 1.0, d);
	k = pow(max(k, 0.0), falloff_power);
	COLOR = vec4(light_tint * strength * k, 1.0);
}
