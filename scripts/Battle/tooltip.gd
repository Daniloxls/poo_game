extends PanelContainer

@onready var tooltip_label = $TooltipText

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_tooltip_label(text : String):
	tooltip_label.clear()
	tooltip_label.append_text("[center]")
	tooltip_label.append_text(text)
