extends Node3D

signal animation_called_event

#region Node References
@onready var choosecube : OptionBlocks = $"ChooseCube"
@onready var label : Label3D = $"ChooseCube/SoftBody3D/Label3D"
@onready var anima : AnimationPlayer = $AnimationPlayer
@onready var itemlist : Control = %ItemList
@onready var mario_anim = $"MarioAnimations"
@onready var ratings = $"UI/Ratings/RatingsAnim"
@onready var main_camera : BattleCamera = $"MainCamera"

@export var brothers_path : Dictionary = {"Mario" = ^"Characters/Mario", "Luigi" = ^"Characters/Luigi"}
var brothers : Dictionary[String, BrotherCB3] = {}
@export var enemies_path : Array[NodePath] = [^"Characters/Goomba", ^"Characters/Goomba2"]
var enemies : Array[EnemyUnit] = []
#endregion

#region Config / Constants
@export var transition_speed_multiplier = 1.0
@export var is_debug = true

var damage_instance = preload("res://Godot/Nodes/damage_display.tscn")
var jump_class = preload("res://Godot/Scripts/manual_animations.gd")
var turn_manager_class = preload("res://Godot/Scripts/TurnManager.gd")

var DEFAULT_CAM_TRANSFORM = CameraTransform.new()
@export var camera_transforms : Dictionary[String, CameraTransform] = {}
@export var animation_offsets : Dictionary[String, Vector2]
@export var chooseblock_global_of : Dictionary[String, Vector3]

var transition_direction = 1
var transition_time = 0.07

const JUMP_HIT_WINDOW := {"min" = 0.01, "max" = 0.09} # Conservé pour compat, plus vraiment utilisé (voir manual_animations.gd)
#endregion

#region State
@export var event_caller : float = 0.0 :
	set(id):
		if id == 24:
			animation_called_event.emit()
		event_caller = 0
		if id > 0 and id < 24:
			choosecube.set_global_transparence(id)

var cur_camera_pos = camera_transforms.get("OG")
var jump_process : Actions
var turn_manager : TurnManager

var cur_enemy : EnemyUnit
var cur_enemy_index := 0
#endregion


#region Lifecycle
func _ready() -> void:
	Debugger.add_text("rpg_state", "RPG State")
	Debugger.add_text("rpg_queue", "List of Ennemies")
	for enemie in enemies_path:
		enemies.append(get_node(enemie))
	for brother in brothers_path:
		brothers[brother] = get_node(brothers_path[brother])

	_init_targeting()
	Globals.cur_action = Globals.ACTIONS_BLOCKS.NONE
	Globals.eat_inventory_item.connect(brother_play_eat_anim)
	choosecube.hit_block.connect(hitting_block)
	choosecube.change_block.connect(changed_block)

	jump_process = jump_class.new(
		$"Characters/Mario", $"Characters/Luigi", enemies , $"UI/Ratings/RatingsAnim", set_visible_choosecube
	)
	add_child(jump_process)

	turn_manager = turn_manager_class.new()
	add_child(turn_manager)
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.round_started.connect(_on_round_started)
	turn_manager.actor_defeated.connect(_on_actor_defeated)

	label_change_effect_timer.autostart = false
	label_change_effect_timer.one_shot = true
	add_child(label_change_effect_timer)

	for bro : BrotherCB3 in brothers.values():
		bro.animated_sprite.offset = animation_offsets.get("idle", Vector2.ZERO)

	itemlist.set_deferred(&"size", Vector2(1152,648)) # In case of problems
	anima.play(&"show_itemlist")
	anima.advance(0.01)
	anima.stop()

	await Globals.wait(Globals.trans_ready_time + 0.5)

	# Démarre le combat : la queue est construite et triée par vitesse ici.
	turn_manager.setup(brothers.values(), enemies)

func _init_targeting() -> void:
	cur_enemy = enemies[0]
	$"Pointer".position = cur_enemy.position

