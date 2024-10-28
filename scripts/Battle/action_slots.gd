extends VBoxContainer

@onready var attack_icon:TextureRect = get_node("Attack")
@onready var defend_icon:TextureRect = get_node("Defend")
@onready var run_icon:TextureRect = get_node("Run")
@onready var item_icon:TextureRect = get_node("Item")

var can_click:bool

var movement_icon:TextureRect

func check_icon(icon_name:String)->void:
	match icon_name:
		"atacar()":
			defend_icon.can_click = false
		"defender()":
			attack_icon.can_click = false
