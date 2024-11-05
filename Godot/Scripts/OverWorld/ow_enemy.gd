extends Node3D

# What level the mario brothers need to be to one shot this enemy
@export var enemy_preset : EnemyInfo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if enemy_preset:
		$"StompableArea".monitorable = true if enemy_preset.is_stompable else false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
