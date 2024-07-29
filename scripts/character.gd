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
var nome : String
var rpg_class : RPG_CLASS
var hp : int
var max_hp : int
var mp : int
var max_mp  : int
var level : int
var atk : int
var def : int
var vel : int
var xp : int
var original_pos
var xp_needed = [0,100,300,650,1200,2000,3000,4200,5600]


var equipment = {
	"head_slot" : null,
	"body_slot" :  null,
	"feet_slot" : null,
	"lhand_slot" : null,
	"rhand_slot" :  null,
	"acessory_slot" : null
}
# Called when the node enters the scene tree for the first time.
func _ready():
	#healthbar.hide()
	animation.play("default")
	original_pos = get_position()
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
	size = size * sprite.get_scale()
	return(Vector2(position) + Vector2(0, size.y))

# Mesma função só que pega a parte direita do sprite
func get_turn_cursor_pos():
	var current_animation : String = $Sprite.animation
	var sprite_texture : Texture2D = $Sprite.sprite_frames.get_frame_texture(current_animation, 0)
	var size = sprite_texture.get_size()
	size = size * sprite.get_scale()
	return(Vector2(position) + Vector2(size.x, size.y))
	
func get_nome():
	return nome

func get_hp():
	return hp

func get_max_hp():
	var current_max_hp = max_hp
	for equip in equipment.keys():
		if equipment[equip]:
			current_max_hp += equipment[equip].get_hp_bonus()
	return current_max_hp
	
func get_mp():
	return mp

func get_max_mp():
	var current_max_pp = max_mp
	for equip in equipment.keys():
		if equipment[equip]:
			current_max_pp += equipment[equip].get_pp_bonus()
	return current_max_pp
	
func get_health_percentage():
	var current_max_hp = max_hp
	for equip in equipment.keys():
		if equipment[equip]:
			current_max_hp += equipment[equip].get_hp_bonus()
	return float(hp)/current_max_hp

func get_level():
	return level

func get_xp():
	return xp

func get_next_level_xp():
	if level >= 9:
		return 99999
	return xp_needed[level] - xp
	
func get_atk():
	var current_atk = atk
	for equip in equipment.keys():
		if equipment[equip]:
			current_atk += equipment[equip].get_atk_bonus()
	return current_atk

func get_def():
	var current_def = def
	for equip in equipment.keys():
		if equipment[equip]:
			current_def += equipment[equip].get_def_bonus()
	return current_def
	
func get_vel():
	var current_vel = vel
	for equip in equipment.keys():
		if equipment[equip]:
			current_vel += equipment[equip].get_vel_bonus()
	return current_vel
	
func get_skills():
	return rpg_class.get_skills()
	
func get_class_name():
	return rpg_class.get_class_name()
	
func get_sprite():
	var frameIndex: int = sprite.get_frame()
	var animationName: String = sprite.animation
	var spriteFrames: SpriteFrames = sprite.get_sprite_frames()
	var currentTexture: Texture2D = spriteFrames.get_frame_texture(animationName, frameIndex)
	return currentTexture
	
	
func reset_position():
	set_position(original_pos)
	
func is_alive():
	if hp> 0:
		return true
	else:
		return false

# Função de cura do personagem, toca animação de cura e retorna porcentagem da vida atual
func gain_health(value):
	var current_max_hp = max_hp
	for equip in equipment.keys():
		if equipment[equip]:
			current_max_hp += equipment[equip].get_hp_bonus()
	hp += value
	if hp > current_max_hp:
		hp = current_max_hp
	animation.play("heal")
	return float(hp)/current_max_hp
	
# Função de receber dano
func lose_health(value):
	var current_max_hp = max_hp
	for equip in equipment.keys():
		if equipment[equip]:
			current_max_hp += equipment[equip].get_hp_bonus()
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
	return float(hp)/current_max_hp

# emite o sinal de fim de animação quando recebe o sinal da barra de vida
# Usado no monstro mas não aqui, remover depois
func _on_healthbar_animation_end():
	animation_end.emit()

func set_hp(new_hp):
	hp = new_hp

func set_animation(anim):
	animation.play(anim)

func set_equip(slot, equip_item):
	equipment[slot] = equip_item
