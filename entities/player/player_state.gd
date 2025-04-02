extends Node2D

var on_dialogue = false
var on_scene = false
var on_interface = false

	
func is_able_to_move()-> bool:
	if on_dialogue or on_interface or on_scene:
		return false
	return true
	
func set_on_dialogue(dialogue):
	on_dialogue = dialogue

func set_on_interface(interface):
	on_interface = interface

func set_on_scene(scene):
	on_scene = scene

func is_on_dialogue():
	return on_dialogue

func is_on_interface():
	return on_interface

func is_on_scene():
	return on_scene
