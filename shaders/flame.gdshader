shader_type spatial;
// Cartoon flame for particle quads (ground fire and burning characters, GDD 19): the quad faces the camera,
// scrolling noise breaks up a teardrop shape, and the result is cut into three flat colour bands.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 core_color : source_color = vec4(1.0, 0.93, 0.5, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.56, 0.13, 1.0);
uniform vec4 edge_color : source_color = vec4(0.86, 0.2, 0.06, 1.0);
uniform float bands = 3.0;
uniform float speed = 1.7;

varying float seed;

void vertex() {
	mat4 world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	world = world * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * world;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	seed = fract(float(INSTANCE_ID) * 0.6180339);
}

void fragment() {
	float n = texture(noise_tex, vec2(UV.x * 0.9 + seed * 7.0, UV.y * 0.8 + TIME * speed + seed)).r;
	vec2 p = UV - vec2(0.5, 0.7);
	p.x *= 1.0 + (1.0 - UV.y) * 1.5;
	float shape = 1.0 - length(p * vec2(2.3, 1.4));
	float v = clamp(shape + (n - 0.5) * 0.6, 0.0, 1.0) * COLOR.a;
	float q = floor(v * bands + 0.4) / bands;
	if (q <= 0.0) {
		discard;
	}
	vec3 col = mix(edge_color.rgb, mid_color.rgb, step(0.34, q));
	col = mix(col, core_color.rgb, step(0.67, q));
	ALBEDO = col * COLOR.rgb;
	ALPHA = 0.95;
}
