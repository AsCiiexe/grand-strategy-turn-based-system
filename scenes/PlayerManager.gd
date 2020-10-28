extends Position2D

onready var tileManager = get_parent().get_node("Terrain")
onready var pathfindingMap = get_parent().get_node("PathfindingMap")
onready var camera2D = get_parent().get_node("Camera2D")
var hovering_units = []
var selected_units = []
var iterating_units = []
var new_iteration = true
var current_iteration = 0
var mb_middle_held = false
var shift_held = false


func _process(_delta):
	mb_middle_held = Input.is_action_pressed("mb_middle")
	shift_held = Input.is_action_pressed("shift")



func _unhandled_input(event):
	#F3: get tile id of selected unit
	if event.is_action_pressed("F3"):
		get_unit_tile_id()
	
	#F4: get unit position
	if event.is_action_pressed("F4"):
		get_unit_position()
	
#	left_click: unit selection
	if event.is_action_pressed("mb_left"):
		#shift + leftclick = add to selected units
		if shift_held and hovering_units.empty() != true:
			shift_left_click()
		#leftclick alone = deselect everything except what's here
		else:
			left_click()
		pathfindingMap.update()
		print("selected ", selected_units)
	
	#right_click: do path
	if event.is_action_pressed("mb_right"):
		if selected_units.empty() != true:
			#shift + leftclick = add more path to selected units
			if shift_held:
				#this will behave the same as a rclick if there is no path already given to the units
				shift_right_click()
			#else rewrite path or create a new path
			else:
				right_click()
			pathfindingMap.update()
	
	#tab: iterate through selected units
	if event.is_action_pressed("tab") and selected_units.empty() != true:
		if new_iteration:
			new_iteration = false
			iterating_units = selected_units.duplicate()
			current_iteration = 0
		
		selected_units = [iterating_units[current_iteration]]
		pathfindingMap.PFselected_units = [iterating_units[current_iteration]]
		print("selected_units ", selected_units, " iterating_units ", iterating_units, " current_iteration ", current_iteration)
		
		current_iteration += 1
		if current_iteration + 1 > iterating_units.size():
			current_iteration = 0
		pathfindingMap.update()
	
	if event.is_action_pressed("mouse_wheel_up"):
		if camera2D.zoom <= Vector2(3, 3):
			camera2D.zoom -= Vector2(0.1, 0.1)
	
	if event.is_action_pressed("mouse_wheel_down"):
		if camera2D.zoom >= Vector2(0.3, 0.3):
			camera2D.zoom += Vector2(0.1, 0.1)
	
	#pan camera with middle mouse
	#if mouse is moving -> if middle click is held -> change camera pos based on mouse movement (relative)
	if event is InputEventMouseMotion:
		if mb_middle_held:
			camera2D.position -= event.relative * camera2D.zoom
			print("move ", camera2D.position)



func get_unit_tile_id():
	if selected_units.empty() != true:
			for unit in selected_units:
				print(tileManager.get_tile_id(unit.position))


func get_unit_position():
	if selected_units.empty() != true:
			for unit in selected_units:
				print(tileManager.get_tile_properties(unit.position))



func shift_left_click():
	new_iteration = true
	
	for unit in hovering_units:
		selected_units.append(unit)
		pathfindingMap.PFselected_units.append(unit)


func left_click():
	new_iteration = true
	selected_units.clear()
	pathfindingMap.PFselected_units.clear()
	
	if hovering_units.empty() != true:
		for unit in hovering_units:
			if selected_units.find(unit) == -1:#this is so a unit is only selected once
				selected_units.append(unit)
				pathfindingMap.PFselected_units.append(unit)



func shift_right_click():
	for unit in selected_units:
		pathfindingMap.append_moving_units(unit)
		unit.add_to_path()


func right_click():
	for unit in selected_units:
		pathfindingMap.append_moving_units(unit)
		unit.new_path()



func append_to_hovering_units(unit):
	#check if it's already on the list, otherwise it would be called multiple times
	if hovering_units.find(unit) == -1:
		hovering_units.append(unit)
		#print("hovering ", hovering_units)


#removes (object) from progress list so it’s not called anymore
func erase_from_hovering_units(unit):
	hovering_units.erase(unit)
	#print("hovering ", hovering_units)



