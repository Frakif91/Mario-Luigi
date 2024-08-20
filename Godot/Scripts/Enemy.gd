extends CharacterBody3D

class_name Enemy

@export var max_hp = 20
@export var hp = max_hp
@export var attack_damage = 4

func attack_brother(brother : Globals.Brother)