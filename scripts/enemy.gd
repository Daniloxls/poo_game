extends Node2D

# scrip que deve ser a base para todos os inimigos

# sinais de morte e fim de animação
signal death
signal animation_end

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite
@onready var healthbar = $Healthbar

# variaveis temporarias de teste
var nome = "Boneco"
var hp

const MAX_HP = 27

# Called when the node enters the scene tree for the first time.
func _ready():
	#healthbar.hide()
	animation.play("default")
	hp = MAX_HP
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
	
	return(Vector2(position) + Vector2(size.x, size.y/3))

func get_nome():
	return nome

func get_hp():
	return hp

func gain_health(value):
	hp += value
	if hp > MAX_HP:
		hp = MAX_HP
	
	healthbar.show()
	var hp_percentage = float(hp)/MAX_HP
	healthbar.change_hp_percent(hp_percentage, value)
	
func lose_health(damage):
	hp -= damage
	if hp < 0:
		hp = 0
	var hp_percentage = float(hp)/MAX_HP
	healthbar.show()
	healthbar.change_hp_percent(hp_percentage, -damage)
	if hp == 0:
		animation.play("death")
		death.emit()
	else:
		animation.play("get_hit")
	

#logica do inimigo
func logic(character_list, menu):
	# essa primeira parte serve para procurar um personagem vivo na party
	var id = randi_range(0,len(character_list)-1)
	if id == len(character_list):
		id = 0
	for i in range(4):
		if character_list[id].is_alive():
			break
		else:
			id += 1
			if id == len(character_list):
				id = 0
	# E essa parte é o ataque, ele atualiza a vida chamando a função de perder vida do personagem
	menu.update_health_slow(id, character_list[id].lose_health(randi_range(2, 5)))

# Quando a barra de vida dele termina de transicionar ele emite o sinal de que a animação acabou
func _on_healthbar_animation_end():
	animation_end.emit()

func on_animation():
	return animation.is_playing()
