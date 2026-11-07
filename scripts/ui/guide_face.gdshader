shader_type canvas_item;

uniform vec2 mouth;
uniform vec2 left_eye;
uniform vec2 right_eye;
uniform float speech : hint_range(0.0, 1.0);
uniform float blink : hint_range(0.0, 1.0);
uniform float expression : hint_range(-1.0, 1.0);
uniform sampler2D rest_frame : source_color;
uniform sampler2D blink_frame : source_color;

float falloff(vec2 offset, vec2 radius) {
	return 1.0 - smoothstep(0.24, 1.0, length(offset / radius));
}

void fragment() {
	vec2 art_size = vec2(1536.0, 1024.0);
	vec2 p = UV * art_size;
	vec2 face_center = mouth - vec2(0.0, 68.0);
	float face_weight = falloff(p - face_center, vec2(160.0, 190.0));
	p += vec2(expression * 1.3, expression * 0.8) * face_weight;
	vec2 sample_uv = p / art_size;
	// Blend authored facial frames locally so the interface and silhouette stay stable.
	vec2 lips = p - mouth;
	float lip_mask = 1.0 - smoothstep(0.68, 1.0, length(lips / vec2(92.0, 69.0)));
	vec4 original = texture(TEXTURE, sample_uv);
	vec4 rest = texture(rest_frame, sample_uv);
	vec4 result = mix(original, rest, lip_mask * (1.0 - smoothstep(0.03, 0.60, speech)));
	float left_mask = 1.0 - smoothstep(0.74, 1.0, length((p - left_eye) / vec2(66.0, 62.0)));
	float right_mask = 1.0 - smoothstep(0.74, 1.0, length((p - right_eye) / vec2(66.0, 62.0)));
	float eye_mask = max(left_mask, right_mask);
	result = mix(result, texture(blink_frame, sample_uv), eye_mask * blink);
	COLOR = result;
}
