extends Node2D
# Personagem Padrão guarda informações e status de um personagem,
# os outros personagens extendem desse

# Sinal emitido quando a vida dele chega a zero
signal death
# sinal emitido quando ele acaba uma animação
signal animation_end
# sinal emitido quando a vida é alterada
signal health_change

signal select_targets

signal button_mouse_in
signal button_mouse_out

signal sprite_clicked
signal mouse_in
signal mouse_out

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite
# 'damage_text' dano que o personagem tomou aparece nessa label
@onready var damage_text = $DamageText
@onready var char_pic = $CharPic
@onready var battle_options = $BattleOptions

enum State{
	DEFAULT,
	ACTED,
	ANIMATION,
	DEFEATED
}
var current_state = State.DEFAULT

# Status de teste para o personagem
var nome : String
var rpg_class : RPG_CLASS
var hp : int
var max_hp : int
var pp : int
var max_pp  : int
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
	
func get_state():
	return current_state
	
func set_state(new_state):
	current_state = new_state
	
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
	
func get_pp():
	return pp

func get_max_pp():
	var current_max_pp = max_pp
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
	
func get_pic():
	var pic = char_pic.get_texture()
	return pic
	
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
	var old_hp = hp
	for equip in equipment.keys():
		if equipment[equip]:
			current_max_hp += equipment[equip].get_hp_bonus()
	hp += value
	if hp > current_max_hp:
		value = current_max_hp - old_hp
		hp = current_max_hp
	animation.play("heal")
	return value
	
# Função de receber dano
func take_damage(value):
	var current_max_hp = get_max_hp()
	hp -= value
	#Checa se o personagem morreu
	if hp < 0:
		hp = 0
	if hp == 0:
		# toca animação de morte e emite o sinal
		animation.play("death")
		set_state(State.DEFEATED)
		death.emit()
	else:
		# se o personagem ainda estiver vivo só toca a animação de receber dano
		animation.play("get_hit")
	#Numero do dano aparece na tela conforme o dano é tomado
	damage_text.number_animation(value)
	# retorna porcentagem do hp
	return -value

func connect_action_buttons():
	for button in battle_options.get_children():
		button.connect("select_target", _on_button_select_targets)
		button.connect("mouse_in", _on_button_mouse_in)
		button.connect("mouse_out", _on_button_mouse_out)

func _on_button_select_targets(targets, id, char_node):
	select_targets.emit(targets, id, char_node)
	
func _on_button_mouse_in(skill_name):
	button_mouse_in.emit(skill_name)

func _on_button_mouse_out():
	button_mouse_out.emit()
	

func set_hp(new_hp):
	hp = new_hp

func set_animation(anim):
	animation.play(anim)

func set_equip(slot, equip_item):
	equipment[slot] = equip_item

func get_equip(slot):
	return equipment[slot]

func get_strict_max_hp():
	return max_hp
func get_strict_max_pp():
	return max_pp
func get_strict_atk():
	return atk
func get_strict_def():
	return def
func get_strict_vel():
	return vel

func execute_skill(id, targets):
	battle_options.get_child(id).execute_skill(targets, self)
	set_state(State.ACTED)

func show_options():
	battle_options.show()

func hide_options():
	battle_options.hide()

func default_state():
	current_state = State.DEFAULT

		
func on_sprite_clicked():
	sprite_clicked.emit(get_index())

func on_sprite_mouse_in():
	mouse_in.emit(self.nome)

func on_sprite_mouse_out():
	mouse_out.emit()


func set_acted(option):
	if option:
		set_state(State.ACTED)
	else:
		set_state(State.DEFAULT)



func _on_animation_player_animation_finished(anim_name):
	if anim_name != "default":
		animation_end.emit()
