shader_type canvas_item;

// Ranges from 0 to 1 over the course of the transition.
// We use this to actually animate the shader.
uniform float progress : hint_range(0.0, 2.0);

// Size of each diamond, in pixels.
uniform float diamond_pixel_size = 10.0;

void fragment() {
	float x_frac = fract(FRAGCOORD.x / diamond_pixel_size);
	float y_frac = fract(FRAGCOORD.y / diamond_pixel_size);
	float x_dist = abs(x_frac - 0.5);
	float y_dist = abs(y_frac - 0.5);
	float v = x_dist + y_dist + UV.x + UV.y + 0.5;
	if (v > clamp(progress, 0.0, 1.0) * 4.0 || v < clamp(progress - 1.0, 0.0, 1.0) * 4.0) {
		discard;
	}
}