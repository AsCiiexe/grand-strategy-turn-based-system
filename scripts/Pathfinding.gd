extends TileMap
#WARNING: Astar returns PoolVector3s, if you need Vector2s you'll have to convert
#example: Vector2(PoolVector3[0].x, PoolVector3[0].y)
onready var astar_node = AStar.new()
onready var tileManager = get_parent().get_node("Terrain")
export var map_size = Vector2(34, 20)
#setter methods (setget) will run the func specified whenever the var is changed 
#(the func runs before the change) setget can actually cancel any changes made to a variable
var path_start_position = Vector2() setget _set_path_start_position
var path_end_position = Vector2() setget _set_path_end_position
var moving_units = []
var PFselected_units = []
#this will contain the path that the object has to follow in order to reach its destination
var point_path = []

const BASE_LINE_WIDTH = 3.0
const DRAW_COLOR = Color('#fff')#white
const END_COLOR = Color(1, 0, 0, 1)#red

# Scans the tilemap to search all cells with tile id 0 (obstacles, can be seen in tilemap editor) and adds them to the list
onready var obstacles = get_used_cells_by_id(0)
onready var half_cell = cell_size / 2


func _ready():
	var walkable_cells_list = astar_add_walkable_cells(obstacles)
	astar_connect_walkable_cells(walkable_cells_list)



#every time a new unit is selected this will be updated so multiple paths are drawn
#if that unit has no path then it will be skipped
func _draw():
	for unit in PFselected_units:
		if moving_units.find(unit) != -1:
			draw_path(unit.current_node_position, unit.unit_path)



func draw_path(first_path_point, path_to_draw):
	draw_circle(first_path_point, BASE_LINE_WIDTH * 2.0, DRAW_COLOR)
	var previous_point = first_path_point
	#this will connect each cell of the path with lines and a dot at the center of each one
	for index in range(0, len(path_to_draw)):
		var current_point = Vector2(path_to_draw[index].x, path_to_draw[index].y)
		draw_line(previous_point, current_point, DRAW_COLOR, BASE_LINE_WIDTH, true)
		if index == len(path_to_draw) - 1:#if it's the last node draw a red dot
			draw_circle(current_point, BASE_LINE_WIDTH * 2.0, END_COLOR)
		else:
			draw_circle(current_point, BASE_LINE_WIDTH * 2.0, DRAW_COLOR)
		previous_point = current_point



#add all cells in the map that are not obstacles to points_array
#for loops in Godot are not bound to number sequences, it also accepts arrays, tables or dictionaries
func astar_add_walkable_cells(obstacles_ = []):
	var points_array = []
	
	#point_x and point_y are not coordinates, they are tile indices
	for point_y in range(map_size.y):
		for point_x in range(map_size.x):
			var point = Vector2(point_x, point_y)
			if point in obstacles_:
				continue
			
			points_array.append(point)
			# The AStar class references points with indices
			# which is calculated from a point's coordinates
			# think of points as "coord locations" and indices as "spreadsheet locations"
			var point_index = calculate_point_index(point)
			#this will assure movement cost will be taken into account when calculating paths
			#x10 because Astar needs point weight to be at least 1
			var point_weight = tileManager.p_get_tile_pathfinding_weight(point)
			# AStar works in 3d by default, so the Vector3 is "converted" into Vector2
			astar_node.add_point(point_index, Vector3(point.x, point.y, 0.0), point_weight)
			
	return points_array



#connects all cells horizontally and vertically
func astar_connect_walkable_cells(points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		# For each cell in the map, we check one to the right, left, bottom and top of them.
		# If there's a cell and it's not an obstacle, we connect the current point with it
		var points_relative = PoolVector2Array([#points_relative are the points around this point
			point + Vector2.RIGHT,
			point + Vector2.LEFT,
			point + Vector2.DOWN,
			point + Vector2.UP,
		])
		for point_relative in points_relative: #reminder that for loops can declare a var in this line here
			var point_relative_index = calculate_point_index(point_relative)
			
			if is_outside_map_bounds(point_relative):
				continue #skip this check and go to the next iteration of the loop
			if not astar_node.has_point(point_relative_index):
				continue
			astar_node.connect_points(point_index, point_relative_index, false)



#NOT USED. This variation connects cells vertically, horizontally and diagonally.
func astar_connect_walkable_cells_diagonal(points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		
		for local_y in range(3):
			for local_x in range(3):
				var point_relative = Vector2(point.x + local_x - 1, point.y + local_y - 1)
				var point_relative_index = calculate_point_index(point_relative)
				if point_relative == point or is_outside_map_bounds(point_relative):
					continue
				if not astar_node.has_point(point_relative_index):
					continue
				astar_node.connect_points(point_index, point_relative_index, true)



#this is the actual function that will be called from other objects to make their path
func get_astar_path(world_start, world_end):
	self.path_start_position = world_to_map(world_start)
	self.path_end_position = world_to_map(world_end)
	
	#AStar can only calculate by indices (IDs), not coordinates
	var start_point_index = calculate_point_index(path_start_position)
	var end_point_index = calculate_point_index(path_end_position)
	point_path = astar_node.get_point_path(start_point_index, end_point_index)
	
	var path_world = []
	for point in point_path:
		var point_world = map_to_world(Vector2(point.x, point.y)) + half_cell
		path_world.append(point_world)
	return path_world



#the AStar indices are stored in an array and not a xy spreadsheet, so this is needed
func calculate_point_index(point):
	return point.x + map_size.x * point.y



func is_outside_map_bounds(point):
	return point.x < 0 or point.y < 0 or point.x >= map_size.x or point.y >= map_size.y



func _set_path_start_position(value):
	#WARNING: this check is never used as its residue from the base pathfinding project (shift+click feature)
	if value in obstacles:
		return
	if is_outside_map_bounds(value):
		return
	
	path_start_position = value



func _set_path_end_position(value):
	#WARNING: this check is never used as its residue from the base pathfinding project (shift+click feature)
	if value in obstacles:
		return
	if is_outside_map_bounds(value):
		return
	
	path_end_position = value



#adds (object) to progress list so it’s called every turn to update its turn progresses
func append_moving_units(unit):
	#check if it's already on the list, otherwise it would be called multiple times
	if moving_units.find(unit) == -1:
		moving_units.append(unit)



#removes (object) from progress list so it’s not called anymore
func erase_from_moving_units(unit):
	moving_units.erase(unit)



