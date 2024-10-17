extends Node

class_name Actions

@export var ease_in_curve : Curve
@export var ease_out_curve : Curve

var mario_variable : BrotherCB3
var luigi_variable : BrotherCB3
var enemies_variable : Array[Node3D]
var ratings_variable : AnimationPlayer
var mario_anim : AnimationPlayer
var cur_enemy_sprite : AnimatedSprite3D
var cur_targetted_enemy

const jump_sfx = preload("res://Assets/SFX/SML2_Jump.ogg")
const stomp_sfx = preload("res://Assets/Sound/SE_BTL_STOMP1.wav")
const run_sfx = preload("res://Assets/Sound/SE_BTL_RUN.wav")
const taking_out_sfx = preload("res://Assets/SFX/Mario_&_Luigi_PIT_Special_Item.ogg")
const recover_sfx = preload("res://Assets/SFX/Mario_&_Luigi_SS_&_BM_Heal.ogg")
const ass_on_floor_sfx = preload("res://Assets/Sound/SE_BTL_STOMP3.wav")
const hammer_takeout = preload("res://Assets/Sound/SE_BTL_HYOI.wav")
const hammer_charged = preload("res://Assets/Sound/SE_BTL_KIRARI.wav")
const hammer_go = preload("res://Assets/Sound/SE_BTL_ML_HAMMER_SHAKE.wav")
const hammer_hit = preload("res://Assets/Sound/SE_BTL_ML_HAMMER.wav")
const SFX : Dictionary = {JUMP = jump_sfx, STOMP = stomp_sfx, RUN = run_sfx, TAKEOUT = taking_out_sfx, RECOVER = recover_sfx, ASS = ass_on_floor_sfx}

@onready var audio_player : AudioStreamPlayer = AudioStreamPlayer.new()
func _play_audio(audio_file):
    audio_player.stream = audio_file
    audio_player.play()

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
    var action_brother : BrotherCB3 = Globals.cur_brother
    var og_position : Vector3 = Globals.cur_brother.og_position
    if overrite:
        Globals.cur_brother.bro.overrite_animation = true
    return [action_brother,og_position]

func do_in_sec(function : Callable, args : Array, sec : float):
    await Globals.wait(sec)
    function.callv(args)

func _ready():
    animation_timer.one_shot = true
    add_child(animation_timer)
    add_child(audio_player)

func get_percentage(value, min_value, max_value):
    return (value - min_value)/(max_value - min_value)

func get_percentage_value(value,min_value,max_value):
    return (value * (max_value - min_value)) + min_value

#region Shake
func shake_object(node : Node3D, power : float, sec : float):
    var og_pos = node.position
    var timer = Timer.new()
    #var fn : FastNoiseLite = FastNoiseLite.new()
    timer.autostart = false
    add_child(timer)
    timer.one_shot = true
    timer.start(sec)
    while(timer.time_left > 0):
        #var coord = fn.get_noise_2d(timer.time_left,timer.wait_time - timer.time_left)
        node.position = og_pos + Vector3(randf_range(-1,1),randf_range(-1,1),0)*power
        await Globals.wait(0.001)
    node.position = og_pos


