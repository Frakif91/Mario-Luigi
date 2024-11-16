## Promise is a Godot GDScript that can wait for multiple signals
class_name Promise extends Node

signal promised(succes : bool, args : Array)

var promises : Array[Signal]
var confirmed : Array[bool]
var timer : Timer

func _init(singal_array : Array[Signal], parent : Node = null) -> void:
	timer = Timer.new()
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	
	if parent:
		parent.add_child(self)
	
	if not promises.is_empty():
		for promise in promises:
			promise.connect(confirm_promise.bind(promise))
			confirmed.append(false)


func confirm_promise(arg0 = null, arg1 = null):
	var index : int
	var return_1 : bool = false
	if arg0 is Signal:
		index = promises.find(arg0)
	if arg1 is Signal:
		index = promises.find(arg1)
		return_1 = true
	
	if index != -1:
		confirmed[index] = true
	
	if not (false in confirmed):
		promised.emit(true, [arg0 if return_1 else null])
		queue_free() 
	
