class_name Fake_Shadow extends Node3D

@export_range(0.01,100,0.01) var max_shadow_distance = 2.0
@export var shadow_curve : Curve
@export var pos_offset : Vector3
@export var shadow_texture : Texture2D
var origin_point : Vector3

@export_node_path("RayCast3D") var ray_np : NodePath
@onready var ray : RayCast3D = get_node(ray_np)

@export_node_path("Decal") var decal_np : NodePath
@onready var decal : Decal = get_node(decal_np)

func _ready() -> void:
	Debugger.add_text(&"shadow","[i]Shadows[/i] Test")
	#ray.hit_from_inside = false
	ray.target_position = Vector3(0,-max_shadow_distance,0)
	decal.texture_albedo = shadow_texture
	#ray.collision_mask = 0b00000000_00000000_00000000_00000001 # Only detect mask 1

func _physics_process(_delta: float) -> void:
	ray.global_position = global_position + pos_offset
	ray.force_raycast_update()
	if ray.is_colliding():
		var distance = abs(ray.global_position.y - ray.get_collision_point().y)
		decal.albedo_mix = shadow_curve.sample_baked(1 - (distance / max_shadow_distance))
		decal.global_position = ray.get_collision_point()
		Debugger.modify_text(&"shadow","Colliding with " + str(distance))
	else:
		decal.albedo_mix = shadow_curve.sample_baked(0)
		Debugger.modify_text(&"shadow","[i]Shadows[/i] No collision detected")

