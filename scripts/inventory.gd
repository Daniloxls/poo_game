extends CanvasLayer

@onready var party = $Party
@onready var party_container = $MenuContents/HBoxContainer/PartyContainer
@onready var background = $MenuBackground
@onready var content = $MenuContents
@onready var player = get_node("../Level").get_child(0).get_child(2)

var size
var items : Array[ITEM] = [load("res://scenes/itens/repo/potion.tres"),
							load("res://scenes/itens/repo/armadura_ferro.tres"),
							load("res://scenes/itens/repo/armadura_couro.tres")]

# Called when the node enters the scene tree for the first time.
func _ready():
	update_group()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_input()
	pass

func get_items():
	return items

func update_group():
	for i in party_container.get_children():
		i.hide()
	var party_ui = party_container.get_children()
	for i in len(party.get_children()):
		party_ui[i].show()
		party_ui[i].update_char(party.get_children()[i])
		
func get_party():
	return party

func aparecer():
	update_group()
	background.show()
	content.show()
	player.set_movement(false)

func esconder():
	background.hide()
	content.hide()
	player.set_movement(true)
	
func process_input():
	if Input.is_action_just_pressed("x"):
		esconder()
