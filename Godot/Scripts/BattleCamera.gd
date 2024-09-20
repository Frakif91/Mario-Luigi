class_name BattleCamera extends Camera3D

var target_position : Vector3
var target_follow = false
var target_node : Node3D

func _process(delta: float) -> void:
	position = lerp(position,target_position,delta*7.5)

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
