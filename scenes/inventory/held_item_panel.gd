extends PanelContainer

@onready var held_item_label = $MarginContainer/HeldItemLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_item_name(item_name : String):
	held_item_label.clear()
	held_item_label.push_color("#ffffff")
	held_item_label.add_text("Utilizando ")
	held_item_label.push_color("#bfbdb6")
	held_item_label.add_text(item_name)
