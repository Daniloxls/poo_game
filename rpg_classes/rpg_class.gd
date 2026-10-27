extends Resource
class_name RPG_CLASS


@export var CLASS_NAME : String
@export var HP_BONUS : int
@export var PP_BONUS : int
@export var ATK_BONUS : int
@export var DEF_BONUS : int
@export var VEL_BONUS : int
## Ações da batalha.
@export var SKILLS : Array[SKILL]
## Habilidades da classe mostradas no menu; a batalha ainda não as usa.
@export var HABILIDADES : Array[SKILL]
## Aparece na troca de classe do menu.
@export var JOGAVEL : bool
## Cor provisória do personagem nesta classe, até ter os sprites próprios.
@export var COR : Color = Color.WHITE

func get_class_name():
	return CLASS_NAME

func get_skills():
	return SKILLS


static func jogaveis() -> Array[RPG_CLASS]:
	var out: Array[RPG_CLASS] = []
	for f in ResourceLoader.list_directory("res://rpg_classes/"):
		if f.ends_with(".tres"):
			var c = load("res://rpg_classes/" + f)
			if c is RPG_CLASS and c.JOGAVEL:
				out.append(c)
	out.sort_custom(func(a, b): return a.CLASS_NAME < b.CLASS_NAME)
	return out
