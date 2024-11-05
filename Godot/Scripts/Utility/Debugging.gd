extends Control

var debug_text : Dictionary

var debug_scene = preload("res://Godot/Nodes/Utility/debugging_scene.tscn")
@onready var debug_holder = $"DebuggingScene/MarginContainer/PanelContainer/MarginContainer/RichTextLabel"

func _enter_tree() -> void:
    add_child(debug_scene.instantiate())

func add_text(tag : StringName, placeholder_text : String):
    if not debug_text.has(tag):
        debug_text.merge({tag:placeholder_text})
        update_text()

func delete_text(tag : StringName):
    if debug_text.has(tag):
        debug_text.erase(tag)
        update_text()

func modify_text(tag : StringName, text : String):
    if debug_text.has(tag):
        debug_text.merge({tag:text},true)
        update_text()

func update_text():
    if debug_holder:
        (debug_holder as RichTextLabel).text = " \n".join(debug_text.values())

# func _process(_delta):
#     update_text()