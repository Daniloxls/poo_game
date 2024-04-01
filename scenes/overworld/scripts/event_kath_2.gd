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
		tween.tween_callback(kath.set_seq.bind(1))
		tween.tween_callback(kath.set_sprite.bind("walk_up"))
		tween.tween_property(kath, "position",Vector2(4500, -13500), 2.5)
		tween.tween_callback(kath.set_sprite.bind("walk_left"))
		tween.tween_property(kath, "position",Vector2(900, -13500), 1)
		tween.tween_callback(kath.set_sprite.bind("walk_up"))
		tween.tween_property(kath, "position",Vector2(900, -21800), 2)
		tween.tween_callback(kath.set_sprite.bind("idle_down"))
	
