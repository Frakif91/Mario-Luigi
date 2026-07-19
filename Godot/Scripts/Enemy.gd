class_name Enemy extends Resource

@export_category("Enemy Stats")
@export var enemy_name : StringName = "Goomba"
@export var hp : int = 8 :
	set(new_hp):
		hp = clampi(new_hp, 0, max_hp)
	get:
		return hp
@export var max_hp : int = 8
@export var attack : int = 3
@export var defense : int = 1
@export var speed : int = 5

@export_category("Behaviour")
## Certains ennemis ne parent/n'esquivent jamais (ex: Goomba).
## Servira quand tu implémenteras l'IA d'attaque/défense ennemie custom.
@export var can_defend : bool = false

@export_category("Rewards")
@export var xp_reward : int = 3
@export var coin_reward : int = 5

func is_dead() -> bool:
	return hp <= 0
