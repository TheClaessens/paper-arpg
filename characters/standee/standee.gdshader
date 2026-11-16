// A Standee's card: the current frame plus a white cut-out border, drawn on a quad
// padded by `pad_px` on every side so the border has room. Unshaded: paper ignores scene lighting (revisit when lighting matters).
shader_type spatial;
render_mode cull_disabled, unshaded;

uniform sampler2D tex : source_color, filter_nearest_mipmap;
uniform float pad_px = 8.0; // set by standee.gd, which also sizes the quad
uniform float outline_px = 5.0;
uniform vec4 outline_color : source_color = vec4(1.0);
uniform bool flip = false;
uniform bool flash = false; // a hit: the whole cut-out turns white
uniform vec4 tint : source_color = vec4(0.0); // a mark: the picture blends toward this colour by its alpha

float alpha_at(vec2 uv) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return 0.0;
	return texture(tex, uv).a;
}

void fragment() {
	vec2 size = vec2(textureSize(tex, 0));
	vec2 uv = (UV * (size + 2.0 * pad_px) - pad_px) / size;
	if (flip) uv.x = 1.0 - uv.x;
	vec4 c = alpha_at(uv) > 0.0 ? texture(tex, uv) : vec4(0.0);

	// Dilate the silhouette: 16 directions at two radii covers thin parts.
	float border = 0.0;
	for (int i = 0; i < 16; i++) {
		vec2 dir = vec2(cos(TAU * float(i) / 16.0), sin(TAU * float(i) / 16.0)) / size;
		border = max(border, max(alpha_at(uv + dir * outline_px), alpha_at(uv + dir * outline_px * 0.5)));
	}

	vec3 picture = mix(c.rgb, tint.rgb, tint.a);
	ALBEDO = flash ? vec3(1.0) : mix(outline_color.rgb, picture, c.a);
	ALPHA = max(c.a, border);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
