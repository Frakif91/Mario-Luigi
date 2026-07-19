## A class that gives context information to the camera as the pos, rotation and fov
class_name  CameraTransform extends Resource

@export var position : Vector3 = Vector3.ZERO
@export_custom(PROPERTY_HINT_HIDE_QUATERNION_EDIT, "property_name:rota,suffix:°", ) var rotation : Vector3 = Vector3.ZERO
@export var fov : float = 70.0

### POS : Vec3, ROT : Vec3, FOV : float
func _init(_pos := Vector3.ZERO, _rot := Vector3.ZERO, _fov := 70.0) -> void:
    position = _pos
    rotation = _rot
    fov = _fov

