shader_type canvas_item;

uniform float blur_amount : hint_range(-2.0, 10.0);

uniform float noise_size = 12.0;
uniform float noise_fps = 6.0;
uniform vec4 noise_color : source_color;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

vec2 random(vec2 uv){
    uv = vec2( dot(uv, vec2(127.1,311.7) ),
               dot(uv, vec2(269.5,183.3) ) );
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

void fragment() {
	vec4 fin = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
	
	vec2 noise_res = 1.0 / (SCREEN_PIXEL_SIZE * noise_size);
	float noies_seed = fract(floor(TIME * noise_fps) / noise_fps) + floor(TIME) / 100.;
	float noise = clamp(random((floor(SCREEN_UV * noise_res) / noise_res) + noies_seed).x, 0., 1.);
	float noise_a = 1.-length(SCREEN_UV - vec2(.5)) * 2.;
	noise_a = max(noise_a, 0.0);
	noise_a = 1.0;
	fin.rgb += noise_color.rgb * noise * noise_color.a * noise_a;
	
	COLOR.rgb = mix(fin.rgb, COLOR.rgb, COLOR.a);
	COLOR.a = 1.0;
}