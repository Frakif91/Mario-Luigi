extends TextureRect

var og_pos : Vector2 = Vector2(-1152,-648)
var target_pos : Vector2 = Vector2(0,0)
var progression : float = 0
@export var tile_size = 256
@export var h_tile_number = 4.5
@export var v_tile_number = 2.5
@export var parkour_times = 1
@export var seconds : float = 5
@export var adapt_size_for_parkour : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
    if adapt_size_for_parkour:
        size = Vector2((tile_size*h_tile_number)*(parkour_times+1),(tile_size*v_tile_number)*(parkour_times+1))
    go_to(-Vector2((tile_size*h_tile_number)*parkour_times,(tile_size*v_tile_number)*parkour_times),Vector2.ZERO,seconds)

func go_to(from : Vector2, to : Vector2, _seconds : float):
    target_pos = to
    og_pos = from
    progression = 0.0
    seconds = _seconds

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    progression = clamp(progression + (delta/seconds),0,1)
	
    if progression >= 1:
        progression = 0
	
    position = lerp(og_pos,target_pos,progression)