extends "res://scripts/event.gd"
@onready var kath = get_node("../Kath")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_area_2d_area_entered(area):
	if triggered == false:
		triggered = true
		var tween = create_tween()
		tween.tween_callback(kath.set_sprite.bind("walk_up"))
		tween.tween_property(kath, "position",Vector2(900, -26000), 2.5)
		tween.tween_callback(kath.set_process_mode.bind(PROCESS_MODE_DISABLED))
	
