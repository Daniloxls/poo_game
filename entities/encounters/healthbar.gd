extends Node2D

# healthbar é o script que mosta a vida dos inimigos quando eles tomam dano
# tambem é responsavel por mostrar o numero do dano da mesma forma que DamageText
# Esse scrip junta os dois em uma animação só e é usado para os inimigos apenas
signal animation_end

@onready var sprite_2d = $"../Sprite2D"
@onready var progress_bar = $HBoxContainer/ProgressBar
@onready var enemy_name = $TabBar/Enemy_Name
@onready var enemy_hp_text = $HBoxContainer/ProgressBar/EnemyHp

var enemy_max_hp
var enemy_hp

func set_values():
	sprite_2d.connect("mouse_entered", _on_sprite_2d_mouse_entered)
	sprite_2d.connect("mouse_exited", _on_sprite_2d_mouse_exited)
	enemy_name.set_name(get_parent().name)
	enemy_max_hp = get_parent().get_max_hp()
	enemy_hp = enemy_max_hp
	enemy_hp_text.set_text(str(enemy_max_hp) + "/" + str(enemy_max_hp))

func change_hp_percent(percentage, damage):
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(progress_bar, "value", percentage * 100, 0.8)
	tween.tween_method(set_hp_text, enemy_hp, enemy_hp+damage, 0.8)
	tween.set_parallel(false)
	tween.tween_interval(3)
	tween.tween_callback(hide)
	tween.tween_callback(end_animation)
	enemy_hp += damage

func end_animation():
	animation_end.emit()

func set_enemy_hp_bar_name(name):
	enemy_name.name = name

func _on_sprite_2d_mouse_entered():
	show()


func _on_sprite_2d_mouse_exited():
	hide()

func set_hp_text(value):
	enemy_hp_text.set_text(str(value) + "/" + str(enemy_max_hp))
