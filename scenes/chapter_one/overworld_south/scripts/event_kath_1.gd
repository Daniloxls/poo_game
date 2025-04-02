extends "res://scenes/main/scripts/event.gd"

@onready var kath: CharacterBody2D = $"../Path2D/PathFollow2D/Kath"
@onready var path_follow_2d: PathFollow2D = $"../Path2D/PathFollow2D"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_area_2d_area_entered(area):
	if !triggered and kath.get_seq() == 2:
		triggered = true
		var tween = create_tween()
		tween.tween_callback(kath.set_sprite.bind("walk_up"))
		tween.tween_property(path_follow_2d, "progress_ratio", 1, 1.8)
		tween.tween_callback(kath.set_process_mode.bind(PROCESS_MODE_DISABLED))
	
