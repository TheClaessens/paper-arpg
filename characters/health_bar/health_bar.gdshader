// A Health bar: a dark frame around a red fill that covers `fraction` of the inside from the
// left. The quad always faces the camera, so the bar reads flat on screen. Unshaded, like the
// Standees.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 fill_color : source_color = vec4(0.847, 0.278, 0.227, 1.0); // #d8473a
uniform vec4 frame_color : source_color = vec4(0.106, 0.082, 0.071, 1.0); // #1b1512
// The frame's thickness as a share of the quad: 2 of its 100×9 viewport units.
uniform vec2 frame = vec2(0.02, 0.222);
// How full the bar is, 0 to 1. Per bar, set by health_bar.gd.
instance uniform float fraction = 1.0;

void vertex() {
	// Face the camera: the model's position with the camera's axes.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 inside = (UV - frame) / (1.0 - 2.0 * frame); // 0 to 1 across the inside of the frame
	bool filled = all(greaterThanEqual(inside, vec2(0.0))) && inside.y <= 1.0 && inside.x < fraction;
	ALBEDO = filled ? fill_color.rgb : frame_color.rgb;
}
