shader_type spatial;
render_mode unshaded;

uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 color = texture(texture_albedo,UV);
	if(color.rgb == vec3(1.))
	{
		ALBEDO = vec3(0.1);
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
