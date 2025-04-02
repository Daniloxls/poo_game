extends "res://entities/player/player_script.gd"

var sudo = false

func get_sudo():
	return sudo

func set_sudo(mode):
	sudo = mode
