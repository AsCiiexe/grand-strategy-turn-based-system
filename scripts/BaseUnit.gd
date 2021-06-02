extends Position2D

enum states {IDLE, MOVING, FIGHTING}
var state = states.IDLE
enum TEAMS {PLAYER, ENEMY}
export(TEAMS) var team = TEAMS.PLAYER
var movement_speed = 500.0 #how fast this unit moves on screen once movement progress is completed

#the max_health and similars are not changed as this is a base unit class and will be changed by diff units
#NOTE: consider organising them into dictionaries with a unit_manager
var unit_max_health = 250 
var unit_health = unit_max_health
var unit_base_strength = 25
var unit_strength = unit_base_strength
var unit_max_vigor = 100
var unit_vigor = unit_max_vigor
var unit_speed = 50 #how much is added to movement progress every turn when moving

var unit_path = [] #list of all nodes to final node in pathfinding
var movement_queue = [] #this keeps node relocation and physical movement separate so there's a "buffer"
var movement_progress = 0 #when this reaches 100 the unit moves to the next tile
var movement_cost_mod = 1 #multiplier applied depening on the next tile movement cost when pathfinding
var target_position = Vector2() #final node in pathfinding
var current_tile_position = Vector2() #which tile this unit is registered to be on

onready var fightScene = preload("res://scenes/FightScene.tscn")
onready var pathfindingMap = get_tree().get_root().get_node("Main/PathfindingMap")
onready var tileManager = get_tree().get_root().get_node("Main/Terrain")
onready var turnManager = get_tree().get_root().get_node("Main/TurnManager")
onready var playerManager = get_tree().get_root().get_node("Main/Cursor")
onready var area2d = get_node("Area2D")
var fight_reference = null #points to the fight manager spawned when this unit starts a fight

func _ready():
	current_tile_position = position
	
	area2d.connect("mouse_entered", self, "_on_mouse_entered")
	area2d.connect("mouse_exited", self, "_on_mouse_exited")
	tileManager.set_unit_position(current_tile_position, self)
	
	if team == TEAMS.PLAYER:
		modulate = Color.white
	elif team == TEAMS.ENEMY:
		modulate = Color.red



func _physics_process(delta):
	if movement_queue:
		_move_to_next_tile(delta, movement_queue[0])



func new_path():
	movement_progress = 0
	movement_queue.clear()
	unit_path.clear()
	position = current_tile_position
	target_position = get_global_mouse_position()
	unit_path = pathfindingMap.get_astar_path(position, target_position)
	
	#if the player has clicked the same tile cancel any movement and go back to idle
	if not unit_path or unit_path.size() == 1:
		unit_path.clear()
		change_state(states.IDLE)
		return
	
	unit_path.remove(0)#the first cell is always the cell the unit is already standing at
	movement_cost_mod = tileManager.get_tile_movement_cost(unit_path[0])
	change_state(states.MOVING)



#for shift+click so this path is added at the end of the path
func add_to_path():
	if not unit_path:#if there is no unit path simply draw a new path
		new_path()
		return
	target_position = get_global_mouse_position()
	var path_addition = pathfindingMap.get_astar_path(unit_path.back(), target_position)
	path_addition.remove(0)#without this the last previous tile will be repeated
	for new_tile in path_addition:
		unit_path.push_back(new_tile)
	path_addition.clear()



func update_turn():
	if state == states.MOVING:
		_turn_based_movement()



func _turn_based_movement():
	#separate physical movement with movement queue and movement relocation with unit path
	movement_progress += unit_speed * movement_cost_mod
	if movement_progress >= 100:
		tileManager.delete_unit_position(current_tile_position, self)
		current_tile_position = unit_path[0]#position relocation part
		tileManager.set_unit_position(current_tile_position, self)
		movement_queue.append(unit_path[0])#physical relocation part
		unit_path.remove(0)
		var enemies_found = check_for_enemies(current_tile_position)
		if enemies_found:
			return
		
		if unit_path:#if the path is still going transfer excess speed to the next point movement
			movement_progress -= 100
			movement_cost_mod = tileManager.get_tile_movement_cost(unit_path[0])
		else:
			movement_progress = 0
			change_state(states.IDLE)
	print("	", self, " movement_progress = ", movement_progress, " ¦ moving = ", not movement_queue.empty())



func check_for_enemies(pos):
	var tile_units = tileManager.get_tile_units(pos)
	if tile_units == null or tile_units == [self]: #technically this would never be null
		return false #if there's no units return false
	
	for unit in tile_units:
		if unit.team != team:
			change_state(states.FIGHTING)
			if unit.state == states.FIGHTING: #if there's already a fight join it
				unit.fight_reference.add_more_combatants([self])
			else: #else start one and create a fight manager
				unit.change_state(states.FIGHTING)
				var fight_instance = fightScene.instance()
				get_tree().get_root().add_child(fight_instance)
				fight_instance.global_position = current_tile_position
				fight_instance.set_sides([self], [unit])
				fight_reference = fight_instance
				unit.fight_reference = fight_instance
			
			return true #if there's unit and any are in the enemy team return true
	
	return false #if there's units but none are enemies return false



func _move_to_next_tile(delta, tile):
	var _arrived_to_next_point = _move_to_snap(tile, delta)
	if _arrived_to_next_point:
		movement_queue.remove(0)



#actual physical movement
#without this subtle "snap" at the end, this may lead to a unit endlessly jittering back and forth a tile
func _move_to_snap(world_position, delta):
	var _velocity = Vector2()
	var SNAP_DISTANCE = 4.0
	_velocity = (world_position - position).normalized() * movement_speed
	position += _velocity * delta
	if position.distance_to(world_position) < SNAP_DISTANCE:
		position = world_position
		return true
	
	return false



#where unit_path is filled with the pathfinded path
func change_state(new_state):
	if new_state == states.MOVING:
		print(self, " state: moving")
		turnManager.append_to_working_list(self)
	
	if new_state == states.IDLE:
		print(self, " state: idle")
		turnManager.erase_from_working_list(self)
		pathfindingMap.erase_from_moving_units(self)
	
	if new_state == states.FIGHTING:
		movement_progress = 0
		unit_path.clear()
		movement_queue.clear()
		position = current_tile_position
		pathfindingMap.erase_from_moving_units(self)
	
	state = new_state



func eliminate():
	turnManager.erase_from_working_list(self)
	tileManager.delete_unit_position(position, self)
	queue_free()



func _on_mouse_entered():
	playerManager.append_to_hovering_entities(self)


func _on_mouse_exited():
	playerManager.erase_from_hovering_entities(self)



