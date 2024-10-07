extends Node

var music : Dictionary = {
	"battle_theme" : preload("res://Assets/Music/Okey Dokey! DX - Mario and Luigi BIS DX .mp3"),
	"victory_theme" : preload("res://Assets/Music/Joyous Occasion - Mario & Luigi Dream Team Music.mp3"),
	"menu_theme" : preload("res://Assets/Music/Go with the Bros. - Mario & Luigi Dream Team Music Extended.mp3"),
	"multiplayer_scene_theme" : preload("res://Assets/Music/Dozing Sands Secret - Mario & Luigi Dream Team Music Extended.mp3")
}

func change_music(tag : String, new_music : AudioStream):
	if music.has(tag) and new_music is AudioStream:
		music[tag] = new_music

func change_global_music_volume(volume_percentage : float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),linear_to_db(volume_percentage))

func change_bus_volume_perc(bus_name : StringName, volume_percentage : float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),linear_to_db(volume_percentage))
