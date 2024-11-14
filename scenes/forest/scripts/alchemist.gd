extends "res://scripts/npc_script.gd"

@onready var arbusto_area:Node2D = get_node("../Bushes/ArbustoArea")
@onready var bush:CharacterBody2D = get_node("../Bushes/Bush")

var scene:bool = false
var triggered:bool = false
var burned:bool = false

func interaction():
	if !scene and !burned:
		textbox.queue_text(["A magia do POO é tão poderosa que você pode manipular os objetos dentro de outros objetos"])
		triggered = true
		
	else:
		textbox.queue_text(["Parabéns. você liberou o caminho!!"])


func _on_textbox_text_finish() -> void:
	if triggered:
		textbox.display_choice("Você quer tentar abrir o caminho?", ["Sim", "Não"])
		
	elif scene:
		scene = false
		var comando = arbusto_area.get_methods()["0"][0].substr(5, arbusto_area.get_methods()["0"][2])
		print(comando)
		var result = evaluate(comando, "arbusto.queimar()")
		
		if result:
			burned = true
			bush.burn()

func _on_textbox_choise_closed() -> void:
	if triggered:
		triggered = false
		match(textbox.get_choice()):
			0:
				textbox.queue_text(["Certo se prepare para usar a magia"])
				scene = true
			1:
				textbox.queue_text(["Tudo bem, boa sorte então"])

func evaluate(command, variable_names:String) -> bool:
	if variable_names in command:
		return true
		
	else:
		return false
