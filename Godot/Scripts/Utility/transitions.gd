extends Control

@onready var anim : AnimationPlayer = $CanvasLayer/AnimationPlayer
@onready var label: Label = $CanvasLayer/Background/LoadingScreen/Label

enum TransitionType {CIRCULAR, FILL, TOP_DOWN}

func _enter_tree() -> void:
	get_tree().root.child_entered_tree.connect(func(b): get_tree().root.move_child.call_deferred(self,-1))

func _ready() -> void:
	#if get_tree().current_scene != self:
	#	process_mode = Node.PROCESS_MODE_DISABLED
	pass

func _process(_delta: float) -> void: 
	if Input.is_action_just_pressed("ui_accept") and get_tree().current_scene == self:
		print_debug("True Fake Test")
		start_loading("res://Godot/Scene/title.tscn",TransitionType.FILL,get_tree())
	if Input.is_action_just_pressed("ui_cancel") and get_tree().current_scene == self:
		print_debug("Fake Fake Test")
		start_fake_loading()

func start_fake_loading():
	
	anim.play(&"TransitionFill")
	await anim.animation_finished

	#Test // Start : loading screen
	for i in range(1,101):
		label.text = "Loading... " + str(i) + "%"
		await Globals.wait(0.03)
	#Test // End

	await Globals.wait(0.5)
	anim.play_backwards(&"TransitionFill")

func start_loading(path : String, transition_type : TransitionType, scene_tree : SceneTree):
	print_debug("Starting Transitioning to : " + path)
	anim.play(&"TransitionFill")
	await anim.animation_finished

	#Test // Start : loading screen
	var load_progression = []
	var status = ResourceLoader.load_threaded_request(path,"",false,ResourceLoader.CACHE_MODE_IGNORE)
	while(status != ResourceLoader.THREAD_LOAD_LOADED):
		await Globals.wait(0.01)
		status = ResourceLoader.load_threaded_get_status(path,load_progression)
		print_debug(load_progression)
		if typeof(load_progression[0]) == TYPE_FLOAT:
			label.text = "Loading... " + str(int(load_progression[0] * 100)) + "%"
		#await Globals.wait(0.01)
	assert(status == ResourceLoader.THREAD_LOAD_LOADED,"The while-loop exited without a proper loading !")
	label.text = "Entering Scene..."
	scene_tree.change_scene_to_packed(ResourceLoader.load_threaded_get(path))
	#Test // End

	await Globals.wait(0.5)
	anim.play_backwards(&"TransitionFill")
