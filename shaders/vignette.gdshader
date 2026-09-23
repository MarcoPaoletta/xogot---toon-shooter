shader_type canvas_item;
// Red damage vignette (GDD 7.2): radial, strongest at the frame edges.
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.85, 0.05, 0.05, 1.0);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p * vec2(1.0, 0.8));
	COLOR = vec4(tint.rgb, amount * smoothstep(0.45, 1.15, d));
}
