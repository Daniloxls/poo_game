extends Node2D

var shown = false
# Called when the node enters the scene tree for the first time.
func _ready():
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("x"):
		hide()


func _on_codebox_code_open():
	if !shown:
		shown = true
		show()
