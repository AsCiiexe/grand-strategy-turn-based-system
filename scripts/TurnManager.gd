extends Node2D

onready var pathfindingMap = get_parent().get_node("PathfindingMap")
onready var timer = get_node("Timer")
var turn = 0
var turn_speed = 2 setget set_turn_speed #change this on _ready if you want a different default turn_speed
var max_turn_speed = 4
var min_turn_speed = 1

var currently_working = [] #list of all objects to be updated at every turn progress


func _ready():
	timer.connect("timeout", self, "_on_Timer_timeout")
	timer.start()
	timer.set_paused(true)



func _unhandled_input(event):
	if event.is_action_pressed("pause"):#toggle pause (space)
		if timer.is_paused():
			print("continue")
			timer.set_paused(false)
		else:
			print("pause")
			timer.set_paused(true)
	
	if event.is_action_pressed("speed_up"):#raise turn speed (F2)
		self.turn_speed += 1
		print("turn speed = ", turn_speed)
	
	if event.is_action_pressed("slow_down"):#lower turn speed (F1)
		self.turn_speed -= 1
		print("turn speed = ", turn_speed)



func set_turn_speed(new_speed):
	turn_speed = new_speed
	if turn_speed > max_turn_speed:
		turn_speed = max_turn_speed
	if turn_speed < min_turn_speed:
		turn_speed = min_turn_speed
	match turn_speed:
		1:
			timer.set_wait_time(2.25)
		2:
			timer.set_wait_time(1)
		3:
			timer.set_wait_time(0.5)
		4:
			timer.set_wait_time(0.2)
		_:
			timer.set_wait_time(1)
			print("ERROR: UNRECOGNISED TURN SPEED")



func _on_Timer_timeout():
	turn += 1
	print("turn ", turn)
	next_turn()



func next_turn():
	for entity in currently_working:
		entity.update_turn()
	pathfindingMap.update()



#adds (object) to progress list so it’s called every turn to update its turn progresses
func append_to_working_list(object):
	#check if it's already on the list, otherwise it would be called multiple times
	if currently_working.find(object) == -1:
		currently_working.append(object)



#removes (object) from progress list so it’s not called anymore
func erase_from_working_list(object):
	currently_working.erase(object)