#region Jump Manual
func _jump_manual_animation(enemy_position: Vector3, enemy_sprite : AnimatedSprite3D):
    var animation_speed = (1.1)**-1
    animation_timer.start(1.5*animation_speed)
    var total_time = 1.5
    var progression = 0
    var jump_minimal_window = 1.2
    var jump_minimal_good_window = 1.3
    var jump_maximal_window = 1.55
    var jump_maximal_good_window = 1.45
    var does_have_result = false
    var result
    cur_enemy_sprite = enemy_sprite
    var step : int = 0

    var init_anima = _init_animation(true) 
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]

    action_brother.animated_sprite.play(&"walking")
    _play_audio(SFX.RUN)
    while (animation_timer.time_left > 0 and not stop_animation):
        progression = (total_time - animation_timer.time_left/animation_speed)
        # if (progression < 0.5 and step):
        #     action_brother.animated_sprite.play(&"walking")
        if (progression > 0.5 and progression <= 0.95):
            if step == 0:
                step = 1
                action_brother.animated_sprite.play(&"jump-up-right")
                _play_audio(SFX.JUMP)
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0.5,0.95) ,0.5),og_position.y,1.7)
        if (progression > 0.95 and progression <= 1.4):
            if step == 1:
                step = 2
                action_brother.animated_sprite.play(&"jump-down-right")
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0.95,1.4) ,2),1.7,enemy_position.y + 0.2)
        if (progression < 1.4):            
            action_brother.position.x = lerp(og_position.x,enemy_position.x,get_percentage(progression,0,1.4))
            action_brother.position.z = lerp(og_position.z,enemy_position.z,get_percentage(progression,0,1.4))
        # elif (progression > 1.4 and step == 2):
        #     step = 3
            
        if (progression > jump_minimal_window and progression < jump_maximal_window and not does_have_result):
            if step == 2:
                step = 3
                action_brother.position.x = enemy_position.x
                action_brother.position.z = enemy_position.z
                action_brother.animated_sprite.play(&"jump_on_enemy")
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

#region Check Hit
func jump_check_hit(progression,jump_minimal_good_window,jump_maximal_good_window):
    if Input.is_action_just_pressed(Globals.cur_brother.bro.action_button):
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

# #region Bro Attack
# func bro1_multiple_jump_check(progression,jump_minimal_good_window,jump_maximal_good_window):
#     if Input.is_action_just_pressed(Globals.cur_brother.bro.action_button):
#         print_debug("Sucess or not >>>  ",jump_minimal_good_window,"<",progression,"<",jump_maximal_good_window)
#             #print("Test Variable", _jump_minimal_window, _jump_timing, _jump_maximal_window)
#         if progression >= jump_minimal_good_window and progression <= jump_maximal_good_window:
#             return results.SUCESS
#         else:
#             return results.FAIL
#     else:
#         if progression > jump_maximal_good_window:
#             return results.FAIL
#         else:
#             return results.NONE

#region Results    
func result_todo(result):
    if result == results.SUCESS:
        if is_debug:
            print_debug("Sucess First Hit")
        show_damage(11, enemies_variable[0].position + Vector3(0.1 + randf() / 5., -0.3 + randf() / 5., 0), DamageAnouncerTexture.BackGroundTexture.DAMAGE)
        shake_object(cur_enemy_sprite,0.05,0.1)
        cur_enemy_sprite.play(&"damage")
        do_in_sec(cur_enemy_sprite.play,[&"idle"],0.4)
        ratings_variable.play(&"Good")
        _play_audio(SFX.STOMP)
        var resulta = await _double_jump_manual(enemies_variable[0].position)
        if resulta == results.SUCESS:
            if is_debug:
                print_debug("Sucess First Hit")
            show_damage(14, enemies_variable[0].position + Vector3(0.1 + randf() / 5., -0.3 + randf() / 5., 0), DamageAnouncerTexture.BackGroundTexture.DAMAGE)
            ratings_variable.play(&"Excellent")
            shake_object(cur_enemy_sprite,0.07,0.2)
            cur_enemy_sprite.play(&"damage")
            do_in_sec(cur_enemy_sprite.play,[&"idle"],0.5)
            _play_audio(SFX.STOMP)
            await _jump_manual_succesful()
        else:
            #await Globals.wait(max(jump_minimal_good_window - progression,0.001))
            print_debug("Failed")
            ratings_variable.play(&"Ok")
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
    # if Input.is_action_just_pressed(&"Test5"):
    #     mario_variable.position = enemies_variable[0].position + Vector3(0,0.3,0)
    #     await fail_stomp()
    #     choosecube_visible.call()
    if Input.is_action_just_pressed(&"Test6"):
        test2var = _init_animation(false)[1]
        mario_variable.position = test2var

