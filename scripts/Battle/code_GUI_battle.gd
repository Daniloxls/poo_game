extends TextureRect

@onready var code_label:Label = get_node("Label")


func update_text(icon_name:String)->void:
	code_label.text = "void ação(){
		%s
	}" %icon_name
