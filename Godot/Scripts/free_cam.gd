extends Camera3D



func _process(_delta):	
	var iz = Input.get_axis(&"ui_up",&"ui_down")
	var ix = Input.get_axis(&"ui_left",&"ui_right")
	var iy = Input.get_axis(&"Jump",&"ui_cancel")

	Debugger.modify_text(&"ix","X Axis : " + str(ix))
	Debugger.modify_text(&"iy","Y Axis : " + str(iy))
	Debugger.modify_text(&"iz","Z Axis : " + str(iz))

	position += (-self.transform.basis.z.normalized()) * iz
	position += (-self.transform.basis.x.normalized()) * ix
	position += (-self.transform.basis.y.normalized()) * iy


@export var mouse_sensitivity := 2.0
@export var y_limit := 90.0
var mouse_axis := Vector2()
var rot := Vector3()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Debugger.show()
	Debugger.add_text(&"iz","Z Axis : X")
	Debugger.add_text(&"ix","X Axis : X")
	Debugger.add_text(&"iy","Y Axis : X")
	mouse_sensitivity = mouse_sensitivity / 1000
	y_limit = deg_to_rad(y_limit)


# Called when there is an input event
func _input(event: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_axis = event.relative
		camera_rotation()
	else:
		if Input.is_action_just_pressed(&"F1"):
			print("mouse changed mode")
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Called every physics tick. 'delta' is constant
# func _physics_process(delta: float) -> void:
# 	var joystick_axis := Input.get_vector(&"look_left", &"look_right",
# 			&"look_down", &"look_up")
	
# 	if joystick_axis != Vector2.ZERO:
# 		mouse_axis = joystick_axis * 1000.0 * delta
# 		camera_rotation()


func camera_rotation() -> void:
	# Horizontal mouse look.
	rot.y -= mouse_axis.x * mouse_sensitivity
	# Vertical mouse look.
	rot.x = clamp(rot.x - mouse_axis.y * mouse_sensitivity, -y_limit, y_limit)
	
	rotation.y = rot.y
	rotation.x = rot.x