func fail_stomp():
    var animation_speed = (1.0)**-1
    animation_timer.start(2*animation_speed)
    var total_time = 2
    var progression = 0
    var step = 0
    var velocity_y = 2
    var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
    var init_anima = _init_animation(true) 
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]
    var cur_position : Vector3 = action_brother.position
    var max_assonfloor_sounds = 5

    test1var = og_position
    test2var = cur_position

    while (animation_timer.time_left > 0 and not stop_animation):
        progression = (total_time - animation_timer.time_left/animation_speed)
        
        if (progression < 1.4):
            if step == 0:
                step = 1
                action_brother.animated_sprite.play(&"fall_back")
            action_brother.position.x = lerp(action_brother.position.x, og_position.x + (cur_position.x - og_position.x)/2,get_process_delta_time()*2)
            action_brother.position.z = lerp(action_brother.position.z, og_position.z + (cur_position.z - og_position.z)/2,get_process_delta_time()*2)
            if action_brother.position.y < 0.33:
                action_brother.animated_sprite.play(&"fall_back_on_floor")
                action_brother.position.y = 0.33
                if max_assonfloor_sounds > 1:
                    _play_audio(SFX.ASS)
                    max_assonfloor_sounds -= 1
                velocity_y = get_percentage_value(get_percentage(1.4-progression,0,1.4),0.3,1.2)
            velocity_y -= get_process_delta_time() * 10
            action_brother.velocity.y = velocity_y
        if (progression > 1.4):
            if step == 1:
                step = 2
                cur_position = action_brother.position
                action_brother.animated_sprite.flip_h = true
                action_brother.animated_sprite.play(&"walking")
                _play_audio(SFX.RUN)
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
    var animation_speed = (1.1)**-1 #Animation speed = x1.1
    animation_timer.start(1.15*animation_speed)
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
        progression = (animation_timer.wait_time - animation_timer.time_left)/animation_speed

        if (progression < 0.3):
            action_brother.animated_sprite.play(&"jump_pirouette")
        elif (progression < 0.6):
            action_brother.animated_sprite.play(&"jump_pirouette2")
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
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0.5,1) ,2),2.0,enemy_position.y + 0.2)
        if (progression < 0.95):
            # action_brother.animated_sprite.rotate_z(deg_to_rad(get_process_delta_time()*(360/animation_speed)))
            action_brother.animated_sprite.rotation_degrees.z = clampf(get_percentage(progression,0,0.90)*360,0,360)
        else:
            action_brother.animated_sprite.rotation_degrees.z = og_angle


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

    action_brother.animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    if result:
        return result
    else:
        return results.FAIL

#region Jump Sucess
func _jump_manual_succesful():
    var animation_speed = (1.15)**-1
    animation_timer.start(2.6*animation_speed)
    var total_time = 2.6
    var progression = 0
    var succes_anim_played = false

    var init_anima = _init_animation(true) 
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]
    var cur_position = action_brother.position

    action_brother.animated_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
    while (animation_timer.time_left > 0 and not stop_animation):
        progression = total_time - animation_timer.time_left/animation_speed

        if (progression < 0.5):
            action_brother.animated_sprite.play(&"jump_pirouette2")
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0,0.5) ,0.5),cur_position.y,1.5)
        elif (progression > 0.5 and progression < 1):
            action_brother.animated_sprite.play(&"jump_pirouette2")
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0.5,1) ,2),1.5,og_position.y)
        if (progression < 1):
            action_brother.animated_sprite.play(&"jump_on_enemy")
            action_brother.animated_sprite.rotation.z = deg_to_rad(lerp(0,360*2,progression))
            action_brother.position.x = lerp(cur_position.x,og_position.x,get_percentage(progression,0,1))
            action_brother.position.z = lerp(cur_position.z,og_position.z,get_percentage(progression,0,1))
        elif (progression > 1 and not succes_anim_played):
            succes_anim_played = true
            action_brother.position.y = og_position.y
            action_brother.animated_sprite.rotation.z = 0
            action_brother.animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
            action_brother.animated_sprite.play(&"jump-succesful")

        await Globals.wait(0.001)
        
func hammer_enable_hit():
    pass

