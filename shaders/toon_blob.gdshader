shader_type spatial;
// Cartoon explosion and smoke balls (GDD 19): the particle's colour in three flat bands: a hot core where the
// ball faces the camera, the body colour, and a hard darker rim that reads as an outline. `heat` pushes the
// core toward yellow white (the fireball); 0 for smoke and debris.
render_mode unshaded, depth_prepass_alpha, shadows_disabled;

uniform float rim_width : hint_range(0.0, 1.0) = 0.36;
uniform float rim_dark : hint_range(0.0, 1.0) = 0.55;
uniform float core_width : hint_range(0.0, 1.0) = 0.78;
uniform float heat : hint_range(0.0, 1.0) = 0.0;
uniform float boost = 1.35;

void fragment() {
	float facing = dot(NORMAL, VIEW);
	vec3 c = COLOR.rgb;
	vec3 core = mix(c * 1.15, vec3(1.0, 0.97, 0.7), heat * 0.65);
	vec3 col = facing > core_width ? core : (facing > rim_width ? c : c * rim_dark);
	ALBEDO = col * boost;
	ALPHA = COLOR.a;
}
