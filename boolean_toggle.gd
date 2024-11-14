extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_value(value):
	self.set_toggle_mode(true)
	connect("toggled", _on_toggled)
	if value:
		self.set_text("true;")
	else:
		self.set_text("false;")
	self.button_pressed = value

func _on_toggled(toggled_on):
	if toggled_on:
		self.set_text("true;")
	else:
		self.set_text("false;")

func set_editable(value):
	return