func eat_animation(sprite : Sprite3D, _heal_sfx : AudioStreamPlayer, show_sfx : AudioStreamPlayer, apply : Callable, item : UniqueItem):
    animation_timer.start(5.3)
    var total_time = 5.3
    var progression = 0
    var step : int = 0
    #var sprite_velocity = 0
 
    var init_anima = _init_animation(true) 
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]

    # Animation names :
    #   taking-out-item
    #   showing-item
    #   throwing_item_himself
    #   open-mouth
    #   close-mouth
    #   tummy
    sprite.position.x = og_position.x + 0.25
    sprite.position.y = og_position.y + 0.1
    sprite.position.z = og_position.z + (-0.001) #Be infront of the brother's sprite
    action_brother.animated_sprite.play(&"taking-out-item")
    while (animation_timer.time_left > 0 and not stop_animation):
        progression = total_time - animation_timer.time_left

        if (progression >= 0.9 and step == 0):
            step = 1
            action_brother.animated_sprite.play(&"showing-item")
            show_sfx.play()
            #_play_audio(SFX.TAKEOUT)
            sprite.show()
        elif (progression >= 1.8 and step == 1):
            step = 2
            action_brother.animated_sprite.play(&"throwing_item_himself")
            #sprite_velocity = 0.425/2 #0.425
            sprite.position.z = og_position.z
            
        elif (progression >= 2.2 and step == 2):
            step = 3
            action_brother.animated_sprite.play(&"open-mouth")
        elif (progression >= 2.63 and step == 3):
            step = 4
            action_brother.animated_sprite.play(&"close-mouth")
            sprite.hide()
        elif (progression >= 3.4 and step == 4):
            step = 5
            #heal_sfx.play()
            #_play_audio(SFX.RECOVER)
            apply.call(item)
            action_brother.animated_sprite.modulate = Color(0.6,0.6,1,1)
            #action_brother.animated_sprite.play(&"tummy")
            action_brother.animated_sprite.play(&"tummy")
        if (progression >= 4):
            action_brother.animated_sprite.modulate = lerp(action_brother.animated_sprite.modulate,Color(1,1,1,1),get_process_delta_time()*2)

        if (progression > 1.8 and progression < 2.65):
            sprite.position.x = og_position.x + get_percentage_value(get_percentage(progression,1.8,2.65),0.25,0.0)
            
        if (progression > 1.8 and progression < 2.225):
            #Throw up
            sprite.position.y = get_percentage_value(ease(get_percentage(progression,1.8,2.225) ,0.5),og_position.y,1.5)
        elif (progression > 2.225 and progression < 2.65):
            #Throw down
            sprite.position.y = get_percentage_value(ease(get_percentage(progression,2.225,2.65) ,2),1.5,og_position.y)

        await Globals.wait(0.00) #Await -> Go on Idle...


#region Hammer
func _hammer_manual_animation(enemy_position: Vector3, enemy_sprite : AnimatedSprite3D):
    #0.8 hammer_walk
    #1.9 hammer_ready
    #2.3 hammer_charge
    #3.2 hammer_readystand
    var animation_speed = (1.1)**-1
    animation_timer.start(3.7*animation_speed)
    var total_time = 3.5
    var progression = 0
    var hammer_minimal_window = 2.5
    var hammer_minimal_good_window = 3.1
    var hammer_maximal_window = 3.3
    var hammer_maximal_good_window = 3.3
    var does_have_result = false
    var result
    cur_enemy_sprite = enemy_sprite
    var step : int = 0

    var init_anima = _init_animation(true) 
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]

    action_brother.animated_sprite.play(&"hammer_taking_out")
    _play_audio(hammer_takeout)
    while (animation_timer.time_left > 0 and not stop_animation):
        progression = (total_time - animation_timer.time_left/animation_speed)

        if (progression > 0.8 and progression < 1.9):
            action_brother.position.x = lerp(og_position.x,enemy_position.x - 0.3,get_percentage(progression,0.8,1.9))
            action_brother.position.z = lerp(og_position.z,enemy_position.z,get_percentage(progression,0.8,1.9))
        
        if (step == 0 and progression > 0.8):
            step = 1
            action_brother.animated_sprite.play(&"hammer_walk")
            #action_brother.animated_sprite.play(&"hammer_ready")
            _play_audio(SFX.RUN)

        elif (step == 1 and progression > 1.9):
            step = 2
            action_brother.animated_sprite.play(&"hammer_start_charge")
            action_brother.position.z -= 0.01 #Stay infront of enemy
            _play_audio(hammer_go)
        elif (step == 2 and progression > 2.3):
            step = 3
            action_brother.animated_sprite.play(&"hammer_charge")
        elif (step == 3 and progression > 2.5):
            step = 4
            audio_player.pitch_scale = 0.9
            _play_audio(hammer_charged)

        elif (step == 4 and progression > 2.8):
            step = 5
            audio_player.pitch_scale = 0.95
            _play_audio(hammer_charged)

        elif (step == 5 and progression > hammer_minimal_good_window):
            step = 6
            audio_player.pitch_scale = 1.0
            _play_audio(hammer_charged)
            action_brother.animated_sprite.play(&"hammer_charged")

        if (progression > hammer_minimal_window and progression < hammer_maximal_window and not does_have_result):
            result = jump_check_hit(progression,hammer_minimal_good_window,hammer_maximal_good_window)
            if result:
                return result
        
        if (progression > hammer_maximal_window):
            return Actions.results.NONE

        await Globals.wait(0.001)

