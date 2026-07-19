@abstract
class_name EnemyBehavior extends Resource

var players : Dictionary[String, BrotherCB3]

@abstract
func player_choosing_behavior() -> BrotherCB3

@abstract
func attack(enemy)