func _process(_delta : float) -> void:
	if (label_change_effect_timer.time_left):
		label.position.y = label_change_effect_timer.time_left * transition_direction
		label.modulate.a = (transition_time - label_change_effect_timer.time_left) / transition_time * 5
	else:
		label.position.y = 0.0
		label.modulate.a = 1.0
	
	Debugger.modify_text("rpg_state", "RPG Actor : " + str(turn_manager.current_actor()))
	var turn_text = "RPG Turn Queue : "
	for actor in turn_manager.queue:
		turn_text += "\n" + ("O" if turn_manager.current_actor() == actor else "-") + "\t" + str(actor)

	Debugger.modify_text("rpg_queue", turn_text)

@onready var label_change_effect_timer := Timer.new()
#endregion


#region Turn Flow (TurnManager hooks)
## Appelé par TurnManager à chaque nouvel acteur (joueur OU ennemi).
## C'est LE point d'entrée unique du flux de combat maintenant.
func _on_turn_started(actor : Variant) -> void:
	if turn_manager.is_player(actor):
		change_character(actor)
		set_visible_choosecube()
	else:
		_enemy_take_turn(actor)

func _on_round_started() -> void:
	if is_debug:
		print_debug("--- Nouveau round --- ordre : ", turn_manager.queue)
	# TODO (optionnel) : régen légère de BP en début de round, effets de statut qui tick, etc.

func _on_actor_defeated(actor : Variant) -> void:
	if is_debug:
		print_debug("Acteur vaincu : ", actor)
	if not turn_manager.is_player(actor):
		(actor as EnemyUnit).visible = false
		# TODO : anim de KO ennemie, distribution xp_reward/coin_reward, vérifier victoire (enemies tous morts)
	else:
		# TODO : anim de KO du bro, vérifier défaite (les deux bros à 0 hp)
		pass

## STUB : logique d'attaque ennemie. Le vrai script custom par ennemi viendra ici,
## mais peut réutiliser les fonctions de timing/anim de manual_animations.gd (jump_process)
## de la même façon que _jump_manual_animation/_hammer_manual_animation le font pour le joueur.
func _enemy_take_turn(enemy : EnemyUnit) -> void:
	Globals.RPG.combat_state = Globals.RPG.combat_turn.ENEMY_ACTION
	$"Pointer".visible = false

	# TODO : choisir une cible (aléatoire / la plus faible / choix du script custom de l'ennemi)
	var target : BrotherCB3 = brothers.values().pick_random()

	# TODO : jouer l'anim de charge de `enemy`, positionner la caméra sur lui
	await Globals.wait(0.6) # placeholder, remplace par la vraie anim de charge

	# TODO : passer ici à Globals.RPG.combat_turn.PLAYER_DEFENDING et ouvrir une fenêtre
	#        de timing (même principe que jump_process.jump_check_hit) pour réduire les dégâts
	#        selon target.bro.defense / enemy.stats.can_defend-équivalent côté joueur.
	Globals.RPG.combat_state = Globals.RPG.combat_turn.ENEMY_ACTION

	# Dégâts fixes en attendant la vraie formule (attack - defense, cf. discussion précédente)
	target.bro.hp -= enemy.stats.attack
	if is_debug:
		print_debug(enemy.stats.enemy_name, " attaque ", target.bro.character_name, " pour ", enemy.stats.attack)

	turn_manager.advance()
#endregion


#region Inputs
func _input(_event) -> void:
	if Input.is_action_just_pressed(&"Back") and (Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_SELECTING or Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_MENU):
		$"BackSound".play()
		await set_visible_choosecube()

	if Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_SELECTING and Globals.cur_action == Globals.ACTIONS_BLOCKS.JUMP:
		_input_jump_selecting()

	if Globals.RPG.combat_state == Globals.RPG.combat_turn.PLAYER_SELECTING and Globals.cur_action == Globals.ACTIONS_BLOCKS.HAMMER:
		_input_hammer_selecting()

	if is_debug:
		_input_debug(_event)

