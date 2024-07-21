extends Control

signal on_hover
@onready var button = $Button

var item : ITEM
# Called when the node enters the scene tree for the first time.
func _ready():
	set_item(load("res://scenes/itens/repo/armadura_ferro.tres"))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_item(new_item : ITEM):
	item = new_item
	button.set_button_icon(item.get_icon())
	
func _on_button_mouse_entered():
	on_hover.emit(item)


