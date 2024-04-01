extends Node2D
@onready var area = $Area2D
@onready var portal = $Portal/Sprite
@onready var espinhos = $Espinhos/Sprite
@onready var estatica = $ScreenFlash
@onready var estatica_sprite = $ScreenFlash/Sprite
@onready var player = get_node("../Player")
@onready var codebox = get_node("../Codebox")

var triggered = false
# Called when the node enters the scene tree for the first time.
func _ready():
	area.monitoring = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_2d_area_entered(area):
	pass # Replace with function body.
