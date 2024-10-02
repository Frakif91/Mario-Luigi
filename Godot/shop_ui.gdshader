shader_type canvas_item;

uniform sampler2D f_img_texture : filter_nearest, repeat_enable;
uniform sampler2D s_img_texture : filter_nearest, repeat_enable;
uniform float first_image_alpha : hint_range(0.0, 1.0, 0.05);

void fragment(){
	vec4 f_tex = texture(f_img_texture, UV);
	vec4 s_tex = texture(s_img_texture, UV);
	
	COLOR.rgb = mix(f_tex.rgb, s_tex.rgb, first_image_alpha);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
