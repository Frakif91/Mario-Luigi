class_name EnemyUnit extends CharacterBody3D

## Assigner une ressource Enemy.gd différente par instance dans l'inspecteur
## (ex: goomba_stats.tres, koopa_stats.tres...)
@export var stats : Enemy

@export var enemy_behavior : Script

@onready var animated_sprite : AnimatedSprite3D = $AnimatedSprite3D

func take_damage(amount : int) -> void:
	stats.hp -= amount

func is_dead() -> bool:
	return stats.is_dead()
