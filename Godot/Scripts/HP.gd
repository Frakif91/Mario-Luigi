extends Control

@export var hp : int = 24
@export var bp : int = 18
@export var low_health_effect = true
@export var low_hp_color = Color(1,0,0.8)
@export var low_bp_color = Color.WHITE
@export var low_percentage = 0.3
@export var max_hp = 24
@export var max_bp = 18
@export var affect_BP = true
@export var hide_zeros = true

const og_link = "res://Assets/Numbers/"
var images 

func _ready():
	images = [
		load(og_link + "0.png"),
		load(og_link + "1.png"),
		load(og_link + "2.png"),
		load(og_link + "3.png"),
		load(og_link + "4.png"),
		load(og_link + "5.png"),
		load(og_link + "6.png"),
		load(og_link + "7.png"),
		load(og_link + "8.png"),
		load(og_link + "9.png")]

var change_speed = 10
var temp_hp : float = hp
var temp_bp : float = bp

func _process(_delta):
	if not Engine.is_editor_hint(): #DON'T RUN THE SCRIPT INSIDE THE EDITOR

		#Smooth HP increaser/decreaser.
		temp_hp = move_toward(temp_hp,Globals.MARIO.hp,_delta*change_speed)
		max_hp = Globals.MARIO.max_hp #move_toward(max_hp,Globals.MARIO.max_hp,_delta*change_speed)
		temp_bp = move_toward(temp_bp,Globals.MARIO.bp,_delta*change_speed)
		max_bp = Globals.MARIO.max_bp #move_toward(max_bp,Globals.MARIO.max_bp,_delta*change_speed)

		hp = int(temp_hp)
		bp = int(temp_bp)

	var image_hp_10
	var image_hp_01
	#var image_bp_10
	#var image_bp_01

	if (hp < 10):
		image_hp_01 = images[hp]
		image_hp_10 = images[0]
	else:
		image_hp_01 = images[hp%10]
		image_hp_10 = images[floor(hp/10.0)]

	#if (bp < 10):
	#	image_bp_01 = images[bp]
	#	image_bp_10 = images[0]
	#else:
	#	image_bp_01 = images[int(str(bp)[1])]
	#	image_bp_10 = images[int(str(bp)[0])]
	
	$"UI_Health/HP_01".texture = image_hp_01
	#$"UI_Health/BP_01".texture = image_bp_01
	$"UI_Health/HP_10".texture = image_hp_10
	#$"UI_Health/BP_10".texture = image_bp_10

	if hide_zeros:
		if (hp < 10):
			$"UI_Health/HP_10".visible = false
		else:
			$"UI_Health/HP_10".visible = true
		
		#if (bp < 10):
		#	$"UI_Health/BP_10".visible = false
		#else:
		#	$"UI_Health/BP_10".visible = true

	if low_health_effect:
		if hp < (max_hp*low_percentage):
			$"UI_Health/HP_01".self_modulate = low_hp_color
			$"UI_Health/HP_10".self_modulate = low_hp_color
		else:
			$"UI_Health/HP_01".self_modulate = Color.WHITE
			$"UI_Health/HP_10".self_modulate = Color.WHITE
	#if low_health_effect and affect_BP:
	#	if bp < (max_bp*low_percentage):
	#		$"UI_Health/BP_01".self_modulate = low_bp_color
	#		$"UI_Health/BP_10".self_modulate = low_bp_color
	#	else:
	#		$"UI_Health/BP_01".self_modulate = Color("white")
	#		$"UI_Health/BP_10".self_modulate = Color("white")
