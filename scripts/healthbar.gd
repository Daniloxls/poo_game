extends Node2D

# healthbar é o script que mosta a vida dos inimigos quando eles tomam dano
# tambem é responsavel por mostrar o numero do dano da mesma forma que DamageText
# Esse scrip junta os dois em uma animação só e é usado para os inimigos apenas
signal animation_end

@onready var green_bar = $HBoxContainer/Green
@onready var red_bar = $HBoxContainer/Red


func change_hp_percent(percentage, damage):
	var tween = create_tween()

	tween.set_parallel()
	tween.tween_property(green_bar, "size_flags_stretch_ratio", percentage, 0.8)
	tween.tween_property(red_bar, "size_flags_stretch_ratio", 1 - percentage, 0.8)
	tween.set_parallel(false)
	tween.tween_callback(hide)
	tween.tween_callback(end_animation)

func end_animation():
	animation_end.emit()



func _on_sprite_2d_mouse_entered():
	show()


func _on_sprite_2d_mouse_exited():
	hide()
