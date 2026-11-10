// Lush lawn under a paint layer of slime. The paint layer holds every snail's trail: color in one
// texture, style channels (glitter, chrome, holo) in another, drawn by PaintLayer.
shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D paint_color : filter_linear, repeat_disable;
uniform sampler2D paint_style : filter_linear, repeat_disable;
uniform float garden_size = 40.0;
uniform vec3 sky_top : source_color = vec3(0.12, 0.38, 0.92);
uniform vec3 sky_low : source_color = vec3(0.72, 0.88, 1.0);

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

vec3 rainbow(float t) {
	return 0.5 + 0.5 * cos(6.2832 * (t + vec3(0.0, 0.33, 0.67)));
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz / garden_size + 0.5;
	vec4 paint = texture(paint_color, uv);
	vec4 style_paint = texture(paint_style, uv);
	// Stamps blend over transparent black, so color comes out premultiplied by coverage.
	vec3 slime = paint.rgb / max(paint.a, 0.001);
	float cover = smoothstep(0.08, 0.35, paint.a);
	vec3 style = style_paint.rgb / max(style_paint.a, 0.001) * cover;

	vec2 g = world_pos.xz;
	float patches = noise(g * 0.25) * 0.6 + noise(g * 1.3) * 0.4;
	vec3 grass = mix(vec3(0.14, 0.44, 0.1), vec3(0.3, 0.64, 0.16), patches);
	grass *= 0.9 + 0.2 * noise(g * 9.0);

	vec3 view = normalize(CAMERA_POSITION_WORLD - world_pos);
	// Chrome slime mirrors the sky; flat ground reflects straight up the view ray.
	vec3 r = reflect(-view, vec3(0.0, 1.0, 0.0));
	vec3 mirror = mix(sky_low, sky_top, pow(clamp(r.y, 0.0, 1.0), 0.5));
	mirror = mix(vec3(0.25, 0.3, 0.35), mirror, smoothstep(-0.05, 0.08, r.y));
	vec3 col = slime;
	col = mix(col, mirror * mix(vec3(1.0), slime, 0.35) * 1.15, clamp(style.g, 0.0, 1.0));
	vec3 holo = rainbow(dot(view, vec3(0.7, 0.4, 0.6)) * 2.0 + (g.x + g.y) * 0.15);
	col = mix(col, mix(slime, holo, 0.75), clamp(style.b, 0.0, 1.0));

	// Glitter: fine cells that each flash at their own moment as the camera moves.
	vec2 cell = floor(g * 18.0);
	float seed = hash(cell);
	float flash = step(0.7, seed) * pow(max(sin(TIME * 2.0 + seed * 40.0 + dot(view, vec3(9.0, 3.0, 7.0))), 0.0), 6.0);
	float glitter = clamp(style.r, 0.0, 1.0);
	col += vec3(1.0, 0.97, 0.85) * flash * glitter * 2.0;

	ALBEDO = mix(grass, col, cover);
	ROUGHNESS = mix(0.85, 0.06, cover);
	SPECULAR = mix(0.15, 1.0, cover);
	METALLIC = clamp(style.g, 0.0, 1.0) * 0.5;
	EMISSION = (vec3(1.0) * flash * glitter * 1.5 + holo * clamp(style.b, 0.0, 1.0) * 0.15);
}
