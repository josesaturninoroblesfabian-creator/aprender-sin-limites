shader_type canvas_item;

uniform vec2 mouth;
uniform vec2 left_eye;
uniform vec2 right_eye;
uniform float speech : hint_range(0.0, 1.0);
uniform float blink : hint_range(0.0, 1.0);
uniform float expression : hint_range(-1.0, 1.0);

float falloff(vec2 offset, vec2 radius) {
	return 1.0 - smoothstep(0.24, 1.0, length(offset / radius));
}

void fragment() {
	vec2 art_size = vec2(1536.0, 1024.0);
	vec2 p = UV * art_size;
	vec2 lip = p - mouth;
	float lip_weight = falloff(lip, vec2(68.0, 50.0));
	// Collapse the original smile between syllables and let the jaw open on speech peaks.
	p.y += (lip.y * (0.42 - 0.72 * speech) + expression * 3.0) * lip_weight;
	p.x += lip.x * expression * 0.09 * lip_weight;
	vec2 left = p - left_eye;
	vec2 right = p - right_eye;
	p.y += clamp(left.y * 2.1, -31.0, 31.0) * falloff(left, vec2(43.0, 42.0)) * blink;
	p.y += clamp(right.y * 2.1, -31.0, 31.0) * falloff(right, vec2(43.0, 42.0)) * blink;
	COLOR = texture(TEXTURE, p / art_size);
}
