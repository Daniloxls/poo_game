extends Node2D

@onready var colision = $StaticBody2D
@onready var area = $Area2D
@onready var player = get_node("../Player")
@onready var codebox = get_node("../Codebox")
@onready var map = get_node("../TileMap")
@onready var pit = get_node("../Pit")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("exit"):
		pit.set_size(area.depure()["1int tamanho"])
	pass
