// A Bliss-style sky: deep blue overhead fading to a pale hazy horizon, soft drifting clouds and a
// glowing sun.
shader_type sky;

uniform vec3 zenith : source_color = vec3(0.12, 0.38, 0.92);
uniform vec3 horizon : source_color = vec3(0.72, 0.88, 1.0);
uniform vec3 ground : source_color = vec3(0.55, 0.8, 0.5);
uniform vec3 sun_dir = vec3(0.4, 0.55, -0.73);
uniform float time = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.1;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = EYEDIR;
	float up = clamp(d.y, -1.0, 1.0);
	vec3 col = mix(horizon, zenith, pow(clamp(up, 0.0, 1.0), 0.55));
	if (up < 0.0) {
		col = mix(horizon, ground, clamp(-up * 6.0, 0.0, 1.0));
	}

	// Clouds live on a flat layer above, so they bunch toward the horizon like a real sky.
	if (up > 0.01) {
		vec2 uv = d.xz / (up + 0.15) * 1.4 + vec2(time * 0.01, time * 0.004);
		float c = smoothstep(0.5, 0.78, fbm(uv));
		float lit = 0.85 + 0.15 * fbm(uv * 2.0 + 3.0);
		col = mix(col, vec3(lit), c * smoothstep(0.0, 0.25, up));
	}

	vec3 s = normalize(sun_dir);
	float sd = max(dot(d, s), 0.0);
	col += vec3(1.0, 0.95, 0.8) * (pow(sd, 600.0) * 4.0 + pow(sd, 24.0) * 0.35);
	COLOR = col;
}
