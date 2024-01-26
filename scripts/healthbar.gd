extends Node2D

signal animation_end

@onready var green_bar = $Green 
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func change_hp_percent(percentage):
	var tween = create_tween()
	tween.tween_property(green_bar, "scale", Vector2(percentage, 1), 0.8)
	tween.tween_property(green_bar, "scale", Vector2(percentage, 1), 0.2)
	tween.tween_callback(hide)
	tween.tween_callback(end_animation)


func end_animation():
	animation_end.emit()
