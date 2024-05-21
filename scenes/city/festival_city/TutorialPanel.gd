extends CanvasLayer
@onready var button = $Button
@onready var panel = $Panel
var shown = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("z"):
		panel.hide()
		

func _on_codebox_code_open():
	if !shown:
		shown = true
		panel.show()
	
	button.show()


func _on_codebox_code_closed():
	button.hide()


func _on_button_pressed():
	panel.show()
