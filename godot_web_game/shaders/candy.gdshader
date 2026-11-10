// Translucent candy plastic, like an iMac G3: a deep color that glows lighter at the edges as if
// light passes through, and a hard white highlight.
shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec3 color : source_color = vec3(1.0, 0.4, 0.8);
uniform float glow = 0.35;

void fragment() {
	float edge = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	ALBEDO = color * (0.75 + 0.25 * edge);
	EMISSION = mix(color, vec3(1.0), 0.35) * pow(edge, 2.5) * glow;
	ROUGHNESS = 0.08;
	SPECULAR = 1.0;
	RIM = 0.3;
	RIM_TINT = 0.4;
}
