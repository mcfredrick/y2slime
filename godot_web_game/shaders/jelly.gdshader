// Wet, squishy snail skin and glossy toy plastic for garden props: soft color, a bright rim and a
// tight specular glint. `wobble` breathes the surface a little for living things.
shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec3 color : source_color = vec3(0.6, 0.9, 0.4);
uniform float roughness = 0.2;
uniform float wobble = 0.0;
uniform float rim = 0.35;

void vertex() {
	VERTEX += NORMAL * sin(TIME * 3.0 + VERTEX.z * 12.0) * 0.006 * wobble;
}

void fragment() {
	float edge = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	ALBEDO = color;
	EMISSION = color * pow(edge, 3.0) * 0.15;
	ROUGHNESS = roughness;
	SPECULAR = 0.8;
	RIM = rim;
	RIM_TINT = 0.5;
}
