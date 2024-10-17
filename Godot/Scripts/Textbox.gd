extends Control

signal show_dialog()

@onready var text_label : Label = $"MarginContainer/NTL/Label"
@onready var text_box : NinePatchRect = $"MarginContainer/NTL"
@onready var dialog_char : AudioStreamPlayer = $"DialogSFX"
@onready var dialog_next : AudioStreamPlayer = $"EnterSFX"

@onready var dialog_fields : Array[DialogField]

const start_animation_seconds = 0.5
const each_animation_second = 0.5

func _ready() -> void:
	text_box.modulate = Color(1,1,1,0)
	text_box.custom_minimum_size = Vector2(100,100)
	show_dialog.connect(_show_dialog)

func _show_dialog():
	assert(len(dialog_fields) > 0,"Dialog Fields is empty.")
	var tween_modulate : Tween = create_tween()
	var size_modulate : Tween = create_tween()
	tween_modulate.tween_property(text_box,^"modulate", Color(1,1,1,1),start_animation_seconds)
	tween_modulate.tween_property(text_box,^"custom_minimum_size", dialog_fields[0].textbox_size,start_animation_seconds)

	for dialog in dialog_fields:
		if dialog.textbox_size != text_box.custom_minimum_size:
			var pptwn =	tween_modulate.tween_property(text_box,^"custom_minimum_size", dialog_fields[0].textbox_size,each_animation_second)
			var cur_text = ""
			for letter in dialog.text:
				cur_text += letter
				dialog_char.stop()
				dialog_char.play()
				text_label.text = cur_text
				await Globals.wait(dialog.text_delay)
			while not Input.is_action_just_pressed("ui_accept"):
				await Globals.next_frame()
			