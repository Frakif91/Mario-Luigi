extends Control

@export var hp : int = 24 :
	set(new_hp):
		if hp != new_hp:
			hp = new_hp
			set_values(hp,bp)
@export var bp : int = 18 :
	set(new_bp):
		if bp != new_bp:
			bp = new_bp
			set_values(hp,bp)
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

@onready var HP = $"UI_Health/HP"
@onready var BP = $"UI_Health/BP"

func _ready():
	set_values(hp,bp)
	

@export var change_speed = 10
var temp_hp : float = hp
var temp_bp : float = bp

func _process(_delta):
	if who_is == 0:
		if not Engine.is_editor_hint(): #DON'T RUN THE SCRIPT INSIDE THE EDITOR
			#Smooth HP increaser/decreaser.
			temp_hp = lerpf(temp_hp,Globals.MARIO.hp,_delta*change_speed)
			max_hp = Globals.cur_brother.max_hp #move_toward(max_hp,Globals.MARIO.max_hp,_delta*change_speed)
			temp_bp = lerpf(temp_bp,Globals.MARIO.bp,_delta*change_speed)
			max_bp = Globals.MARIO.max_bp #move_toward(max_bp,Globals.MARIO.max_bp,_delta*change_speed)

			hp = int(temp_hp)
			bp = int(temp_bp)
	elif who_is == 1:
		#Smooth HP increaser/decreaser.
			temp_hp = lerpf(temp_hp,Globals.LUIGI.hp,_delta*change_speed)
			max_hp = Globals.cur_brother.max_hp #move_toward(max_hp,Globals.MARIO.max_hp,_delta*change_speed)
			temp_bp = lerpf(temp_bp,Globals.LUIGI.bp,_delta*change_speed)
			max_bp = Globals.cur_brother.max_bp #move_toward(max_bp,Globals.MARIO.max_bp,_delta*change_speed)

			hp = int(temp_hp)
			bp = int(temp_bp)

func set_values(_hp : int, _bp : int):
	if not HP is Control or not BP is Control:
		return
	if not HP.is_node_ready() or not BP.is_node_ready():
		return
	
	if low_health_effect and Globals.cur_brother.update_state() == Globals.cur_brother.states.TIRED:
		HP.modulate = low_hp_color
	else:
		HP.modulate = Color.WHITE

	HP.value = _hp
	BP.value = _bp
