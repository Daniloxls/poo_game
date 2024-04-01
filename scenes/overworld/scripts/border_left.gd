extends "res://scripts/event.gd"
@onready var textbox = get_node("../Textbox")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_area_2d_area_entered(area):
	triggered = true
	player.set_in_scene(true)
	player.set_sprite("idle_left")
	textbox.queue_text(["Vamos logo Turin, a gente tá perdendo tempo!"])


func _on_textbox_text_finish():
	if triggered:
		var tween = create_tween()
		tween.tween_callback(player.set_sprite.bind("walk_right"))
		tween.tween_property(player, "position", (player.get_position() + Vector2(400, 0)), 0.5)
		tween.tween_callback(player.set_sprite.bind("idle_right"))
		tween.tween_callback(player.set_in_scene.bind(false))
		tween.tween_callback(reset_trigger)
	pass # Replace with function body.

func reset_trigger():
	triggered = false
