extends TileMap

#pathfindingWeight is used when calculating pathfinding
#the lower the lighter it is in the pathfinding
#in order to get accurate paths this is reversed movementProgressMod
#the calculation is simple: 10 - movementProgressMod
#eg 10 - 0.75 = 9.25 pathfindingWeight
#this is probably a shabby way of doing it but it works

onready var pathfindingMap = get_tree().get_root().get_node("Main/PathfindingMap")

var occupied_tiles = {} #all the tiles with a unit in them
var tile_contents = [] #used in occupied_tiles management
var buildings = {} #all the tiles with a building in them

var plains_properties = {
		"tileName": "plains", #tile name
		"movementProgressMod": 1, #modifier multiplier [x1]
		"pathfindingWeight": 9, #the lower, the less it will take to move here
		"baseVigorCost": 1, #raw number [+1]
		"vigorRecoveryMod": 1, #modifier multiplier [x1]
		"naturalTerrainSupply": 100, #raw number [+1]
		"attackerMod": 1 #modifier multiplier [x1]
}

var hills_properties = {
		"tileName": "hills",
		"movementProgressMod": 0.90,
		"pathfindingWeight": 9.10,
		"baseVigorCost": 2.5,
		"vigorRecoveryMod": 0.95,
		"naturalTerrainSupply": 100,
		"attackerMod": 0.90
}

var forest_properties = {
		"tileName": "forest",
		"movementProgressMod": 0.80,
		"pathfindingWeight": 9.20,
		"baseVigorCost": 2.5,
		"vigorRecoveryMod": 1,
		"naturalTerrainSupply": 150,
		"attackerMod": 0.90
}

var farmlands_properties = {
		"tileName": "farmlands",
		"movementProgressMod": 1,
		"pathfindingWeight": 9,
		"baseVigorCost": 0.85,
		"vigorRecoveryMod": 1.15,
		"naturalTerrainSupply": 200,
		"attackerMod": 1
}

var mountain_properties = {
		"tileName": "mountains",
		"movementProgressMod": 0.60,
		"pathfindingWeight": 9.40,
		"baseVigorCost": 4.5,
		"vigorRecoveryMod": 0.90,
		"naturalTerrainSupply": 85,
		"attackerMod": 0.80
}

var marsh_properties = {
		"tileName": "marsh",
		"movementProgressMod": 0.80,
		"pathfindingWeight": 9.20,
		"baseVigorCost": 3.5,
		"vigorRecoveryMod": 0.85,
		"naturalTerrainSupply": 75,
		"attackerMod": 0.90
}

var desert_properties = {
		"tileName": "desert",
		"movementProgressMod": 0.65,
		"pathfindingWeight": 9.35,
		"baseVigorCost": 5,
		"vigorRecoveryMod": 0.75,
		"naturalTerrainSupply": 50,
		"attackerMod": 1
}

var obstacle_properties = {
		"tileName": "obstacle",
		"movementProgressMod": 0,
		"pathfindingWeight": 100,
		"baseVigorCost": 0,
		"vigorRecoveryMod": 0,
		"naturalTerrainSupply": 0,
		"attackerMod": 1
}



func get_tile_id(tile_position):
	var cell_grid_pos = world_to_map(tile_position)
	return get_cell(cell_grid_pos.x, cell_grid_pos.y)


#cell_pos has to be in XY coords
func get_tile_properties(cell_pos):
	var cell_map_pos = world_to_map(Vector2(cell_pos.x, cell_pos.y))
	var tile_index = get_cell(cell_map_pos.x, cell_map_pos.y)
	match tile_index:
		0:#obstacle
			return obstacle_properties
		1:#plains
			return plains_properties
		2:#hills
			return hills_properties
		3:#forest
			return forest_properties
		4:#farmlands
			return farmlands_properties
		5:#mountains
			return mountain_properties
		6:#marsh
			return marsh_properties
		7:#desert
			return desert_properties
		_:
			print("NO TILE IN ", cell_pos)
			return null

func get_tile_units(pos):
	return occupied_tiles.get(pos)

#this asks for a tile's xy coords and returns that tile's movement cost
func get_tile_movement_cost(tile_coords):
	var tproperties = get_tile_properties(tile_coords)
	return tproperties.get("movementProgressMod")

func get_tile_attacker_mod(tile_coords):
	var tproperties = get_tile_properties(tile_coords)
	return tproperties.get("attackerMod")



#NOTE: THIS STUFF IS NOT FOOLPROOF, IT CAN EASILY HAVE MANY HOLES POKED
func set_unit_position(pos, id):
	#occupied_tiles is a dictionary with all occupied tiles and their contents
	#tile_contents is an array with all units in a specific tile
	tile_contents = occupied_tiles.get(pos)
	if tile_contents == null:
		tile_contents = []
	
	if tile_contents.find(id) == -1:
		tile_contents.append(id)
	else:
		print("UNIT IS ALREADY HERE")
	
	occupied_tiles[pos] = tile_contents

#NOTE: THIS WILL FAIL IF THE TILE IS NONEXISTENT
func delete_unit_position(pos, id):
	tile_contents = occupied_tiles.get(pos)
	tile_contents.erase(id)
	if tile_contents.empty() == false:
		occupied_tiles[pos] = tile_contents
	else:
		occupied_tiles.erase(pos)


#NOTE: this is for the pathfinding node only as it asks for a tile index and not xy coords
func p_get_tile_pathfinding_weight(tile_index):
	var tile_coords = map_to_world(tile_index)
	var tproperties = get_tile_properties(tile_coords)
	return tproperties.get("pathfindingWeight")



