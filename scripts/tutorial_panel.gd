extends Node2D

@onready var canva = $CanvasLayer
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func hide_self():
	canva.hide()
	
func show_self():
	canva.show()
