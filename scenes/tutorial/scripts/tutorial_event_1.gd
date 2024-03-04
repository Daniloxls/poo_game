extends Node2D
@onready var area = $Area2D
@onready var player = get_node("../Player")
@onready var textbox = get_node("../Textbox")
@onready var map = get_node("../TileMap")
var triggered = false
# Called when the node enters the scene tree for the first time.
func _ready():
	area.monitoring = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_2d_area_entered(area):
	if !player.get_sudo() or triggered:
		return
	else:
		triggered = true
		textbox.queue_char_text(["Você ativou suas habilidades de desenvolvedor, agora você vai ver como as coisas realmente funcionam no seu mundo",
		"Tente abrir aquela porta agora, aperte C enquanto olha para ela e você verá o codigo que ela contem"],
		["res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png"])
	pass # Replace with function body.
