extends AudioStreamPlayer

@export var music_name : StringName = ""
@export var fallback_music : AudioStream

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stop()
	if not music_name.is_empty():
		if GlobalSettings.music.has(music_name):
			self.stream = GlobalSettings.music.get(music_name)
		else:
			self.stream = fallback_music
	else:
		self.stream = fallback_music
	if self.autoplay:
		self.play()
