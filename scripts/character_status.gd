extends Node2D

signal animation_end

@onready var nome = $Name
@onready var health_percentage = $Life1
@onready var mana_value = $Mana
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_nome(char_nome):
	nome.set_text(char_nome)

func set_health_instant(percentage):
	health_percentage.set_scale(Vector2(percentage, 1))
	
func set_mana_instant(value):
	mana_value.set_text("MP "+ str(value))

func set_health_slow(percentage):
	var tween = create_tween()
	tween.tween_property(health_percentage, "scale", Vector2(percentage, 1), 0.8).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(end_animation)
	
func set_mana_slow(value):
	var current_value = get_current_mp()
	var tween = create_tween()
	tween.tween_method(set_mana_instant, current_value, value, 0.8).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(end_animation)
	
func get_current_mp():
	return int(mana_value.text.erase(0 , 3))

func end_animation():
	animation_end.emit()
