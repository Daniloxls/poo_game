extends "res://scenes/main/scripts/event.gd"

func _on_area_2d_area_entered(area):
	if triggered:
		return
	else:
		triggered = true
		Textbox.queue_char_text(["Muito bem, parece que tem uma ponte quebrada a seguir...",
		"Veja o código dela, talvez haja algo que possamos fazer."],
		["res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png"])
