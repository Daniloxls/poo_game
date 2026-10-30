extends "res://scenes/main/scripts/interact.gd"
## Baú do tutorial: dá uma Poção na primeira vez; depois está vazio.

signal aberto

const POCAO := preload("res://scenes/items/repo/potion.tres")
const FRAME_ABERTO := 1

var foi_aberto := false

@onready var sprite = $Sprite


func _ready():
	ready_drop_menu()


func interaction():
	if foi_aberto:
		Textbox.queue_text(["O baú está vazio."])
		return
	foi_aberto = true
	Inventory.mochila.adicionar(POCAO, 1)
	sprite.set_frame(FRAME_ABERTO)
	Textbox.queue_text(["Você encontrou uma Poção!"])
	aberto.emit()