func _input_jump_selecting() -> void:
	if Input.is_action_just_pressed(Globals.cur_brother.bro.action_button):
		Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_ACTION
		$"Pointer".visible = false
		var result : Actions.results = await jump_process._jump_manual_animation(cur_enemy.position, cur_enemy.animated_sprite)
		await jump_process.result_todo(result)
		_end_player_action()

	_input_target_switch()

func _input_hammer_selecting() -> void:
	if Input.is_action_just_pressed(Globals.cur_brother.bro.action_button):
		Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_ACTION
		$"Pointer".visible = false

		Globals.cur_brother.animated_sprite.offset = animation_offsets.get("hammer_taking_out", Vector2.ZERO)
		Globals.cur_brother.bro.overrite_animation = true
		var result : Actions.results = await jump_process._hammer_manual_animation(cur_enemy.position, cur_enemy.animated_sprite)

		match result:
			Actions.results.SUCESS:
				await jump_process._hammer_excellent()
			Actions.results.FAIL:
				await jump_process._hammer_good()
			_:
				await jump_process._hammer_bad()

		_end_player_action()

	_input_target_switch()

## Factorise la fin d'un tour joueur (jump ou hammer) : remise à zéro des flags d'anim
## + passage de la main au TurnManager (qui déclenchera le tour suivant via _on_turn_started).
func _end_player_action() -> void:
	for bro : BrotherCB3 in brothers.values():
		bro.bro.overrite_animation = false
	Globals.cur_brother.animated_sprite.offset = animation_offsets["idle"]
	turn_manager.advance()

func _input_target_switch() -> void:
	if Input.is_action_just_pressed(&"MenuDown"):
		cur_enemy_index = (cur_enemy_index + 1) % enemies.size()
		cur_enemy = enemies[cur_enemy_index]
		$"ChooseCube/SwitchSound".play()
		$"Pointer".position = cur_enemy.position
	if Input.is_action_just_pressed(&"MenuUp"):
		cur_enemy_index = wrapi(cur_enemy_index - 1, 0, enemies.size())
		cur_enemy = enemies[cur_enemy_index]
		$"ChooseCube/SwitchSound".play()
		$"Pointer".position = cur_enemy.position

## Inputs de test manuels (anims, changement de perso hors-tour...). Ne touchent pas au TurnManager.
func _input_debug(_event) -> void:
	if Input.is_action_just_pressed(&"Test4"):
		main_camera.target_position = camera_transforms.get("T_ENEMY")

	if Input.is_action_just_pressed(&"Test5"):
		Globals.cur_brother.bro.overrite_animation = true
		Globals.cur_brother.animated_sprite.offset = animation_offsets["idle"]
		$"MarioAnimations".play(&"victory")
		Globals.cur_brother.bro.overrite_animation = false
		Globals.cur_brother.animated_sprite.offset = animation_offsets["idle"]

	if Input.is_action_just_pressed(&"Test3"):
		Globals.cur_brother.animated_sprite.offset = animation_offsets["hammer"]
		Globals.cur_brother.bro.overrite_animation = true
		await jump_process._hammer_manual_animation(cur_enemy.position, cur_enemy.animated_sprite)
		Globals.cur_brother.bro.overrite_animation = false
		Globals.cur_brother.animated_sprite.offset = animation_offsets["idle"]
#endregion


#region Choosecube UI
func change_character(brother : BrotherCB3) -> void:
	Globals.cur_brother = brother
	main_camera.cur_transform = camera_transforms[Globals.cur_brother.bro.character_name]
	choosecube.position = chooseblock_global_of[Globals.cur_brother.bro.character_name]
	print("New Character", Globals.cur_brother.bro.character_name, " with cube pos : ", chooseblock_global_of[Globals.cur_brother.bro.character_name])

func hide_cubes(_speed_mult := 1.0):
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(choosecube, "position:y", chooseblock_global_of[Globals.cur_brother.bro.character_name].y + 2, 0.5 / _speed_mult).from(chooseblock_global_of[Globals.cur_brother.bro.character_name].y)
	await tween.finished

