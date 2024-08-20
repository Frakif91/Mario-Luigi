extends TextureRect

class_name DamageAnouncerTexture

@export var textures : Array[Texture2D]

enum BackGroundTexture {MARIO,LUIGI,DAMAGE,TOTAL}
@export var cur_bg_tex : BackGroundTexture = BackGroundTexture.MARIO :
	set(value):
		cur_bg_tex = value; update()

func _ready():
	pass

func update():
	texture = textures[cur_bg_tex]