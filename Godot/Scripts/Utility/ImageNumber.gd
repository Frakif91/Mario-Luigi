@tool
extends Control

class_name TextureNumber

signal value_changed(old_value: int, new_value: int)
@warning_ignore("unused_signal")
signal on_reset()

@onready var number_container : BoxContainer = BoxContainer.new()

@export var Numbers: Array[Texture2D]
@export_range(1, 10, 1) var max_number: int = 10 : 
    set(n_value):
        max_number = n_value
        update()

@export_range(1, 4, 1) var max_slot: int = 3
@export var do_hide_zero: bool = false
@export var alignement = BoxContainer.ALIGNMENT_END :
    set(value): alignement = value ; update()
@export var vertical : bool = false :
    set(value): vertical = value ; update()
@export var spacing : int = 1 :
    set(value): spacing = value ; update()
@export var number_offset : Vector2 = Vector2(0,0) : 
    set(value): number_offset = value ; update()
@export var value: int = 169:
    set(new_value):
        var old_value = value ; value = new_value ; value_changed.emit(old_value, new_value) ; update()
        
@export var images_slot : Array[Texture2D] = []

var is_debug = false

func set_value(new_value):
    value = new_value

func _ready():
    number_container.name = "BoxContainer"
    number_container.layout_direction = Control.LAYOUT_DIRECTION_RTL
    #await Globals.wait(0.01)
    for tex in range(max_slot):
         number_container.add_child(TextureRect.new())
    add_child(number_container) # i forgot 💀
    reset()
    update()
    number_container.ready.connect(update)

func reset():
    images_slot.clear()
    for image in range(max_slot):
        images_slot.append(PlaceholderTexture2D.new())

    # for child in number_container.get_children():
    #     child.free()
    
    # for tex in range(max_slot):
    #     number_container.add_child(TextureRect.new())
    
    #number_container.remove_theme_constant_override()
    number_container.add_theme_constant_override(&"separation",spacing)

func image_refresh():
    for number in range(max_slot):
        var texturerect = number_container.get_child(number)
        texturerect.texture = images_slot[number]
        texturerect.custom_minimum_size = Numbers[number].get_size() + number_offset
        texturerect.show()     #...then its adios

func update():
    
    # update() is called before _ready()
    if not number_container:
        return
    if not number_container.is_node_ready():
        return #If it's not ready, then don't start to create problems
               #All people, in their life, need some time before big events start
               #Anyway, i'm going back to sleep
    reset()
    if is_debug:
        print("Max Slot : ",max_slot)
        #print("Images count : ",images_slot.size())
        print_debug("BoxContainer's child(s) : ",number_container.get_child_count())

    for slot in range(max_slot):
        @warning_ignore("integer_division")
        var image_number = floor((value / (10**slot)) % Numbers.size())
        if is_debug:
            print("Update, Number image for slot n°{0} is {1} and of size : {2}".format([slot,image_number,Numbers[image_number].get_size()]))
        images_slot[slot] = Numbers[image_number]

    image_refresh()
    

    if do_hide_zero:
        for number in range(max_slot - 1, 0, -1): # Going from 100 to 10... but don't hide 1 if value is 0
            if images_slot[number] == Numbers[0]:            #if it's 0...
                number_container.get_child(number).hide()     #...then its adios
            else:
                return
            



# match(max_slot):
#         1:
#             images_slot[0] = Numbers[value % 10]
#         2:
#             if (value < 10):
#                 images_slot[0] = Numbers[value]
#                 images_slot[1] = Numbers[0]
#             else:
#                 images_slot[0] = Numbers[value % 10]
#                 @warning_ignore("integer_division")
#                 images_slot[1] = Numbers[floor(value % 10 / 10)]

#             if do_hide_zero:
#                 if (value < 10):
#                     images_slot[1].visible = false
#                 else:
#                     images_slot[1].visible = true
#         3: