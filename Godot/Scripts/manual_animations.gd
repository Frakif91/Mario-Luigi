extends Node

class_name Actions

@export var ease_in_curve : Curve
@export var ease_out_curve : Curve

var mario_variable : BrotherCB3
var luigi_variable : BrotherCB3
var enemies_variable : Array[Node3D]
var ratings_variable : AnimationPlayer
var mario_anim : AnimationPlayer

var choosecube_visible : Callable

var is_debug = true
var damage_instance = preload("res://Godot/Nodes/damage_display.tscn")
var stop_animation = false

enum results {NONE,SUCESS,FAIL,GOOD}

@onready var animation_timer = Timer.new()

func _init(Mario : BrotherCB3, Luigi : BrotherCB3, Enemies : Array[Node3D], Ratings : AnimationPlayer, choosecube_visibility : Callable):
    mario_variable = Mario
    luigi_variable = Luigi
    enemies_variable = Enemies
    ratings_variable = Ratings
    choosecube_visible = choosecube_visibility

    print("Set Variables")
    #mario_anim = mario_variable.animated_sprite

func _init_animation(overrite : bool):
    var action_brother : BrotherCB3
    var og_position : Vector3
    var who_brother = Globals.cur_brother
    if who_brother == Globals.BROTHER.MARIO:
        print("Mario")
        action_brother = mario_variable
        og_position = Globals.MARIO.og_position
        Globals.MARIO.overrite_animation = overrite
    elif who_brother == Globals.BROTHER.LUIGI:
        print("Luigi")
        action_brother = luigi_variable
        og_position = Globals.LUIGI.og_position
        Globals.LUIGI.overrite_animation = overrite
    else:
        print("None")
        action_brother = mario_variable
        og_position = Globals.MARIO.og_position
    return [action_brother, og_position]


func _ready():
    animation_timer.one_shot = true
    add_child(animation_timer)

func get_percentage(value, min_value, max_value):
    return (value - min_value)/(max_value - min_value)

func get_percentage_value(value,min_value,max_value):
    return (value * (max_value - min_value)) + min_value

func _jump_manual_animation(enemy_position: Vector3):
    animation_timer.start(1.5)
    var total_time = 1.5
    var progression = 0
    var jump_minimal_window = 1.2
    var jump_minimal_good_window = 1.3
    var jump_maximal_window = 1.55
    var jump_maximal_good_window = 1.45
    var does_have_result = false
    var result

    var init_anima = _init_animation(true) 
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]

    while (animation_timer.time_left > 0 and not stop_animation):
        progression = total_time - animation_timer.time_left
        if (progression < 0.5):
            action_brother.animated_sprite.play(&"walking")
        if (progression > 0.5 and progression < 0.95):
            action_brother.animated_sprite.play(&"jump-up-right")
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0.5,0.95) ,0.5),og_position.y,1.7)
        if (progression > 0.95 and progression < 1.4):
            action_brother.animated_sprite.play(&"jump-down-right")
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0.95,1.4) ,2),1.5,enemy_position.y + 0.2)
        if (progression < 1.4):
            action_brother.animated_sprite.play(&"jump_on_enemy")
            action_brother.position.x = lerp(og_position.x,enemy_position.x,get_percentage(progression,0,1.4))
            action_brother.position.z = lerp(og_position.z,enemy_position.z,get_percentage(progression,0,1.4))
        if (progression > jump_minimal_window and progression < jump_maximal_window and not does_have_result):

            result = jump_check_hit(progression,jump_minimal_good_window,jump_maximal_good_window)
            if result:
                does_have_result = true
        await Globals.wait(0.001)
    if result:
        return result
    else:
        return results.FAIL
    #action_brother.position = og_position
    #_jump_disable_hit()

func jump_check_hit(progression,jump_minimal_good_window,jump_maximal_good_window):
    if Input.is_action_just_pressed("Jump"):
        print_debug("Sucess or not >>>  ",jump_minimal_good_window,"<",progression,"<",jump_maximal_good_window)
            #print("Test Variable", _jump_minimal_window, _jump_timing, _jump_maximal_window)
        if progression >= jump_minimal_good_window and progression <= jump_maximal_good_window:
            return results.SUCESS
        else:
            return results.FAIL
    else:
        if progression > jump_maximal_good_window:
            return results.FAIL
        else:
            return results.NONE
            