func _hammer_bad():
    _play_audio(hammer_go)
    Globals.cur_brother.animated_sprite.play(&"hammer_fail")
    await Globals.wait(0.05)
    #await Globals.cur_brother.animated_sprite.animation_finished
    show_damage(2, enemies_variable[0].position + Vector3(0.1 + randf() / 5., -0.3 + randf() / 5., 0), DamageAnouncerTexture.BackGroundTexture.DAMAGE)
    ratings_variable.play(&"Ok")
    shake_object(cur_enemy_sprite,0.07,0.2)
    #Globals.cur_brother.animated_sprite.play(&"hammer_failstand")
    await Globals.cur_brother.animated_sprite.animation_finished

    await Globals.wait(0.1)
    Globals.cur_brother.animated_sprite.play(&"walking")
    Globals.cur_brother.animated_sprite.flip_h = true
    _play_audio(SFX.RUN)

    animation_timer.start(0.8)
    var total_time = 0.8
    var init_anima = _init_animation(true)
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]
    var cur_position = action_brother.position
    while (animation_timer.time_left > 0 and not stop_animation):
        var progression = (total_time - animation_timer.time_left)
        if (progression < 0.8):
            action_brother.position.x = lerp(cur_position.x,og_position.x,get_percentage(progression,0,0.8))
            action_brother.position.z = lerp(cur_position.z,og_position.z,get_percentage(progression,0,0.8))
        await Globals.wait(0.001)
    Globals.cur_brother.animated_sprite.flip_h = false

func _hammer_good():
    _play_audio(hammer_go)
    Globals.cur_brother.animated_sprite.play(&"hammer_attack")
    await Globals.cur_brother.animated_sprite.animation_finished
    _play_audio(hammer_hit)
    show_damage(14, enemies_variable[0].position + Vector3(0.1 + randf() / 5., -0.3 + randf() / 5., 0), DamageAnouncerTexture.BackGroundTexture.DAMAGE)
    ratings_variable.play(&"Good")
    shake_object(cur_enemy_sprite,0.07,0.4)
    Globals.cur_brother.animated_sprite.play(&"hammer_attack_stand")
    await Globals.cur_brother.animated_sprite.animation_finished
    Globals.cur_brother.animated_sprite.play(&"hammer_attack_stand")
    await Globals.cur_brother.animated_sprite.animation_finished
    Globals.cur_brother.animated_sprite.play(&"hammer_stop")
    await Globals.cur_brother.animated_sprite.animation_finished

    await Globals.wait(0.1)
    Globals.cur_brother.animated_sprite.play(&"walking")
    Globals.cur_brother.animated_sprite.flip_h = true
    _play_audio(SFX.RUN)

    animation_timer.start(0.8)
    var total_time = 0.8
    var init_anima = _init_animation(true)
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]
    var cur_position = action_brother.position
    while (animation_timer.time_left > 0 and not stop_animation):
        var progression = (total_time - animation_timer.time_left)
        if (progression < 0.8):
            action_brother.position.x = lerp(cur_position.x,og_position.x,get_percentage(progression,0,0.8))
            action_brother.position.z = lerp(cur_position.z,og_position.z,get_percentage(progression,0,0.8))
        await Globals.wait(0.001)
    Globals.cur_brother.animated_sprite.flip_h = false
        

