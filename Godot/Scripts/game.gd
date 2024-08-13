extends Node3D

signal animation_called_event

@onready var choosecube : OptionBlocks = $"ChooseCube"
@onready var label : Label3D = $"ChooseCube/SoftBody3D/Label3D"
@onready var anima : AnimationPlayer = $AnimationPlayer
@onready var itemlist : Control = $ItemList
@export var transition_speed_multiplier = 1.
@export var event_caller : float = 0.0 :
	set(id):
		if id == 24:
			animation_called_event.emit()
		event_caller = 0
		if id > 0 and id < 24:
			choosecube.set_global_transparence(id)
@onready var label_change_effect_timer = Timer.new()
var transition_direction = 1
var transition_time = 0.07

func _ready():
	Globals.eat_inventory_item.connect(_mario_play_eat_animation)
	choosecube.hit_block.connect(Hitting_Block)
	label_change_effect_timer.autostart = false
	label_change_effect_timer.one_shot = true
	self.add_child(label_change_effect_timer)
	choosecube.change_block.connect(changed_block)

	itemlist.set_deferred(&"size",Vector2(1152,648)) #In case of problems
	anima.play(&"show_itemlist")
	anima.advance(0.01)
	anima.stop()
	anima.play(&"hide_cubes")

	await Globals.wait(Globals.trans_ready_time + 1.1)
	anima.play_backwards(&"hide_cubes")

func _input(_event):
	if Input.is_action_just_pressed(&"Back") and (Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_SELECTING or Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_MENU):
		if Globals.is_itemlist_opened:
			anima.play_backwards(&"show_itemlist")
			Globals.is_itemlist_opened = false
			await anima.animation_finished
		choosecube.is_in_choosing_position = true
		Globals.MARIO.can_jump = true
		anima.play_backwards(&"hide_cubes")
		Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_CHOOSING

	if Input.is_action_just_pressed(&"Test2"):
		#WRONG CALL METHOD, LAG INTENDED, WARNING -> FOR TEST ONLY
		Globals.eat_inventory_item.emit(load("res://Godot/Assets/1UP Mushroom.tres"),"Balls")
		#Globals.MARIO.mario_overrite_animation = true
		#$"MarioAnimations".play(&"Eat")
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (label_change_effect_timer.time_left):
		label.position.y = label_change_effect_timer.time_left * transition_direction
		label.modulate.a = (transition_time - label_change_effect_timer.time_left)/transition_time*5
	else:
		label.position.y = 0.0
		label.modulate.a = 1.0

func changed_block(_curent_index: int, direction : int):
	label_change_effect_timer.start(transition_time)
	transition_direction = direction
	label.position.y = transition_time * direction
	label.modulate.a = 0
	label.text = choosecube.get_choose_cube_name()
	#label.text = BLOCKS_NAMES[-_curent_index % choosecube.blocks_nb]
	
func Hitting_Block():
	#print_debug("AAAAAAAAAAAAAAAAAAAA")
	if Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_CHOOSING:
		match (choosecube.selected_block_name):
			"JUMP":
				Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_SELECTING
				choosecube.is_in_choosing_position = false
				anima.play(&"hide_cubes")

			"ITEM":
				Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_MENU
				choosecube.is_in_choosing_position = false
				Globals.MARIO.can_jump = false
				anima.play(&"hide_cubes",0.1,3)
				await anima.animation_finished
				anima.play(&"show_itemlist")
				Globals.is_itemlist_opened = true
			_:
				$"InvalidSound".play()
				push_error(error_string(ERR_CANT_RESOLVE), " : Block \"{}\" not found".format([choosecube.selected_block_name],"{}"))

func _mario_play_eat_animation(texture, uniqueitem):	
	if Globals.is_itemlist_opened:
			anima.play_backwards(&"show_itemlist")

	Globals.MARIO.mario_overrite_animation = true #Disable "state machine" animations, to let $MarioAnimation do it's job
	Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_ACTION
	Globals.MARIO.can_jump = false
	$"MarioAnimations/Sprite3D".texture = texture
	$"MarioAnimations".play(&"Eat")
	await animation_called_event
	itemlist.item_power_application(uniqueitem.item)
	await $"MarioAnimations".animation_finished
	Globals.MARIO.mario_overrite_animation = false #Enable back "state machine" animations
	Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_CHOOSING
	Globals.MARIO.can_jump = true
	choosecube.is_in_choosing_position = true
	anima.play_backwards(&"hide_cubes")
	Globals.finish_eating.emit()

func _on_animated_sprite_3d_animation_changed():
	$"Characters/Mario/AnimatedSprite3D".play() #Play animation when AnimationPlayer change AnimatedSprite's animation, because it's stops automaticly if it doesn't loop 