extends "res://scripts/event.gd"


func _on_area_2d_area_entered(area):
	if !player.get_sudo() or triggered:
		return
	else:
		triggered = true
		textbox.queue_char_text(["Você ativou suas habilidades de desenvolvedor, agora você vai ver como as coisas realmente funcionam no seu mundo.",
		"Agora tente abrir aquela porta, aperte C enquanto olha para ela e você verá o código que ela contém."],
		["res://assets/portraits/silhueta.png",
		"res://assets/portraits/silhueta.png"])
