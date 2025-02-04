extends Resource
class_name SKILL


enum Targets {
	NONE,
	SELF,
	ALLY,
	ENEMY,
	ITE,
	ALL_ALLY,
	ALL_ENEMY,
	EVERYONE
}
@export var SKLL_NAME : String
@export var TARGET : Array[Targets]
@export var DESCRIPTION : String
@export var IS_OVERRIDE : bool
@export var SKILL_SCRIPT : GDScript

func get_skill_name():
	return SKLL_NAME

func get_target():
	return TARGET
	
func get_description():
	return DESCRIPTION

func get_target_argument():
	var argument = []
	for i in TARGET:
		match i:
			Targets.NONE:
				return argument
			Targets.SELF:
				return argument
			Targets.ALLY:
				argument.append("Aliado")
			Targets.ENEMY:
				argument.append("Inimigo")
			Targets.ITE:
				argument.append("Item")
			Targets.ALL_ALLY:
				argument.append("Aliado[]")
			Targets.ALL_ENEMY:
				argument.append("Inimigo[]")
			Targets.EVERYONE:
				argument.append("Personagem[]")
				
	return argument
			

func get_skill_script():
	return SKILL_SCRIPT
