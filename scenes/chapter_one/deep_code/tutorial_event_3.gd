extends "res://scenes/main/scripts/event.gd"


func _on_area_2d_area_entered(area):
	if triggered:
		return
	else:
		triggered = true
		Textbox.queue_char_text(["Ótimo, você só precisa atravessar essa porta e deve chegar onde estou."],
		["res://assets/portraits/silhueta.png"])
