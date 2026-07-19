class_name GoombaBehavior extends EnemyBehavior

func player_choosing_behavior() -> BrotherCB3:
    var list_of_available_players : Array[BrotherCB3] = []
    for player in players:
        if players[player].is_alive():
            list_of_available_players.append(players[player])
    return list_of_available_players.pick_random()

func attack(enemy: EnemyUnit) -> void:
    pass

func _jump_manual_animation(position : Vector3, animated_sprite : AnimatedSprite3D) -> Actions.results:
    animated_sprite.play("jump")
    return Actions.results.SUCESS

