extends Position2D

onready var tileManager = get_tree().get_root().get_node("Main/Terrain")
onready var pathfindingMap = get_tree().get_root().get_node("Main/PathfindingMap")
onready var camera2D = get_tree().get_root().get_node("Main/Camera2D")
var hovering_entities = []
var selected_entities = []
var iterating_entities = []
var new_iteration = true #I don't remember why this was a necessary check but it appeared to cover an edge case
var current_iteration = 0
var mb_middle_held = false
var shift_held = false

func _ready():
	get_tree().connect("screen_resized", self, "_on_screen_resized")

func _unhandled_input(event):
	#I'm not sure what the difference is between Input.method() and event.method()
	mb_middle_held = Input.is_action_pressed("mb_middle")
	shift_held = Input.is_action_pressed("shift")
	
	#F3: get tile id of selected entity
	if event.is_action_pressed("F3"):
		get_entity_tile_id()
	
	#F4: get entity position
	if event.is_action_pressed("F4"):
		get_entity_position()
	
#	left_click: entity selection
	if event.is_action_pressed("mb_left"):
		#shift + leftclick = add to selected entities
		if shift_held and hovering_entities.empty() != true:
			shift_left_click()
		#leftclick alone = deselect everything except what's here
		else:
			left_click()
		pathfindingMap.update()
		print("selected ", selected_entities)
	
	#right_click: do path
	if event.is_action_pressed("mb_right"):
		if selected_entities.empty() != true:
			#shift + leftclick = add more path to selected entities
			if shift_held:
				#this will behave the same as a rclick if there is no path already given to the units
				shift_right_click()
			#else rewrite path or create a new path
			else:
				right_click()
			pathfindingMap.update()
	
	#tab: iterate through selected entities
	if event.is_action_pressed("tab") and selected_entities.empty() != true:
		if new_iteration:
			new_iteration = false
			iterating_entities = selected_entities.duplicate()
			current_iteration = 0
		
		selected_entities = [iterating_entities[current_iteration]]
		pathfindingMap.PFselected_units = [iterating_entities[current_iteration]]
		print("selected_entities ", selected_entities, " iterating_entities ", iterating_entities, " current_iteration ", current_iteration)
		
		current_iteration += 1
		if current_iteration + 1 > iterating_entities.size():
			current_iteration = 0
		pathfindingMap.update()
	
	if event.is_action_pressed("mouse_wheel_up"):
		var zoom_x = max(camera2D.zoom.x - 0.1, 0.3)
		var zoom_y = max(camera2D.zoom.y - 0.1, 0.3)
		camera2D.zoom = Vector2(zoom_x, zoom_y)
	
	if event.is_action_pressed("mouse_wheel_down"):
		var zoom_x = min(camera2D.zoom.x + 0.1, 2.0)
		var zoom_y = min(camera2D.zoom.y + 0.1, 2.0)
		camera2D.zoom = Vector2(zoom_x, zoom_y)
	
	#pan camera with middle mouse
	#if mouse is moving -> if middle click is held -> change camera pos based on mouse movement (relative)
	if event is InputEventMouseMotion:
		if mb_middle_held:
			camera2D.position -= event.relative * camera2D.zoom
			#limit the camera to the level size multiplied by the current zoom level
			var window_size = OS.get_window_size()
			var camera_x = clamp(camera2D.position.x, 0, (pathfindingMap.map_size.x * pathfindingMap.cell_size.x) - (window_size.x * camera2D.zoom.x))
			var camera_y = clamp(camera2D.position.y, 0, (pathfindingMap.map_size.y * pathfindingMap.cell_size.y) - (window_size.y * camera2D.zoom.y))
			camera2D.position = Vector2(camera_x, camera_y)
			print("move ", camera2D.position)

func _on_screen_resized():
	var window_size = OS.get_window_size()
	var camera_x = clamp(camera2D.position.x, 0, (pathfindingMap.map_size.x * pathfindingMap.cell_size.x) - (window_size.x * camera2D.zoom.x))
	var camera_y = clamp(camera2D.position.y, 0, (pathfindingMap.map_size.y * pathfindingMap.cell_size.y) - (window_size.y * camera2D.zoom.y))
	camera2D.position = Vector2(camera_x, camera_y)
	print("screen resized ", camera2D.position)


func get_entity_tile_id():
	if selected_entities.empty() != true:
			for entity in selected_entities:
				print(tileManager.get_tile_id(entity.position))


func get_entity_position():
	if selected_entities.empty() != true:
			for entity in selected_entities:
				print(tileManager.get_tile_properties(entity.position))



func shift_left_click():
	new_iteration = true
	
	for entity in hovering_entities:
		if selected_entities.find(entity) == -1:
			selected_entities.append(entity)
			pathfindingMap.PFselected_units.append(entity)


func left_click():
	new_iteration = true
	selected_entities.clear()
	pathfindingMap.PFselected_units.clear()
	
	if hovering_entities.empty() != true:
		for entity in hovering_entities:
			if selected_entities.find(entity) == -1:#this is so an entity is only selected once
				selected_entities.append(entity)
				pathfindingMap.PFselected_units.append(entity)



func shift_right_click():
	for entity in selected_entities:
		pathfindingMap.append_moving_units(entity)
		entity.add_to_path()


func right_click():
	for entity in selected_entities:
		pathfindingMap.append_moving_units(entity)
		entity.new_path()



func append_to_hovering_entities(entity):
	#check if it's already on the list, otherwise it would be called multiple times
	if hovering_entities.find(entity) == -1:
		hovering_entities.append(entity)
		#print("hovering ", hovering_entities)


#removes (object) from progress list so it’s not called anymore
func erase_from_hovering_entities(entity):
	hovering_entities.erase(entity)
	#print("hovering ", hovering_entities)



