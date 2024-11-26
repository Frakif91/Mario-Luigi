extends Node

var music : Dictionary = {
	"battle_theme" : preload("res://Assets/Music/Okey Dokey! DX - Mario and Luigi BIS DX .mp3"),
	"victory_theme" : preload("res://Assets/Music/Joyous Occasion - Mario & Luigi Dream Team Music.mp3"),
	"menu_theme" : preload("res://Assets/Music/Go with the Bros. - Mario & Luigi Dream Team Music Extended.mp3"),
	"multiplayer_scene_theme" : preload("res://Assets/Music/Dozing Sands Secret - Mario & Luigi Dream Team Music Extended.mp3"),
	"overworld_theme" : preload("res://Assets/Music/Breezy Mushrise Park - Mario & Luigi Dream Team Music Extended.mp3")
}

var settings : Dictionary = {
	"decal_shadows_allowed" = true,
	"debugger_actived" = true,
	"autoload_combat" = true,
}

func change_music(tag : String, new_music : AudioStream):
	if music.has(tag) and new_music is AudioStream:
		music[tag] = new_music

func change_global_music_volume(volume_percentage : float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),linear_to_db(volume_percentage))

func change_bus_volume_perc(bus_name : StringName, volume_percentage : float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name),linear_to_db(volume_percentage))

func loadsong(path : String) -> AudioStream:
	var import_success : bool = false
	var stream

	if path.ends_with(".mp3"):
		var snd_file = FileAccess.open(path, FileAccess.READ)
		stream = AudioStreamMP3.new()
		stream.data = snd_file.get_buffer(snd_file.get_length())
		import_success = true
		snd_file.close()
	if path.ends_with(".ogg"):
		var snd_file = FileAccess.open(path, FileAccess.READ)
		stream = AudioStreamOggVorbis.load_from_buffer(snd_file.get_buffer(snd_file.get_length()))
		snd_file.close()
		#stream = AudioStreamOggVorbis.new()
		#stream.load_from_file(path)
		import_success = true

	#lbl_title.text = path.get_file().get_basename().to_snake_case().capitalize()

	assert(import_success,"Importation of a external audio file was a failure")

	#print((stream as AudioStream)._get_stream_name())

	if import_success and stream:
		return stream
	return AudioStream.new()
