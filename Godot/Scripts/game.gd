extends Node3D

signal animation_called_event

@onready var choosecube : OptionBlocks = $"ChooseCube"
@onready var label : Label3D = $"ChooseCube/SoftBody3D/Label3D"
@onready var anima : AnimationPlayer = $AnimationPlayer
@onready var itemlist : Control = %ItemList
@onready var label_change_effect_timer = Timer.new()
@onready var mario_anim = $"MarioAnimations"
@onready var ratings = $"UI/Ratings/RatingsAnim"

#@export_node_path("Anim"
#overrite_animation
@export var transition_speed_multiplier = 1.
@export var event_caller : float = 0.0 :
	set(id):
		if id == 24:
			animation_called_event.emit()
		event_caller = 0
		if id > 0 and id < 24:
			choosecube.set_global_transparence(id)

var damage_instance = preload("res://Godot/Nodes/damage_display.tscn")
@export var jump_class = preload("res://Godot/Scripts/manual_animations.gd")
var transition_direction = 1
var transition_time = 0.07
var camera_position = {OG = Vector3(1.,1.4,2.), T_ENEMY = Vector3(1.4,1.4,2.2), OUT = Vector3(1,2,3),LUIGI = Vector3(0.5,1.4,2.5)}
var animation_offsets = {"idle" = Vector3(0.08,0,0),"hammer" = Vector3(0.088,0.143,-0.04)}
var chooseblocks_offsets = {MARIO = Vector2(-0.3,-1), LUIGI = Vector2(-1.05,0.6)}
var cur_cam_pos = camera_position.OG
var action_who : BrotherCB3
var jump_process : Actions

func _ready():
	Globals.cur_brother = Globals.BROTHER.MARIO
	Globals.cur_action = Globals.ACTIONS_BLOCKS.NONE
	Globals.eat_inventory_item.connect(_mario_play_eat_animation)
	choosecube.hit_block.connect(Hitting_Block)
	label_change_effect_timer.autostart = false
	label_change_effect_timer.one_shot = true
	jump_process = jump_class.new(
	$"Characters/Mario",$"Characters/Luigi",[$"Characters/Goomba",$"Characters/Goomba2"],$"UI/Ratings/RatingsAnim",set_visible_choosecube)
	self.add_child(jump_process)
	self.add_child(label_change_effect_timer)
	choosecube.change_block.connect(changed_block)

	$"Characters/Mario/AnimatedSprite3D".position = animation_offsets["idle"]

	itemlist.set_deferred(&"size",Vector2(1152,648)) #In case of problems
	anima.play(&"show_itemlist")
	anima.advance(0.01)
	anima.stop()
	anima.play(&"hide_cubes")

	await Globals.wait(Globals.trans_ready_time + 1.1)
	anima.play_backwards(&"hide_cubes")

func change_character(brother : Globals.BROTHER):
	if brother == Globals.BROTHER.LUIGI:
		cur_cam_pos = camera_position.LUIGI
		choosecube.center_point = chooseblocks_offsets.LUIGI
		action_who = $"Characters/Luigi"
		Globals.cur_brother = Globals.BROTHER.LUIGI
	
	elif brother == Globals.BROTHER.MARIO:
		cur_cam_pos = camera_position.OG
		choosecube.center_point = chooseblocks_offsets.MARIO
		action_who = $"Characters/Mario"
		Globals.cur_brother = Globals.BROTHER.MARIO
		$"UI/S2D_to_3D".position = action_who.position + Vector3(-0.4,0,0)

#region Inputs
func _input(_event):
	if Input.is_action_just_pressed(&"Back") and (Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_SELECTING or Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_MENU):
		$"BackSound".play()
		await set_visible_choosecube()
	if Input.is_action_just_pressed(&"Test2"):
		print("cur brother : ", str(Globals.cur_brother) )
		if Globals.cur_brother == Globals.BROTHER.MARIO:
			change_character(Globals.BROTHER.LUIGI)
		elif Globals.cur_brother == Globals.BROTHER.LUIGI:
			change_character(Globals.BROTHER.MARIO)

	if Input.is_action_just_pressed(&"Test4"):
		cur_cam_pos = camera_position.T_ENEMY
	
	if Input.is_action_just_pressed(&"Jump"):
		if Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_SELECTING and Globals.cur_action == Globals.ACTIONS_BLOCKS.JUMP:
			Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_ACTION
			_jump_second_hit = false
			$"Characters/Goomba/Pointer".visible = false
			var result : Actions.results = await jump_process._jump_manual_animation($"Characters/Goomba".position)
			await jump_process.result_todo(result)
			print("Finish")
			Globals.MARIO.overrite_animation = false
			Globals.MARIO.overrite_animation = false
			set_visible_choosecube()

			#$"MarioAnimations".play(&"Jump_on_goomba")

func set_visible_choosecube():
	if Globals.is_itemlist_opened:
		anima.play_backwards(&"show_itemlist")
		Globals.is_itemlist_opened = false
		await anima.animation_finished
	
	if Globals.cur_brother == Globals.BROTHER.MARIO:
		cur_cam_pos = camera_position.OG
		Globals.MARIO.overrite_animation = false
		Globals.LUIGI.overrite_animation = false
	Globals.cur_action = Globals.ACTIONS_BLOCKS.NONE
	$"Characters/Goomba/Pointer".visible = false
	choosecube.is_in_choosing_position = true
	anima.play_backwards(&"hide_cubes")
	await anima.animation_finished
	Globals.MARIO.can_jump = true
	Globals.LUIGI.can_jump = true
	%AButton.show()
	Globals.chooseblocks_visible = true
	Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_CHOOSING

