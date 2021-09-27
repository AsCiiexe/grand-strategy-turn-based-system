extends CanvasLayer

onready var resourceLabel = get_node("Panel/ResourceLabel")
onready var teamManager = get_tree().get_root().get_node("Main/PlayerTeamManager")
onready var playerManager = get_tree().get_root().get_node("Main/Cursor")
onready var turnManager = get_tree().get_root().get_node("Main/TurnManager")
onready var timeSprite = get_node("Panel/Time")

var pause_sprite = preload("res://pause.png")
var play_sprite = preload("res://play.png")
var label_text = "Gold = 0 \nMil goods = 0"
var count = 0

func _ready():
	resourceLabel.text = label_text

func _physics_process(delta): #NOTE: THIS SHOULD BE TEMPORARY attach an update to this node to whenever a resource changes
	count += 1
	if count % 15 == 0:
		label_text = str("Gold = ", teamManager.gold, "\nMil goods = ", teamManager.military_goods)
		resourceLabel.text = label_text


func set_time_sprite(time):
	if time == "pause":
		timeSprite.texture = pause_sprite
	else:
		timeSprite.texture = play_sprite
