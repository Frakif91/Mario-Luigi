class_name SceneProperties extends Node

@export var scene_name = ""
@export var scene_description = ""
@export_node_path("AudioStreamPlayer") var background_music_np
@onready var background_music : AudioStreamPlayer = get_node(background_music_np)


func start_background_music():
    background_music.start()
func stop_background_music():
    background_music.stop()