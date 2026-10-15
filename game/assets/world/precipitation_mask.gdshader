shader_type canvas_item;
// Rain and snow in strip and corner mode, where there is no sky: it should fall in front of the
// land only, not in the empty air above it (where nothing is drawn on the desktop, or, on
// Windows, where only the icons are). `tops` is one pixel per viewport column holding the y of
// the highest land pixel (WorldView builds it from the skyline); anything above it is hidden.
// Unmasked in the opaque window, where the sky is drawn.

uniform sampler2D tops : filter_nearest, repeat_disable;
uniform bool masked = false;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	if (masked) {
		float top = texture(tops, vec2((local_pos.x + 0.5) / 384.0, 0.5)).r * 255.0;
		if (local_pos.y < top) {
			COLOR.a = 0.0;
		}
	}
}
