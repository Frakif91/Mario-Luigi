extends Area3D

enum InteractionTypes {NONE, MANDATORY, USER_INTERACT}
@export var interaction_type : InteractionTypes
@export_node_path("Area3D") var area_collider_np : NodePath = ^"./Area3D"
@onready var area_collider : Area3D = get_node(area_collider_np)
var occupied : bool = false

func _ready():
	pass

func _process(delta):
	match(interaction_type):
		InteractionTypes.NONE:
			pass
		InteractionTypes.MANDATORY:
			if not occupied:
				for ob in area_collider.get_overlapping_bodies():
					if ob is MarioOW_Movement:
						start_action()
		InteractionTypes.USER_INTERACT:
			if not occupied:
				for ob in area_collider.get_overlapping_bodies():
					if ob is MarioOW_Movement && Input.is_action_just_pressed((Globals.Bros["Mario"] as Brother).action_button):
						start_action()

func start_action():
	occupied = true