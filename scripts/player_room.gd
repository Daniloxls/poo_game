extends Node2D
@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var brilho = $Brilho

# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = create_tween()
	tween.tween_property(brilho, "modulate",Color(255, 255, 255, 0), 3).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(textbox.queue_char_text.bind(["Que sonho esquisito"], [""]))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
