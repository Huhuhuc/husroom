class_name StateMachine


extends Node


var _current_state: int = -1
var current_state: int = -1 :
	set(v):
		if _current_state != v:
			owner.transition_state(_current_state, v)
		_current_state = v
	get:
		return _current_state


func _ready() -> void:
	# godot中子节点ready后父节点才ready，此处等待下一帧再执行后续代码
	print("StateMachine: waiting for next frame")
	await get_tree().process_frame
	print("StateMachine: setting initial state to 0")
	current_state = 0


func _physics_process(delta: float) -> void:
	while true:
		var next := owner.get_next_state(current_state) as int
		if current_state == next:
			break
		current_state = next
	
	owner.tick_physics(current_state,delta)