func _hammer_excellent():
    audio_player.pitch_scale = 1.1
    (get_viewport().get_camera_3d() as BattleCamera).target_position = Globals.cur_brother.position + Vector3(0,0.7,1)
    _play_audio(preload("res://Assets/SFX/hammershine.wav"))
    for o in range(4):
        Globals.cur_brother.animated_sprite.play(&"hammer_charged")
        await Globals.cur_brother.animated_sprite.animation_finished
    _play_audio(hammer_go)
    Globals.cur_brother.animated_sprite.play(&"hammer_exellent_attack")
    await Globals.cur_brother.animated_sprite.animation_finished
    
    _play_audio(hammer_hit)
    show_damage(20, enemies_variable[0].position + Vector3(0.1 + randf() / 5., -0.3 + randf() / 5., 0), DamageAnouncerTexture.BackGroundTexture.DAMAGE)
    ratings_variable.play(&"Excellent")
    shake_object(cur_enemy_sprite,0.07,0.4)
    (get_viewport().get_camera_3d() as BattleCamera).shake_camera(0.1,0.3)

    for o in range(3):
        Globals.cur_brother.animated_sprite.play(&"hammer_attack_stand")
        await Globals.cur_brother.animated_sprite.animation_finished
    Globals.cur_brother.animated_sprite.play(&"hammer_stop")
    await Globals.cur_brother.animated_sprite.animation_finished
    await Globals.wait(0.1)
    (get_viewport().get_camera_3d() as BattleCamera).target_position = Globals.cur_brother.bro.camera_position
    Globals.cur_brother.animated_sprite.play(&"walking")
    Globals.cur_brother.animated_sprite.flip_h = true
    _play_audio(SFX.RUN)

    animation_timer.start(0.8)
    var total_time = 0.8
    var init_anima = _init_animation(true)
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]
    var cur_position = action_brother.position
    while (animation_timer.time_left > 0 and not stop_animation):
        var progression = (total_time - animation_timer.time_left)
        if (progression < 0.8):
            action_brother.position.x = lerp(cur_position.x,og_position.x,get_percentage(progression,0,0.8))
            action_brother.position.z = lerp(cur_position.z,og_position.z,get_percentage(progression,0,0.8))
        await Globals.wait(0.001)
    Globals.cur_brother.animated_sprite.flip_h = false
    #     if (progression > hammer_minimal_window and progression < hammer_maximal_window and not does_have_result):
    #         if step == 2:
    #             step = 3
    #             action_brother.animated_sprite.play(&"jump_on_enemy")
    #         result = jump_check_hit(progression,hammer_minimal_good_window,hammer_maximal_good_window)
    #         if result:
    #             does_have_result = true
    #     await Globals.wait(0.001)
    # if result:
    #     return result
    # else:
    #     return results.FAIL
    #action_brother.position = og_position
    #_jump_disable_hit()

func _victory_screen():
    animation_timer.start(2)
    var total_time = 0.8
    var init_anima = _init_animation(true)
    var action_brother : BrotherCB3 = init_anima[0]
    var og_position : Vector3 = init_anima[1]
    #var cur_position = action_brother.position
    var target_position = get_viewport().get_camera_3d().position
    target_position.z = 0
    action_brother.animated_sprite.play("victory")
    while (animation_timer.time_left > 0 and not stop_animation):
        var progression = (total_time - animation_timer.time_left)

        if (progression <= 0.3):
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0,0.3) ,0.5),og_position.y,1.5)
        if (progression > 0.3 and progression <= 0.6):
            action_brother.position.y = get_percentage_value(ease(get_percentage(progression,0.3,0.6) ,2),1.5,og_position.y + 0.5)

        if (progression >= 0.6):
            action_brother.position.x = lerp(og_position.x,target_position.x,get_percentage(progression,0,0.6))
            action_brother.position.z = lerp(og_position.z,target_position.z,get_percentage(progression,0,0.6))
        
        await Globals.wait(0.001)