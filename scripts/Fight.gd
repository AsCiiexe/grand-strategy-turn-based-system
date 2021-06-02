extends Position2D

onready var pathfindingMap = get_tree().get_root().get_node("Main/PathfindingMap")
onready var tileManager = get_tree().get_root().get_node("Main/Terrain")
onready var turnManager = get_tree().get_root().get_node("Main/TurnManager")
onready var playerManager = get_tree().get_root().get_node("Main/Cursor")

var attacker_side = []
var defender_side = []
var attacker_health = 0
var attacker_strength = 0
var attacker_vigor = 0
var defender_health = 0
var defender_strength = 0
var defender_vigor = 0
var vigor_mod = 0
var attacker_iteration = 0 #used to decide how many sprites to draw in the animation
var defender_iteration = 0


func _ready():
	print("	combat!")
	turnManager.append_to_working_list(self)


func set_sides(attackers, defenders):
	for attacker in attackers:
		add_combatant(attacker, 1)
	
	for defender in defenders:
		add_combatant(defender, 2)
	
	calculate_sides()
	print("	fight in ", position)
	print("	attackers = ", attacker_side, " defenders = ", defender_side)


func add_combatant(combatant, side):
	combatant.visible = false
	combatant.get_node("Area2D").input_pickable = false #the player can't select this unit while its fighting
	if side == 1:
		attacker_side.append(combatant)
		attacker_health += combatant.unit_health
		attacker_strength += combatant.unit_strength
		attacker_vigor += combatant.unit_vigor
		
		attacker_iteration += 1
		if attacker_iteration == 1:
			$AttackerSprite1.modulate = combatant.modulate
		if attacker_iteration == 2:
			$AttackerSprite2.modulate = combatant.modulate
			$AttackerSprite2.visible = true
		if attacker_iteration == 3:
			$AttackerSprite3.modulate = combatant.modulate
			$AttackerSprite3.visible = true
	else:
		defender_side.append(combatant)
		defender_health += combatant.unit_health
		defender_strength += combatant.unit_strength
		defender_vigor += combatant.unit_vigor
		defender_iteration += 1
		if defender_iteration == 1:
			$DefenderSprite1.modulate = combatant.modulate
		if defender_iteration == 2:
			$DefenderSprite2.modulate = combatant.modulate
			$DefenderSprite2.visible = true
		if defender_iteration == 3:
			$DefenderSprite3.modulate = combatant.modulate
			$DefenderSprite3.visible = true


func calculate_sides():
	if attacker_side.size() == 2:
		$AttackerAnimations.play("fighting_2")
	else:
		$AttackerAnimations.play("fighting_3")
	if defender_side.size() == 2:
		$DefenderAnimations.play("fighting_2")
	else:
		$DefenderAnimations.play("fighting_3")
	
	vigor_mod = attacker_side.size() * 100 #calculate based on an average unit of 100 vigor
	if attacker_vigor >= vigor_mod * 0.80: #side has high vigor (over 80%)
		attacker_strength *= 1.10 #10% dmg bonus
	elif attacker_vigor >= vigor_mod * 0.50: #side has average vigor (80% - 50%)
		attacker_strength *= 1.0 #no mods
	elif attacker_vigor >= vigor_mod * 0.25: #side has low vigor (25% - 7%)
		attacker_strength *= 0.85 #20% damage debuff
	else: #side has devastated vigor (below 7%)
		attacker_vigor *= 0.50 #50% damage debuff
	attacker_strength *= tileManager.get_tile_attacker_mod(global_position)
	
	vigor_mod = defender_side.size() * 100
	if defender_vigor >= vigor_mod * 0.80:
		defender_strength *= 1.10
	elif defender_vigor >= vigor_mod * 0.50:
		defender_strength *= 1.0
	elif defender_vigor >= vigor_mod * 0.25:
		defender_strength *= 0.85
	elif defender_vigor >= vigor_mod * 0.07:
		defender_strength *= 0.50


func add_more_combatants(units):
	for unit in units:
		if unit.team == attacker_side.front().team:
			add_combatant(unit, 1)
		else:
			add_combatant(unit, 2)
	calculate_sides()



func update_turn():
	attacker_health -= defender_strength
	if attacker_health <= 0:
		defender_victory()
		return
	
	defender_health -= attacker_strength
	if defender_health <= 0:
		attacker_victory()
		return
	
	print(position, " fight, attackers = ", attacker_health, " defenders = ", defender_health)



func attacker_victory():
	for attacker in attacker_side:
		attacker.visible = true
		attacker.get_node("Area2D").input_pickable = true
		attacker.change_state(attacker.states.IDLE)
	for defender in defender_side:
		defender.eliminate()
	
	print("	attacker victory in ", position)
	turnManager.erase_from_working_list(self)
	queue_free()


func defender_victory():
	for attacker in attacker_side:
		attacker.eliminate()
	for defender in defender_side:
		defender.visible = true
		defender.get_node("Area2D").input_pickable = true
		defender.change_state(defender.states.IDLE)
	
	print("	defender victory in ", position)
	turnManager.erase_from_working_list(self)
	queue_free()
