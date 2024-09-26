shader_type canvas_item;
const vec2 first_object = vec2(200,200);
const ivec2 screen_size = ivec2(1152,648);

bool is_between_i(int value, int min, int max){
	return (min <= value && value <= max);
}

bool is_between_f(float value, float min, float max){
	return (min <= value && value <= max);
}

bool is_in_rectangle(vec2 point, vec4 rectangle)
{
	if(point.x >= rectangle[0] &&
	   point.x <= rectangle[2] &&
	   point.y >= rectangle[1] &&
	   point.y <= rectangle[3])
	{
		return true;
	}
	return false;
}

void fragment() {
    vec2 uv = FRAGCOORD.xy / vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);
    vec4 texColor = texture(TEXTURE, UV);
	vec2 screen_middle = vec2(screen_size.xy/2);

	if(COLOR.r == 0. && COLOR.g == 0. && COLOR.b == 0. && COLOR.a == 255.){
		texColor.a = 0.;
	}

	COLOR = texColor;
	/*
    vec2 uv = FRAGCOORD.xy / vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);
    vec4 texColor = texture(TEXTURE, UV);

    // Check if the current fragment is within the area of the first object
    if (true){//(point_inside_object(uv, first_object)) {
        texColor.a = 0.0; // Make the TextureRect transparent
    }

    COLOR = texColor;
	*/
}


//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
