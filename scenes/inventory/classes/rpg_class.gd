extends Resource
class_name RPG_CLASS


@export var CLASS_NAME : String
@export var ATK_BONUS : int
@export var DEF_BONUS : int
@export var VEL_BONUS : int
@export var SKILLS : Array[SKILL]

func get_class_name():
	return CLASS_NAME

func get_skills():
	return SKILLS
