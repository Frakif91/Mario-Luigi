extends Control

@export_node_path("BrotherCB3") var player_node
@onready var player : BrotherCB3 = get_node(player_node)

@export var hp : int = 24 :
	set(new_hp):
		if hp != new_hp:
			hp = new_hp
			if self.is_node_ready():
				set_values(null,hp,bp)
@export var bp : int = 18 :
	set(new_bp):
		if bp != new_bp:
			bp = new_bp
			if self.is_node_ready():
				set_values(null,hp,bp)
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
	print_debug("HP Brother Debug :",player)
	set_values(player,hp,bp)
	

@export var change_speed = 7
var temp_hp : float = hp
var temp_bp : float = bp

func _process(_delta):
	if not Engine.is_editor_hint(): #DON'T RUN THE SCRIPT INSIDE THE EDITOR
		#Smooth HP increaser/decreaser.
		if (player.bro.hp - int(temp_hp)) == 0:
			temp_hp = player.bro.hp
		else: 
			temp_hp = temp_hp + sign(player.bro.hp - temp_hp)*(_delta*change_speed)
		temp_bp = temp_bp + sign(player.bro.bp - temp_bp)*(_delta*change_speed)
		#temp_hp = temp_hp + sign(player.bro.hp)

		if hp != int(temp_hp) or bp != int(temp_bp):
			hp = int(temp_hp)
			bp = int(temp_bp)
			set_values(player,hp,bp)

func set_values(bros : BrotherCB3, _hp : int, _bp : int):
	if not HP is Control or not BP is Control:
		return
	if not HP.is_node_ready() or not BP.is_node_ready():
		return
	
	if typeof(bros) == TYPE_NIL or typeof(bros.bro) == TYPE_NIL:
		return

	if low_health_effect and bros.bro.update_state() == bros.bro.states.TIRED:
		HP.modulate = low_hp_color
	else:
		HP.modulate = Color.WHITE

	#print_debug("Set values")

	HP.value = _hp
	BP.value = _bp
