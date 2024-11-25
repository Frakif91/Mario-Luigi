class_name NPC extends Area3D

enum InteractionTypes {NONE, MANDATORY, USER_INTERACT}
@export var interaction_type : InteractionTypes = InteractionTypes.NONE
@export var dialogfield : DialogField
@export_node_path("Area3D") var area_collider_np : NodePath = ^"./Area3D"
@onready var area_collider : Area3D = get_node(area_collider_np)
var occupied : bool = false

@onready var textbox = preload("res://Godot/Nodes/Textbox.tscn").instantiate()
var textbox_opened : bool = false

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
						start_action(ob)
		InteractionTypes.USER_INTERACT:
			if not occupied:
				for ob in area_collider.get_overlapping_bodies():
					if ob is MarioOW_Movement && Input.is_action_just_pressed((Globals.Bros["Mario"] as Brother).action_button):
						start_action(ob)

func start_action(player : MarioOW_Movement):
	occupied = true
	player.is_in_cutscene = true
	var i = 0
	for dialog in dialogfield.dialog:
		if dialog is DialogText:
			if not textbox_opened:
				open_textbox()
		else:
			if textbox_opened:
				close_textbox()
			if dialog is Dialog:
				dialog.execute(get_tree(),player,self)
		i += 1
	if textbox_opened:
		close_textbox()

func close_textbox():
	pass

func open_textbox():
	pass