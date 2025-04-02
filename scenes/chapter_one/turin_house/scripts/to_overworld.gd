extends "res://scenes/main/scripts/transition.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_area_2d_area_entered(area):
	var root = get_node("../../..")
	var next_level = load("res://scenes/chapter_one/overworld_south/OverworldSouth.tscn")
	var instance = next_level.instantiate()
	root.change_level(instance)
