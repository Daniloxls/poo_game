extends VBoxContainer

@onready var attack_icon:TextureRect = get_node("Attack")
@onready var defend_icon:TextureRect = get_node("Defend")
@onready var run_icon:TextureRect = get_node("Run")
@onready var item_icon:TextureRect = get_node("Item")

@onready var code = $"../../Battle_Panel/Code"

var can_click:bool

var movement_icon:TextureRect

func check_icon(icon_name:String)->void:
	match icon_name:
		"atacar()":
			code.update_text(icon_name)
		"defender()":
			code.update_text(icon_name)
		"fugir()":
			code.update_text(icon_name)
		"item()":
			code.update_text(icon_name)
