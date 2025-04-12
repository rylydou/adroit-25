shader_type canvas_item;

uniform bool flip_horizontal = false;
uniform bool flip_vertical = false;

void fragment() {
    vec2 uv = UV;

    if (flip_horizontal) {
        uv.x = 1.0 - uv.x;
    }

    if (flip_vertical) {
        uv.y = 1.0 - uv.y;
    }

    COLOR = texture(TEXTURE, uv);
}