#region Process
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$"MainCamera".position = lerp($"MainCamera".position,cur_cam_pos,_delta*7.5)
	_jump_process(_delta)
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

#region Hit Block
func Hitting_Block():
	#print_debug("AAAAAAAAAAAAAAAAAAAA")
	if Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_CHOOSING:
		match (choosecube.selected_block_name):
			"JUMP":
				cur_cam_pos = camera_position.T_ENEMY
				Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_SELECTING
				choosecube.is_in_choosing_position = false
				Globals.MARIO.can_jump = false
				anima.play(&"hide_cubes")
				$"Characters/Goomba/Pointer".visible = true

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
				return
		Globals.cur_action = choosecube.selected_block_index
		%AButton.visible = false
			
func _mario_play_eat_animation(texture, uniqueitem):	
	if Globals.is_itemlist_opened:
		Globals.is_itemlist_opened = false
		anima.play_backwards(&"show_itemlist")

	Globals.MARIO.overrite_animation = true #Disable "state machine" animations, to let $MarioAnimation do it's job
	Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_ACTION
	Globals.MARIO.can_jump = false
	$"MarioAnimations/Sprite3D".texture = texture
	$"MarioAnimations".play(&"Eat")
	await animation_called_event
	itemlist.item_power_application(uniqueitem.item)
	await $"MarioAnimations".animation_finished
	Globals.MARIO.overrite_animation = false #Enable back "state machine" animations
	Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_CHOOSING
	Globals.MARIO.can_jump = true
	choosecube.is_in_choosing_position = true
	anima.play_backwards(&"hide_cubes")
	Globals.finish_eating.emit()

func _on_animated_sprite_3d_animation_changed():
	#print_debug("AAAAHHHHHHH : ",$"Characters/Mario/AnimatedSprite3D".animation)
	$"Characters/Mario/AnimatedSprite3D".play(&"",1.,false) #Play animation when AnimationPlayer change AnimatedSprite's animation, because it's stops automaticly if it doesn't loop 


var _jump_second_hit = false
var _jump_can_hit = false
var _jump_timing = 0.0
var _jump_minimal_window = 0.01
var _jump_maximal_window = 0.09

var is_debug = true

#region Jump
func _jump_enable_hit(begin_timing : float, end_timing : float):
	_jump_can_hit = true
	_jump_timing = 0.0
	_jump_minimal_window = begin_timing
	_jump_maximal_window = end_timing
	if is_debug:
		print("MAX_WIN : ",begin_timing)
		print_debug("MIN_WIN : ",end_timing)

func _jump_disable_hit():
	print_debug("Disabled Hit")
	_jump_can_hit = false
	#assert(_jump_timing < _jump_minimal_window and _jump_timing > _jump_maximal_window,"In Hit Window >>>  " + str(_jump_minimal_window, "<", _jump_timing, "<", _jump_maximal_window) )
	if _jump_second_hit:
		#ratings.play(&"Good")
		print_debug("Failed Second hit")
		ratings.play(&"RESET")
	else:
		print_debug("Failed First hit")
		ratings.play(&"Ok")
	mario_anim.play(&"fail_stomp")
	await mario_anim.animation_finished
	mario_anim.play(&"RESET")
	set_visible_choosecube()
	#set_visible_choosecube()

func show_damage(damage : int, posin3d : Vector3, damage_type : int):
	print("SHOWED")
	var di : DamageAnnouncer = damage_instance.instantiate()
	di.create(posin3d,damage,damage_type)
	$"UI".add_child(di)
	di.show()
	di.showup()

func _jump_process(_delta):
	if _jump_can_hit:
		_jump_timing += _delta
		if Input.is_action_just_pressed("Jump"):
			print("Test Variable",_jump_minimal_window,_jump_timing,_jump_maximal_window)
			if _jump_timing >= _jump_minimal_window and _jump_timing <= _jump_maximal_window:
				if _jump_second_hit:
					show_damage(13,$"Characters/Goomba".position + Vector3(0.05,-0.1,0),DamageAnouncerTexture.BackGroundTexture.DAMAGE)
					print_debug("Sucess Second Hit")
					ratings.play(&"Excellent")
					_jump_can_hit = false
					mario_anim.play(&"_jump_sucess")
					await mario_anim.animation_finished
					ratings.play(&"RESET")
					mario_anim.play(&"RESET")
					set_visible_choosecube()
				else:
					print_debug("Sucess First Hit")
					show_damage(11,$"Characters/Goomba".position + Vector3(0.05 + randf()/10.,-0.2 + randf()/10,0),DamageAnouncerTexture.BackGroundTexture.DAMAGE)
					ratings.play(&"Good")
					_jump_can_hit = false
					mario_anim.play(&"double_jump_on_goomba")
					_jump_second_hit = true
			else:
				print_debug("Failed")
				await _jump_disable_hit()

func hammer_enable_hit():
	pass