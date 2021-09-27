extends Position2D

onready var playerTeamManager = get_tree().get_root().get_node("Main/PlayerTeamManager")
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
	if event.is_action_pressed("quit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	#tbh I'm not sure right now what the difference is between Input.method() and event.method()
	mb_middle_held = Input.is_action_pressed("mb_middle")
	shift_held = Input.is_action_pressed("shift")
	
	#F3: Show the teams gold regen and consumption
	if event.is_action_pressed("F3"):
		if playerTeamManager.show_balance == false:
			playerTeamManager.show_balance = true
		else:
			playerTeamManager.show_balance = false
	
#	left_click: entity selection
	if event.is_action_pressed("mb_left"):
		if hovering_entities.empty() != true: #THE .FRONT() CHECKS DOWN HERE ARE NOT OPTIMAL AND SHOULD BE REFORMATTED
			if hovering_entities.front().is_in_group("unit"):
				left_click_unit()
			elif hovering_entities.front().is_in_group("building"):
				pass
		elif not shift_held:#If shift is not held and the click is in an empty tile clear all selections
			new_iteration = true
			selected_entities.clear()
			pathfindingMap.PFselected_units.clear()
		
		pathfindingMap.update()
		print("selected ", selected_entities)
	
	#right_click: do action
	if event.is_action_pressed("mb_right"):
		if selected_entities.empty() != true:
			if selected_entities.front().is_in_group("unit"):
				right_click_unit()
			elif selected_entities.front().is_in_group("building"):
				pass
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

func _on_screen_resized():
	var window_size = OS.get_window_size()
	var camera_x = clamp(camera2D.position.x, 0, (pathfindingMap.map_size.x * pathfindingMap.cell_size.x) - (window_size.x * camera2D.zoom.x))
	var camera_y = clamp(camera2D.position.y, 0, (pathfindingMap.map_size.y * pathfindingMap.cell_size.y) - (window_size.y * camera2D.zoom.y))
	camera2D.position = Vector2(camera_x, camera_y)


func get_entity_tile_id():
	if selected_entities.empty() != true:
			for entity in selected_entities:
				print(tileManager.get_tile_id(entity.position))


func get_entity_position():
	if selected_entities.empty() != true:
			for entity in selected_entities:
				print(tileManager.get_tile_properties(entity.position))



func left_click_unit():
	new_iteration = true
	if not shift_held:#unless the shift is held all previously selected units are deselected
		selected_entities.clear()
		pathfindingMap.PFselected_units.clear()
	
	for entity in hovering_entities:
		if selected_entities.find(entity) == -1:#this is so an entity is only selected once
			selected_entities.append(entity)
			pathfindingMap.PFselected_units.append(entity)


func right_click_unit():
	if selected_entities.empty() == true:
		return
	
	if shift_held:
		for entity in selected_entities:
			pathfindingMap.append_moving_units(entity)
			entity.add_to_path()
	else:
		for entity in selected_entities:
			pathfindingMap.append_moving_units(entity)
			entity.new_path()


#these two are called from other objects when the mouse enters their detection box
func append_to_hovering_entities(entity):
	#check if it's already on the list, otherwise it would be called multiple times
	if hovering_entities.find(entity) == -1:
		hovering_entities.append(entity)


func erase_from_hovering_entities(entity):
	hovering_entities.erase(entity)



