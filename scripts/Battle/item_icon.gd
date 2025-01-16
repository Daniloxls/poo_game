extends TextureRect

var can_click:bool

var nome = "item()"

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_mouse") and can_click:
		get_parent().check_icon(nome)

func _on_mouse_entered() -> void:
	can_click = true
	var attack_tween:Tween = create_tween()
	attack_tween.tween_property(self,"modulate:a",0.5,0.1)

func _on_mouse_exited() -> void:
	var attack_tween:Tween = create_tween()
	attack_tween.tween_property(self,"modulate:a",1,0.1)
	if !Input.is_action_just_pressed("left_mouse") and can_click:
		can_click = false
