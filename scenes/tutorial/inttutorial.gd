extends Node2D
@onready var pit = $Pit
@onready var ponte_interact = $Ponte/Area2D
@onready var ponte_colision =  $Ponte/StaticBody2D
@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox


# Called when the node enters the scene tree for the first time.
func _ready():
	ponte_colision.set_collision_layer_value(1, false)
	ponte_interact.set_texto(["Está quebrada"])
	ponte_interact.set_codigo("Ponte", {"1int tamanho" : 1})
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass
