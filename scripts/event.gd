extends Node2D
# event é um nó que faz uma função quando um nó entra na sua area
# esse é o script base, todos eventos devem extender ele
@onready var area = $Area2D
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

# Quando uma area2d entra na area do evento ele roda essa função
func _on_area_2d_area_entered(area):
	pass # Replace with function body.
