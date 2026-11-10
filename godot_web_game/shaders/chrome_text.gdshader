// Chrome lettering: a sky-to-horizon metal gradient with a hard bright band, sweeping shine.
shader_type canvas_item;

uniform float height = 60.0;

varying float y;
varying float x;

void vertex() {
	y = VERTEX.y;
	x = VERTEX.x;
}

void fragment() {
	float t = clamp(y / height, 0.0, 1.0);
	vec3 top = mix(vec3(0.95, 0.98, 1.0), vec3(0.45, 0.62, 0.95), smoothstep(0.0, 0.48, t));
	vec3 bottom = mix(vec3(0.15, 0.2, 0.45), vec3(0.85, 0.92, 1.0), smoothstep(0.52, 1.0, t));
	vec3 col = t < 0.5 ? top : bottom;
	float shine = smoothstep(0.92, 1.0, sin((x - y) * 0.03 - TIME * 1.5));
	col += vec3(shine) * 0.8;
	COLOR = vec4(col, texture(TEXTURE, UV).a * COLOR.a);
}
