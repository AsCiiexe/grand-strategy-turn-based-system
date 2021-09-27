extends Node2D

onready var pathfindingMap = get_tree().get_root().get_node("Main/PathfindingMap")
onready var HUD = get_tree().get_root().get_node("Main/CanvasLayer")
onready var timer = get_node("Timer")
var turn = 0
var turn_speed = 2 setget set_turn_speed #change this on _ready if you want a different default turn_speed
var max_turn_speed = 4
var min_turn_speed = 1

var currently_working = [] #list of all objects to be updated at every turn progress
var append_queue = [] #queue of entities that want to join the currently_working list
var erase_queue = [] #queue of entities that want to leave the currently_working list
#changing stuff from the currently_working list while it's running can mess up a ton of stuff
#so it's only changeable when it's not being looped


func _ready():
	timer.connect("timeout", self, "_on_Timer_timeout")
	timer.start()
	timer.set_paused(true)



func _unhandled_input(event):
	if event.is_action_pressed("pause"):#toggle pause (space)
		
		if timer.is_paused():
			print("continue")
			timer.set_paused(false)
			HUD.set_time_sprite("play")
		else:
			print("pause")
			timer.set_paused(true)
			HUD.set_time_sprite("pause")
	
	if event.is_action_pressed("speed_up"):#raise turn speed (F2)
		self.turn_speed += 1
	
	if event.is_action_pressed("slow_down"):#lower turn speed (F1)
		self.turn_speed -= 1

func set_turn_speed(new_speed):
	turn_speed = new_speed
	turn_speed = clamp(turn_speed, min_turn_speed, max_turn_speed)
	var time_percent = timer.time_left / timer.wait_time
	
	#if the player constantly changes time it still will progress with this
	match turn_speed:
		1:
			timer.start(1.75 * time_percent)
			timer.set_wait_time(1.75)
		2: 
			timer.start(1 * time_percent)
			timer.set_wait_time(1)
		3:
			timer.start(0.5 * time_percent)
			timer.set_wait_time(0.5)
		4:
			timer.start(0.2 * time_percent)
			timer.set_wait_time(0.2)
		_:
			timer.start(1 * time_percent)
			timer.set_wait_time(1)
			print("ERROR: UNRECOGNISED TURN SPEED")
	
	print("turn speed: ", turn_speed, " ¦ ", timer.wait_time, "s")


func _on_Timer_timeout():
	turn += 1
	print("--- turn ", turn, " ---")
	next_turn()


#NOTE: this would likely be more resilient if there was only two lists: one for the current turn and one for the next
#at the start of each turn next turn is transferred to current turn and then cleared
#then current tun is processed and cleared at the end of the turn, this way there's fewer potential holes and lists
#although maybe if there's a crapton of entities working they would have to be cleared and added constantly each turn
#which may come at a small performance impact but this seems like an edge case
func next_turn():
	#check for pending changes of the working list, this way the list is not edited while its already looping
	for entity in erase_queue:
		currently_working.erase(entity)
	for entity in append_queue:
		currently_working.append(entity)
	erase_queue.clear()
	append_queue.clear()
	
	for entity in currently_working:
		entity.update_turn()
	
	pathfindingMap.update()



#add unit to the append queue to be added to the working list at the start of next turn
func append_to_working_list(entity):
	if currently_working.find(entity) == -1 and append_queue.find(entity) == -1:
		append_queue.append(entity)

#add unit to the erase queue to be removed from the working list at the start of next turn
func erase_from_working_list(entity):
	if erase_queue.find(entity) == -1:
		erase_queue.append(entity)
