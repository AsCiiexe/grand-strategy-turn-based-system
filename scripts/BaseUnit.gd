extends Position2D

enum states {IDLE, MOVING, FIGHTING}
var state = null
enum TEAMS {PLAYER, ENEMY}
export(TEAMS) var team = TEAMS.PLAYER
export(Color) var filter = Color('#fff')#for distinguishing different units
var movement_speed = 500.0 #how fast this unit moves on screen once movement progress is completed

#the max_health and similars are not changed as this is a base unit class and will be changed by diff units
#NOTE: consider organising them into dictionaries with a unit_manager
var unit_max_health = 100 
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
var current_node_position = Vector2() #current residing node IN XY COORD VALUES NOT TILEMAP VALUES

onready var pathfindingMap = get_parent().get_node("PathfindingMap")
onready var tileManager = get_parent().get_node("Terrain")
onready var turnManager = get_parent().get_node("TurnManager")
onready var playerManager = get_parent().get_node("Cursor")

onready var area2d = get_node("Area2D")
#stuff used in _draw() virtual method


func _ready():
	change_state(states.IDLE)
	current_node_position = position
	
	get_node("UnitSprite").set_modulate(filter)
	area2d.connect("mouse_entered", self, "_on_mouse_entered")
	area2d.connect("mouse_exited", self, "_on_mouse_exited")
	tileManager.set_unit_position(current_node_position, self)



func _physics_process(delta):
	if movement_queue:
		_move_to_next_tile(delta, movement_queue[0])



func new_path():
	print("	new path for ", self)
	movement_progress = 0
	movement_queue.clear()
	unit_path.clear()
	position = current_node_position
	target_position = get_global_mouse_position()
	
	unit_path = pathfindingMap.get_astar_path(position, target_position)
	if not unit_path or len(unit_path) == 1:#check if the player clicked the same tile this is at
		unit_path.clear()
		return
	unit_path.remove(0)#first cell is always the cell the unit is already standing at
	movement_cost_mod = tileManager.get_tile_movement_cost(unit_path[0])
	change_state(states.MOVING)



#for shift+click so this path is added at the end of the path
func add_to_path():
	if not unit_path:#if there is no unit path simply draw a new path
		new_path()
		return
	print("added to path of ", self)
	target_position = get_global_mouse_position()
	var path_addition = pathfindingMap.get_astar_path(unit_path.back(), target_position)
	path_addition.remove(0)#without this the last previous tile will be repeated
	for new_tile in path_addition:
		unit_path.push_back(new_tile)
	path_addition.clear()



func update_turn():
	if state == states.MOVING:
		_turn_based_movement()
	#here should be added if "state is fighting" when that's created



func _turn_based_movement():
	#separate physical movement with movement queue and movement relocation with unit path
	movement_progress += unit_speed * movement_cost_mod
	if movement_progress >= 100:
		tileManager.delete_unit_position(current_node_position, self)
		current_node_position = unit_path[0]#position relocation part
		tileManager.set_unit_position(current_node_position, self)
		movement_queue.append(unit_path[0])#physical relocation part
		unit_path.remove(0)
		
		var enemies_found = check_for_enemies(current_node_position)
		if enemies_found:
			change_state(states.FIGHTING)
			return
		
		if unit_path:#if the path is still going transfer excess speed to the next point movement
			movement_progress -= 100
			movement_cost_mod = tileManager.get_tile_movement_cost(unit_path[0])
		else:
			movement_progress = 0
			change_state(states.IDLE)
	print("	", self, " movement_progress = ", movement_progress, " ¦ moving = ", not movement_queue.empty())



func check_for_enemies(pos):
	var tile_units = tileManager.get_tile_contents(pos)
	if tile_units == null:
		return false
	
	for unit in tile_units:
		if unit.team != team:
			return true
	
	return false



func _move_to_next_tile(delta, tile):
	var _arrived_to_next_point = _move_to_snap(tile, delta)
	if _arrived_to_next_point:
		movement_queue.remove(0)



#actual physical movement
#without this subtle "snap" this may lead to a unit endlessly jittering back and forth a tile
func _move_to_snap(world_position, delta):
	var _velocity = Vector2()
	var ARRIVE_DISTANCE = 4.0
	_velocity = (world_position - position).normalized() * movement_speed
	position += _velocity * delta
	if position.distance_to(world_position) < ARRIVE_DISTANCE:
		position = world_position
		return true
	
	return false



#where unit_path is filled with the pathfinded path
func change_state(new_state):
	
	if new_state == states.MOVING:
		turnManager.append_to_working_list(self)
	
	if new_state == states.IDLE:
		turnManager.erase_from_working_list(self)
		pathfindingMap.erase_from_moving_units(self)
	
	if new_state == states.FIGHTING:
		print("	FIGHT!")
		movement_progress = 0
		unit_path.clear()
		movement_queue.clear()
		position = current_node_position
		pathfindingMap.erase_from_moving_units(self)
	
	state = new_state



func _on_mouse_entered():
	playerManager.append_to_hovering_units(self)


func _on_mouse_exited():
	playerManager.erase_from_hovering_units(self)



