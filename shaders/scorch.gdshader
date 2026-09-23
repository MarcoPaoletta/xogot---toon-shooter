shader_type spatial;
// Scorched ground under a fire patch: a dark ragged disc with flickering embers. `fade` runs 0 to 1 to 0.
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float n = texture(noise_tex, UV * 1.3).r;
	float mask = smoothstep(1.0, 0.6, length(p) + (n - 0.5) * 0.6);
	float e = texture(noise_tex, UV * 3.1 + vec2(0.0, TIME * 0.04)).r;
	float ember = smoothstep(0.64, 0.78, e) * mask;
	ALBEDO = vec3(0.13, 0.085, 0.06);
	ROUGHNESS = 1.0;
	EMISSION = vec3(1.0, 0.36, 0.06) * ember * (0.55 + 0.45 * sin(TIME * 7.0 + e * 30.0)) * 2.5 * fade;
	ALPHA = mask * 0.85 * fade;
}
