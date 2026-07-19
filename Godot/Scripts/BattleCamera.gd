@tool
class_name BattleCamera extends Camera3D

@export var cur_transform : CameraTransform = CameraTransform.new()
@export var camera_speed : float = 7.5
@export_category("Editor")
@export var on_editor_custom_transform : bool = false
@export var debugging_transform : CameraTransform = CameraTransform.new()

func _process(delta: float) -> void:
	position = lerp(position,(debugging_transform.position if Engine.is_editor_hint() and on_editor_custom_transform and (debugging_transform != null) else cur_transform.position),delta*camera_speed)
	rotation = lerp(rotation,(debugging_transform.rotation if Engine.is_editor_hint() and on_editor_custom_transform and (debugging_transform != null) else cur_transform.rotation),delta*camera_speed)
	fov = lerp(fov,(debugging_transform.fov if Engine.is_editor_hint() and on_editor_custom_transform else cur_transform.fov),delta*camera_speed)

func shake_camera(power : float, sec : float):
	var og_pos = Vector2(h_offset,v_offset)
	var timer = Timer.new()
	#var fn : FastNoiseLite = FastNoiseLite.new()
	timer.autostart = false
	add_child(timer)
	timer.one_shot = true
	timer.start(sec)
	while(timer.time_left > 0):
		#var coord = fn.get_noise_2d(timer.time_left,timer.wait_time - timer.time_left)
		var new_pos = og_pos + Vector2(randf_range(-1,1),randf_range(-1,1))*power
		h_offset = new_pos.x
		v_offset = new_pos.y
		await Globals.wait(0.001)
	h_offset = og_pos.x
	v_offset = og_pos.y
