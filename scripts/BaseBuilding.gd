extends Position2D

onready var playerTeamManager = get_tree().get_root().get_node("Main/PlayerTeamManager")
onready var turnManager = get_tree().get_root().get_node("Main/TurnManager")
var base_unit = preload("res://scenes/BaseUnit.tscn")
var manager = null
var gold_gen = 4
var level = 1
var seize_progress = 0

func _ready():
	if is_in_group("player"):
		$BuildingSprite.modulate = Color.white
		manager = playerTeamManager
	elif is_in_group("enemy"):
		$BuildingSprite.modulate = Color.red
		manager = null
	turnManager.append_to_working_list(self)

func update_turn():
	pass
