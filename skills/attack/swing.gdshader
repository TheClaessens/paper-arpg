// The Attack's swing: a wedge of a disc, flat on the ground, pointing along -Z.
// Drawn on a 2×2 plane scaled to the reach, so the disc's rim is the reach.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform float half_arc = 1.0472; // radians, either side of -Z
uniform float inner = 0.15; // hole in the middle, as a share of the reach
uniform float alpha = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0; // x right, y toward +Z
	float r = length(p);
	float angle = abs(atan(p.x, -p.y));
	if (r > 1.0 || r < inner || angle > half_arc || alpha <= 0.0) discard;
	ALBEDO = vec3(1.0);
	ALPHA = alpha;
}
