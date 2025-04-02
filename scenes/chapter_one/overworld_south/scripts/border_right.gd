extends "res://scenes/main/scripts/event.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	Textbox.connect("text_finish", _on_textbox_text_finish)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_area_2d_area_entered(area):
	triggered = true
	PlayerState.set_on_scene(true)
	player.set_sprite("idle_right")
	Textbox.queue_text(["Vamos logo Turin, a gente tá perdendo tempo!"])


func _on_textbox_text_finish():
	if triggered:
		var tween = create_tween()
		tween.tween_callback(player.set_sprite.bind("walk_left"))
		tween.tween_property(player, "position", (player.get_position() - Vector2(400, 0)), 0.5)
		tween.tween_callback(player.set_sprite.bind("idle_left"))
		tween.tween_callback(PlayerState.set_on_scene.bind(false))
		tween.tween_callback(reset_trigger)
	pass # Replace with function body.

func reset_trigger():
	triggered = false
