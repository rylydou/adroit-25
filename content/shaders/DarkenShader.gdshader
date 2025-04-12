shader_type canvas_item;

uniform float darkness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    tex_color.rgb *= (1.0 - darkness);
    COLOR = tex_color;
}