func result_todo(result):
    if result == results.SUCESS:
        if is_debug:
            print_debug("Sucess First Hit")
        show_damage(11, enemies_variable[0].position + Vector3(0.1 + randf() / 5., -0.3 + randf() / 5., 0), DamageAnouncerTexture.BackGroundTexture.DAMAGE)
        ratings_variable.play(&"Good")
        var resulta = await _double_jump_manual(enemies_variable[0].position)
        if resulta == results.SUCESS:
            if is_debug:
                print_debug("Sucess First Hit")
            show_damage(14, enemies_variable[0].position + Vector3(0.1 + randf() / 5., -0.3 + randf() / 5., 0), DamageAnouncerTexture.BackGroundTexture.DAMAGE)
            ratings_variable.play(&"Excellent")
            await _jump_manual_succesful()
        else:
            #await Globals.wait(max(jump_minimal_good_window - progression,0.001))
            print_debug("Failed")
            ratings_variable.play(&"Great")
            await fail_stomp()

    elif result == results.FAIL:
        #await Globals.wait(max(jump_minimal_good_window - progression,0.001))
        print_debug("Failed")
        ratings_variable.play(&"Ok")
        await fail_stomp()
        
    #region Jump

                    # if _jump_second_hit:
                    #     show_damage(13, $"Characters/Goomba".position + Vector3(0.05, -0.1, 0), DamageAnouncerTexture.BackGroundTexture.DAMAGE)
                    #     print_debug("Sucess Second Hit")
                    #     ratings_variable.play(&"Excellent")
                    #     _jump_can_hit = false
                    #     stop_animation = true
                    #     mario_anim.play(&"_jump_sucess")
                    #     await mario_anim.animation_finished
                    #     ratings_variable.play(&"RESET")
                    #     mario_anim.play(&"RESET")
                    #     choosecube_visible.call()
                    # else:

func _jump_disable_hit():
    print_debug("Disabled Hit")
    #assert(_jump_timing < _jump_minimal_window and _jump_timing > _jump_maximal_window,"In Hit Window >>>  " + str(_jump_minimal_window, "<", _jump_timing, "<", _jump_maximal_window) ) 
    await fail_stomp()

func show_damage(damage: int, posin3d: Vector3, damage_type: int):
    print("SHOWED")
    var di: DamageAnnouncer = damage_instance.instantiate()
    di.create(posin3d, damage, damage_type)
    ratings_variable.get_node(^"../..").add_child(di)
    di.show()
    di.showup()

var test1var = Vector3(0,0.4,0)
var test2var = Vector3(0.2,0.4,0)

func _input(_event):
    if Input.is_action_just_pressed(&"Test5"):
        mario_variable.position = enemies_variable[0].position + Vector3(0,0.3,0)
        await fail_stomp()
        choosecube_visible.call()
    if Input.is_action_just_pressed(&"Test6"):
        test2var = _init_animation(false)[1]
        mario_variable.position = test2var

func fail_stomp():
    animation_timer.start(2)
    var total_time = 2
    var progression = 0
    var step = 0
    var velocity_y = 2
    var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
    var init_anima = _init_animation(true) 
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]
    var cur_position : Vector3 = action_brother.position

    test1var = og_position
    test2var = cur_position

    while (animation_timer.time_left > 0 and not stop_animation):
        progression = total_time - animation_timer.time_left
        
        if (progression < 1.4):
            if step == 0:
                step = 1
                action_brother.animated_sprite.play(&"fall_back")
            action_brother.position.x = lerp(action_brother.position.x, og_position.x + (cur_position.x - og_position.x)/2,get_process_delta_time()*2)
            action_brother.position.z = lerp(action_brother.position.z, og_position.z + (cur_position.z - og_position.z)/2,get_process_delta_time()*2)
            if action_brother.position.y < 0.33:
                action_brother.animated_sprite.play(&"fall_back_on_floor")
                action_brother.position.y = 0.33
                velocity_y = get_percentage_value(get_percentage(1.4-progression,0,1.4),0.3,1.2)
            velocity_y -= get_process_delta_time() * 10
            action_brother.velocity.y = velocity_y
        if (progression > 1.4):
            if step == 1:
                step = 2
                cur_position = action_brother.position
                action_brother.animated_sprite.flip_h = true
                action_brother.animated_sprite.play(&"walking")
            action_brother.position.y = og_position.y
            action_brother.position.x = lerp(cur_position.x, og_position.x,get_percentage(progression,1.4,total_time))
            action_brother.position.z = lerp(cur_position.z, og_position.z,get_percentage(progression,1.4,total_time))
        await Globals.wait(0.001)
    action_brother.animated_sprite.flip_h = false


        # if (progression > 0.3 ):
        #     action_brother.animated_sprite.play(&"fall_back")
        #     action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0.5,0.95) ,0.5),og_position.y,1.5)
        # if (progression > 0.95 and progression < 1.4):
        #     action_brother.animated_sprite.play(&"fall_back_on_floor")
        #     action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0.95,1.4) ,2),1.5,enemy_position.y + 0.2)
        # if (progression < 1.4):
        #     action_brother.position.x = lerp(og_position.x,enemy_position.x,get_percentage(progression,0,total_time))
        #     action_brother.position.z = lerp(og_position.z,enemy_position.z,get_percentage(progression,0,total_time))
        #     action_brother.position.y += velocity_y
        # if (progression < 0.3):
        #     action_brother.animated_sprite.play(&"walking")
    await Globals.wait(0.001)
    action_brother.position = og_position
    choosecube_visible.call()
        
