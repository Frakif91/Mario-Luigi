extends CharacterBody3D

class_name Enemy

@export var max_hp = 20
@export var hp = max_hp
@export var attack_damage = 4
var invicibility

func attack_brother(brother : BrotherCB3):
    var attack_direction = Vector3(position.direction_to(brother.position))
    attack_direction.z = 0