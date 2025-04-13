shader_type canvas_item;
render_mode unshaded;

uniform float scale = 1.0;
uniform vec2 offset = vec2(0.0);

void vertex(){
	UV = (VERTEX + offset) * TEXTURE_PIXEL_SIZE * (1.0/scale);
}