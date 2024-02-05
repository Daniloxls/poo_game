extends Node2D

var size
var items = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_items():
	var item_names = []
	for item in items:
		item_names.append(item.get_name())
