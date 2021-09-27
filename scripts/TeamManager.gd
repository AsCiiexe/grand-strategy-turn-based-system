extends Node2D

#This takes care of each faction's resources and modifiers
#It will eventually also take care of diplomacy and territory, maybe even population

onready var turnManager = get_tree().get_root().get_node("Main/TurnManager")
onready var playerManager = get_tree().get_root().get_node("Main/Cursor")
var team = "NO TEAM ASSIGNED"
var gold = 0
var gold_gen = 0
var gold_consumption = 0
var military_goods = 0
var mg_gen = 0
var mg_consumption = 0
var show_balance = false


func _ready():
	gold = 100
	gold_gen = 4
	military_goods = 60
	mg_gen = 2.5
	turnManager.append_to_working_list(self)
	team = get_groups()[0]
	print(self, " team = ", team)

func update_turn():
	gold += gold_gen - gold_consumption
	military_goods += mg_gen - mg_consumption
	if show_balance:
		print(team, " gold = ", gold, "(", gold_gen - gold_consumption,
			   ") military gods = ", military_goods, "(", mg_gen - mg_consumption, ")" )
	else:
		print(team, " gold = ", gold, " military goods = ", military_goods)
	
