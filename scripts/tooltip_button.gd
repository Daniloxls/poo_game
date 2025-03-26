extends Node2D

@onready var label = $MarginContainer/HBoxContainer/RichTextLabel
@onready var button = $MarginContainer/HBoxContainer/Button
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_button_pressed():
	label.show()
	button.hide()
	pass # Replace with function body.

func set_text(text):
	label.text = text

func reset():
	label.hide()
	button.show()
