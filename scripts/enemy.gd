extends Node2D

# scrip que deve ser a base para todos os inimigos

# sinais de morte e fim de animação
signal death
signal animation_end

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite
@onready var healthbar = $Healthbar

# variaveis temporarias de teste
var nome
var hp
var max_hp

# Called when the node enters the scene tree for the first time.
func _ready():
	#healthbar.hide()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func hit_animation():
	animation.play("get_hit")
	
func get_cursor_pos():
	var current_animation : String = $Sprite.animation
	var sprite_texture : Texture2D = $Sprite.sprite_frames.get_frame_texture(current_animation, 0)
	var size = sprite_texture.get_size()
	size = size * sprite.get_scale()
	return(Vector2(position) + Vector2(size.x, size.y))

func get_nome():
	return nome

func get_hp():
	return hp

func gain_health(value):
	hp += value
	if hp > max_hp:
		hp = max_hp
	
	healthbar.show()
	var hp_percentage = float(hp)/max_hp
	healthbar.change_hp_percent(hp_percentage, value)
	
func lose_health(damage):
	hp -= damage
	if hp < 0:
		hp = 0
	var hp_percentage = float(hp)/max_hp
	healthbar.show()
	healthbar.change_hp_percent(hp_percentage, -damage)
	if hp == 0:
		animation.play("death")
	else:
		animation.play("get_hit")

#logica do inimigo
func logic(character_list, menu):
	pass

# Quando a barra de vida dele termina de transicionar ele emite o sinal de que a animação acabou
func _on_healthbar_animation_end():
	animation_end.emit()

func on_animation():
	return animation.is_playing()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		death.emit()