func _double_jump_manual(enemy_position : Vector3):
    animation_timer.start(1.15)
    #var total_time = 1.15
    var progression = 0
    var jump_minimal_window = 0.8
    var jump_minimal_good_window = 0.95
    var jump_maximal_window = 1.15
    var jump_maximal_good_window = 1.1
    var does_have_result = false
    var result

    var init_anima = _init_animation(true) 
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]
    var og_angle : float = 0

    action_brother.animated_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED

    while (animation_timer.time_left > 0 and not stop_animation):
        progression = animation_timer.wait_time - animation_timer.time_left

        if (progression < 0.3):
            action_brother.animated_sprite.play(&"jump-pirouette")
        elif (progression < 0.6):
            action_brother.animated_sprite.play(&"jump-pirouette2")
        elif (progression < 0.95):
            action_brother.animated_sprite.play(&"jump-second-falling")
        #jump_pirouette 0
        #jump_pirouette2 0.3
        #jump-second-falling 0.7
        if (progression < 0.5):
           # action_brother.animated_sprite.play(&"jump-up-right")
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0,0.5) ,0.5),og_position.y,2)
        if (progression > 0.5 and progression < 1.0):
            #action_brother.animated_sprite.play(&"jump-down-right")
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0.5,1) ,2),1.5,enemy_position.y + 0.2)
        if (progression < 0.95):
            action_brother.rotate_z(deg_to_rad(get_process_delta_time()*360))
        else:
            action_brother.rotation.z = og_angle


        # if (progression < 1.4):
        #     action_brother.position.x = lerp(og_position.x,enemy_position.x,get_percentage(progression,0,total_time))
        #     action_brother.position.z = lerp(og_position.z,enemy_position.z,get_percentage(progression,0,total_time))
        if (progression > 1):
            action_brother.animated_sprite.play(&"jump_on_enemy")
        if (progression > jump_minimal_window and progression < jump_maximal_window and not does_have_result):
            result = jump_check_hit(progression,jump_minimal_good_window,jump_maximal_good_window)
            if result:
                does_have_result = true
        await Globals.wait(0.001)
    if result:
        return result
    else:
        return results.FAIL

func _jump_manual_succesful():
    animation_timer.start(2.5)
    var total_time = 2.5
    var progression = 0
    var succes_anim_played = false

    var init_anima = _init_animation(true) 
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]
    var cur_position = action_brother.position

    action_brother.animated_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
    while (animation_timer.time_left > 0 and not stop_animation):
        progression = total_time - animation_timer.time_left
        if (progression < 0.5):
            action_brother.animated_sprite.play(&"jump-pirouette2")
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0,0.5) ,0.5),cur_position.y,1.5)
        elif (progression > 0.5 and progression < 1):
            action_brother.animated_sprite.play(&"jump-pirouette2")
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0.5,1) ,2),1.5,og_position.y)
        elif (progression < 1):
            action_brother.animated_sprite.play(&"jump_on_enemy")
            action_brother.rotation.z = lerp(0,360*3,get_percentage(progression,0,1))
            action_brother.position.x = lerp(cur_position.x,og_position.x,get_percentage(progression,0,1))
            action_brother.position.z = lerp(cur_position.z,og_position.z,get_percentage(progression,0,1))
        elif (progression > 1 and not succes_anim_played):
            succes_anim_played = true
            action_brother.animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
            action_brother.animated_sprite.play(&"jump-succesful")

        await Globals.wait(0.001)
        
func hammer_enable_hit():
    pass