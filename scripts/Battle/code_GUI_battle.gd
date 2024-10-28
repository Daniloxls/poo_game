extends TextureRect

@onready var code_label:Label = get_node("Label")

func _on_detection_icon_area_entered(area: Area2D) -> void:
	if area.is_in_group("Icon_Movement"):
		code_label.text = "void ação(){
%s

}" %area.get_parent().nome
		area.get_parent().hide()
