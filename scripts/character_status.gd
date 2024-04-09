extends Node2D

#character_status é cada linha com informações dos personagens no menu de batalha
# ela mostra a barra de vida e a quantidade de pp

# sinal de fim de animação
signal animation_end

# 'nome' e 'mana_value' são labels com os valores respectivos
@onready var nome = $Name
@onready var mana_value = $Mana

# 'health_percentage' é a barra verde de vida
@onready var health_percentage = $Life1


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_nome(char_nome):
	nome.set_text(char_nome)

# Muda o tamanho da barra de vida sem transição
func set_health_instant(percentage):
	health_percentage.set_scale(Vector2(percentage, 1))
	
# Muda a quantidade de pp sem transição
func set_mana_instant(value):
	mana_value.set_text("MP "+ str(value))

# Muda o tamanho da barra de vida com transição
func set_health_slow(percentage):
	var tween = create_tween()
	tween.tween_property(health_percentage, "scale", Vector2(percentage, 1), 0.8).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(end_animation)
	
# Muda a quantidade de pp com transição
func set_mana_slow(value):
	var current_value = get_current_mp()
	var tween = create_tween()
	tween.tween_method(set_mana_instant, current_value, value, 0.8).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(end_animation)
	
# corta a string que contem o pp e retorna só o valor atual
func get_current_mp():
	return int(mana_value.text.erase(0 , 3))

# Função que emite o sinal de fim de animação
func end_animation():
	animation_end.emit()
