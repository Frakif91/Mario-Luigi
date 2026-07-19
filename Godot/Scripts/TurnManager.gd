class_name TurnManager extends Node

## Émis à chaque nouveau round (queue reconstruite/triée par vitesse)
signal round_started
## Émis quand un nouvel acteur (BrotherCB3 ou EnemyUnit) commence son tour
signal turn_started(actor : Variant)
## Émis quand un acteur meurt (utile pour couper une anim en cours, etc.)
signal actor_defeated(actor : Variant)

var queue : Array = []
var index : int = -1

var _brothers_ref : Array = []
var _enemies_ref : Array = []

## À appeler une fois au début du combat.
func setup(brothers : Array, enemies : Array) -> void:
	_brothers_ref = brothers
	_enemies_ref = enemies
	_start_new_round()

func current_actor() -> Variant:
	return queue[index] if index >= 0 and index < queue.size() else null

## Retourne vrai si l'acteur est un Frère Character Body 3D (BrotherCB3)
func is_player(actor : Variant) -> bool:
	return actor is BrotherCB3

## Passe à l'acteur suivant. Reconstruit un nouveau round si la queue est épuisée.
## Retourne le nouvel acteur courant.
func advance() -> Variant:
	_remove_dead()
	index += 1
	if index >= queue.size():
		_start_new_round()
		return current_actor()
	var actor = current_actor()
	turn_started.emit(actor)
	return actor

func _start_new_round() -> void:
	queue = _brothers_ref + _enemies_ref
	_remove_dead()
	queue.sort_custom(_by_speed_desc)
	index = -1
	round_started.emit()
	index += 1
	if queue.size() > 0:
		turn_started.emit(current_actor())

func _remove_dead() -> void:
	var alive : Array = []
	for actor in queue:
		if _is_alive(actor):
			alive.append(actor)
		else:
			actor_defeated.emit(actor)
	# Recalage de l'index si l'acteur courant a été retiré
	if index >= 0 and index < queue.size() and not _is_alive(queue[index]):
		index -= 1
	queue = alive

static func _by_speed_desc(a : Variant, b : Variant) -> bool:
	return _get_speed(a) > _get_speed(b)

static func _get_speed(actor : Variant) -> int:
	if actor is BrotherCB3:
		return actor.bro.speed
	return actor.stats.speed

static func _is_alive(actor : Variant) -> bool:
	if actor is BrotherCB3:
		return actor.bro.hp > 0
	return not actor.stats.is_dead()
