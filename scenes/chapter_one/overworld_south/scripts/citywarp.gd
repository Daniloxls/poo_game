extends Node2D
@onready var area = $Area2D
@onready var player = get_node("../Player")

var triggered = false


func _ready():
	area.monitoring = true


func _on_area_2d_area_entered(area):
	LevelWarp.change_level("res://scenes/chapter_one/festival_city/City.tscn")
