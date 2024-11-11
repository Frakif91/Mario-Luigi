extends Area3D

enum InteractionTypes {NONE, MANDATORY, USER_INTERACT}
@export var interaction_type : InteractionTypes
@export_node_path("Area3D") var area_collider_np : NodePath = ^"./Area3D"

@onready var area_collider = get_node(area_collider_np)

func _ready():
	match(interaction_type):
		InteractionTypes.NONE:
			pass
		InteractionTypes.MANDATORY:
			pass
		InteractionTypes.USER_INTERACT:
			pass