func show_cubes(_speed_mult := 1.0):
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(choosecube, "position:y", chooseblock_global_of[Globals.cur_brother.bro.character_name].y, 0.5 / _speed_mult).from(chooseblock_global_of[Globals.cur_brother.bro.character_name].y + 2)
	await tween.finished

func set_visible_choosecube() -> void:
	if Globals.is_itemlist_opened:
		anima.play_backwards(&"show_itemlist")
		Globals.is_itemlist_opened = false
		await anima.animation_finished

	main_camera.cur_transform = camera_transforms[Globals.cur_brother.bro.character_name]
	for bro : BrotherCB3 in brothers.values():
		bro.bro.overrite_animation = false
	Globals.cur_action = Globals.ACTIONS_BLOCKS.NONE
	$"Pointer".visible = false
	await show_cubes()
	choosecube.is_in_choosing_position = true
	for brother : BrotherCB3 in brothers.values():
		brother.bro.can_jump = true
	%AButton.show()
	Globals.chooseblocks_visible = true
	Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_CHOOSING

func changed_block(_curent_index : int, direction : int) -> void:
	label_change_effect_timer.start(transition_time)
	label_change_effect_timer.one_shot = true
	transition_direction = direction
	label.position.y = transition_time * direction
	label.modulate.a = 0
	label.text = choosecube.get_choose_cube_name()

func hitting_block() -> void:
	if Globals.RPG.combat_state != Globals.RPG.combat_turn.PLAYER_CHOOSING:
		return

	match choosecube.selected_block_name:
		"JUMP", "HAMMER":
			main_camera.cur_transform = camera_transforms.get("T_ENEMY", DEFAULT_CAM_TRANSFORM)
			Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_SELECTING
			choosecube.is_in_choosing_position = false
			Globals.cur_brother.bro.can_jump = false
			hide_cubes()
			$"Pointer".visible = true
		"ITEM":
			Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_MENU
			choosecube.is_in_choosing_position = false
			Globals.cur_brother.bro.can_jump = false
			hide_cubes(3)
			anima.play(&"show_itemlist")
			Globals.is_itemlist_opened = true
		_:
			$"InvalidSound".play()
			push_error(error_string(ERR_CANT_RESOLVE), " : Block \"{}\" not found".format([choosecube.selected_block_name], "{}"))
			return

	Globals.cur_action = choosecube.selected_block_index as Globals.ACTIONS_BLOCKS
	%AButton.visible = false
#endregion


#region Items
func brother_play_eat_anim(texture, uniqueitem) -> void:
	if Globals.is_itemlist_opened:
		Globals.is_itemlist_opened = false
		anima.play_backwards(&"show_itemlist")

	Globals.cur_brother.bro.overrite_animation = true
	Globals.RPG.combat_state = Globals.RPG.combat_turn.PLAYER_ACTION
	Globals.cur_brother.bro.can_jump = false
	$"MarioAnimations/Sprite3D".texture = texture
	await jump_process.eat_animation($"MarioAnimations/Sprite3D", $"MarioAnimations/HealSound", $"MarioAnimations/SpecialItem", itemlist.item_power_application, uniqueitem.item)
	Globals.cur_brother.bro.overrite_animation = false

	choosecube.is_in_choosing_position = true
	show_cubes()
	Globals.finish_eating.emit()

	# Manger un item ne fait plus partie du "tour d'action" bloquant : on redonne
	# la main au TurnManager comme pour jump/hammer.
	_end_player_action()
#endregion


#region Misc
func _on_animated_sprite_3d_animation_changed() -> void:
	$"Characters/Mario/AnimatedSprite3D".play(&"", 1., false) # Play animation when AnimationPlayer change AnimatedSprite's animation, because it's stops automaticly if it doesn't loop

func show_damage(damage : int, posin3d : Vector3, damage_type : int) -> void:
	var di : DamageAnnouncer = damage_instance.instantiate()
	di.create(posin3d, damage, damage_type)
	$"UI".add_child(di)
	di.show()
	di.showup()
#endregion
