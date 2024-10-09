extends Control

@onready var transition : TextureRect = $"Transitions"
@onready var transition_gradient : GradientTexture2D = get_node_and_resource(^"Transitions:texture")[1]
@onready var anim : AnimationPlayer = $"AnimationPlayer"
@onready var loading_anim : AnimationPlayer = $"Transitions/Background/LoadingScreen/Animation"
@onready var loading : Control = $"Transitions/Background/LoadingScreen"

enum TransitionType {CIRCULAR}

@export var gradient_1_progression : float = 0 :
	set(value):
		gradient_2_progression = value
		if transition_gradient:
			transition_gradient.gradient.set_offset(0,value)
@export var gradient_2_progression : float = 0 :
	set(value):
		gradient_2_progression = value
		if transition_gradient:
			transition_gradient.gradient.set_offset(1,value)

func _ready() -> void:
	#start_fake_loading()
	pass

func start_fake_loading():
	anim.play(&"TransitionIn")
	await anim.animation_finished
	loading.start_loading.emit()
	await Globals.wait(1)

	#Test // Start : loading screen
	for i in range(1,101):
		loading.update_progression.emit(float(i)/100.0)
		await Globals.wait(0.03)
	#Test // End

	await Globals.wait(0.5)
	loading.end_loading.emit()
	await Globals.wait(0.5)
	anim.play_backwards(&"TransitionIn")

func start_loading(path : String, transition_type : TransitionType, scene_tree : SceneTree, loading_screen : bool = true):
	if transition_type == TransitionType.CIRCULAR:
		anim.play(&"TransitionIn")
		await anim.animation_finished
	if loading_screen:
		loading.start_loading.emit()
		await Globals.wait(1)

	if loading_screen:
		#Test // Start : loading screen
		var load_progression = []
		loading.set_custom_load_message("Loading...")
		var status = ResourceLoader.load_threaded_request(path,"",false,ResourceLoader.CACHE_MODE_REPLACE_DEEP)
		while(status != ResourceLoader.THREAD_LOAD_LOADED):
			await Globals.wait(0.01)
			status = ResourceLoader.load_threaded_get_status(path,load_progression)
			print_debug(load_progression)
			if typeof(load_progression[0]) == TYPE_FLOAT:
				loading.update_progression.emit(load_progression[0])
			#await Globals.wait(0.01)
		assert(status == ResourceLoader.THREAD_LOAD_LOADED,"The while-loop exited without a proper loading !")
		loading.set_custom_load_message("Entering Scene...")
		scene_tree.change_scene_to_packed(ResourceLoader.load_threaded_get(path))
		#Test // End
	else:
		if path.is_empty():
			scene_tree.reload_current_scene()
		else:
			ResourceLoader.load_threaded_request(path,"tscn",true,ResourceLoader.CACHE_MODE_IGNORE_DEEP)
			scene_tree.change_scene_to_packed(ResourceLoader.load_threaded_get(path))

	if loading_screen:
		await Globals.wait(0.5)
		loading.end_loading.emit()
		await Globals.wait(0.5)
	if transition_type == TransitionType.CIRCULAR:
		anim.play_backwards(&"TransitionIn")