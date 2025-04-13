shader_type canvas_item;


uniform sampler2D tex : repeat_enable;
uniform sampler2D vine_tex : repeat_enable;
uniform float tiling = 1;
uniform float ratio = 1.0;
uniform vec2 tex_size = vec2(128.0, 128.0);
uniform vec4 tint : source_color = vec4(1.0, 0.855, 0.655, 1.0);


varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	world_pos.y *= ratio;
}


void fragment() {
	vec2 tex_uv = vec2(tiling, tiling) / tex_size;
	vec2 new_uv = world_pos * tex_uv;
	
	if (COLOR.r == 1.0) {
		COLOR.rgb = texture(tex, new_uv).rgb /** tint.rgb*/;
	}
}
