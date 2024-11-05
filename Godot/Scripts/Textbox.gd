extends Control

signal show_dialog()
signal finished_dialog()
signal dialog_nextline()

@onready var text_label : Label = $"MarginContainer/NTL/Clip/Label"
@onready var text_box : NinePatchRect = $"MarginContainer/NTL"
@onready var dialog_char_sfx : AudioStreamPlayer = $"DialogSFX"
@onready var dialog_next_sfx : AudioStreamPlayer = $"EnterSFX"

const minimum_minimum_box_size = Vector2(100,75)
const normal_position = Vector2(6,3)

@export var dialog_fields : Array[DialogField]

const start_animation_seconds = 0.5
const each_animation_second = 0.5
const end_animation_seconds = 0.3

func _ready() -> void:
	text_box.modulate = Color(1,1,1,0)
	text_box.custom_minimum_size = minimum_minimum_box_size
	show_dialog.connect(_show_dialog)

	if get_tree().current_scene == self: #If game is launched on Textbox -> Debug
		_show_dialog()


func _show_dialog():
	assert(len(dialog_fields) > 0,"Dialog Fields is empty.")
	var tween_modulate : Tween = create_tween()
	var size_modulate : Tween = create_tween()
	text_label.text = ""
	tween_modulate.tween_property(text_box,^"modulate", Color(1,1,1,1),start_animation_seconds)
	size_modulate.tween_property(text_box,^"custom_minimum_size", dialog_fields[0].textbox_size,start_animation_seconds)
	await Globals.wait(start_animation_seconds)

	for dialog in dialog_fields:

		if dialog.text_size != 0:
			text_label.label_settings.font_size = dialog.text_size

		if dialog.sfx:
			dialog_char_sfx.stream = dialog.sfx

		if dialog.textbox_size != text_box.custom_minimum_size:
			print("Changing textbox size")
			await create_tween().tween_property(text_box,^"custom_minimum_size", dialog.textbox_size,each_animation_second).finished

		text_label.text = dialog.text
		for letter in range(1,len(dialog.text) + 1):
			text_label.visible_characters = letter
			if (letter % dialog.each_n_letters) == 0:
				dialog_char_sfx.stop()
				dialog_char_sfx.play()
			await Globals.wait(dialog.text_delay)
		text_label.visible_characters = -1
		
		while not Input.is_action_just_pressed("ui_accept"):
			await Globals.next_frame()
		
		dialog_nextline.emit()
		dialog_next_sfx.play()
		await create_tween().tween_property(text_label,^"position",Vector2(6,-100),0.3).finished
		text_label.position = normal_position
		text_label.visible_characters = 0
	
	create_tween().tween_property(text_box,^"modulate", Color(1,1,1,0),end_animation_seconds)
	create_tween().tween_property(text_box,^"custom_minimum_size", minimum_minimum_box_size,end_animation_seconds + 0.1)
	await Globals.wait(end_animation_seconds)
	finished_dialog.emit()