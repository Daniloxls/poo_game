extends Node2D
# Personagem Padrão guarda informações e status de um personagem,
# os outros personagens extendem desse

# Sinal emitido quando a vida dele chega a zero
signal death
# sinal emitido quando ele acaba uma animação
signal animation_end
# sinal emitido quando a vida é alterada
signal health_change

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite
# 'damage_text' dano que o personagem tomou aparece nessa label
@onready var damage_text = $DamageText

# Status de teste para o personagem
var nome = "Turin"
var hp = 32
const MAX_HP = 32
var mp = 32
const MAX_MP = 32
var level = 1
var xp = 0
var original_pos = get_position()

# Called when the node enters the scene tree for the first time.
func _ready():
	#healthbar.hide()
	animation.play("default")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# funções que tocam animações,
# mudar para uma função que recebe um argumento e toca a animação apropiada
func hit_animation():
	animation.play("get_hit")

func heal_animation():
	animation.play("heal")
	
# Função que retorna a coordenada que o cursor deve ficar para apontar para esse personagem
func get_cursor_pos():
	var current_animation : String = $Sprite.animation
	var sprite_texture : Texture2D = $Sprite.sprite_frames.get_frame_texture(current_animation, 0)
	var size = sprite_texture.get_size()
	return(Vector2(position) + Vector2(0, size.y/3))

# Mesma função só que pega a parte direita do sprite
func get_turn_cursor_pos():
	var current_animation : String = $Sprite.animation
	var sprite_texture : Texture2D = $Sprite.sprite_frames.get_frame_texture(current_animation, 0)
	var size = sprite_texture.get_size()
	return(Vector2(position) + Vector2(size.x, size.y/3))
	
func get_nome():
	return nome

func get_hp():
	return hp

func get_max_hp():
	return MAX_HP
	
func get_mp():
	return mp

func get_max_mp():
	return MAX_MP
	
func get_health_percentage():
	return float(hp)/MAX_HP

func get_level():
	return level

func reset_position():
	set_position(original_pos)
	
func is_alive():
	if hp> 0:
		return true
	else:
		return false

# Função de cura do personagem, toca animação de cura e retorna porcentagem da vida atual
func gain_health(value):
	hp += value
	if hp > MAX_HP:
		hp = MAX_HP
	animation.play("heal")
	return float(hp)/MAX_HP
	
# Função de receber dano
func lose_health(value):
	hp -= value
	#Checa se o personagem morreu
	if hp < 0:
		hp = 0
	if hp == 0:
		# toca animação de morte e emite o sinal
		animation.play("death")
		death.emit()
	else:
		# se o personagem ainda estiver vivo só toca a animação de receber dano
		animation.play("get_hit")
	#Numero do dano aparece na tela conforme o dano é tomado
	damage_text.number_animation(value)
	# retorna porcentagem do hp
	return float(hp)/MAX_HP

# emite o sinal de fim de animação quando recebe o sinal da barra de vida
# Usado no monstro mas não aqui, remover depois
func _on_healthbar_animation_end():
	animation_end.emit()
	pass # Replace with function body.
