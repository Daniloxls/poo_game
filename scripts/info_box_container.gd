extends VBoxContainer

@onready var item_info_label = $ItemDescriptionContainer/ItemInfoContainer/ItemInfoLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_info_text(text : String):
	item_info_label.set_text(text)
