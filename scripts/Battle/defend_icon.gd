extends TextureRect

var can_click:bool

var position_default:Vector2 
var global_position_default:Vector2 

var nome = "defender()"

func _ready() -> void:
	position_default = position

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("left_mouse") and can_click:
		global_position = get_global_mouse_position() - Vector2(130,16)
	elif !can_click:
		position = position_default
		global_position = global_position_default
	
func _on_mouse_entered() -> void:
	can_click = true
	var attack_tween:Tween = create_tween()
	attack_tween.tween_property(self,"modulate:a",0.5,0.1)

func _on_mouse_exited() -> void:
	var attack_tween:Tween = create_tween()
	attack_tween.tween_property(self,"modulate:a",1,0.1)
	if !Input.is_action_pressed("left_mouse") and can_click:
		can_click = false
