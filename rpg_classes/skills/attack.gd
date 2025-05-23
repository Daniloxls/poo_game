extends "res://scenes/party/scripts/skill_button.gd"



func execute_skill(targets, character):
	var target = targets[0]
	var char_atk = character.get_atk()
	var char_vel = character.get_vel()
	var target_def = target.get_def()
	var target_vel = target.get_vel()
	
	if target_vel >= randi_range(char_vel + 0, char_vel + 256):
		target.miss()
		skill_end.emit()
		return
	else:
		var damage 
		damage = char_atk * randf_range(1.17 , 1.56)
		damage = damage * (1 - (target_def/ 512))
		if randi_range(0, 853) <= char_vel:
			damage = damage * 2

		target.take_damage(int(damage))
		skill_end.emit()
