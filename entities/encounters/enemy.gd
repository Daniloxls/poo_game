extends Node2D

# scrip que deve ser a base para todos os inimigos

# sinais de morte e fim de animação
signal death
signal animation_end
signal sprite_clicked
signal mouse_in
signal mouse_out
signal finished_turn

@onready var animation = $AnimationPlayer
@onready var sprite_2d = $Sprite2D
@onready var healthbar = $Healthbar

enum State{
	DEFAULT,
	ANIMATION,
	DONE
}
# variaveis temporarias de teste
var nome
var hp
var max_hp
var def
var atk
var vel

var current_state = State.DEFAULT
# Called when the node enters the scene tree for the first time.
func enemy_ready():
	sprite_2d.connect("sprite_clicked", on_sprite_clicked)
	sprite_2d.connect("mouse_entered", on_sprite_mouse_in)
	sprite_2d.connect("mouse_exited", on_sprite_mouse_out)
	animation.connect("animation_finished", _on_animation_player_animation_finished)
	healthbar.set_values()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func hit_animation():
	animation.play("get_hit")
	

func get_nome():
	return nome

func get_hp():
	return hp
	
func get_max_hp():
	return max_hp
	
func get_def():
	return def
	
func get_vel():
	return vel

func get_state():
	return current_state
	
func take_damage(damage):
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
	current_state = State.ANIMATION
	
func gain_health(value):
	hp += value
	if hp > max_hp:
		hp = max_hp
	
	healthbar.show()
	var hp_percentage = float(hp)/max_hp
	healthbar.change_hp_percent(hp_percentage, value)
	

#logica do inimigo
func logic(character_list, menu):
	pass


func on_animation():
	return animation.is_playing()


func _on_animation_player_animation_finished(anim_name):
	current_state = State.DEFAULT
	if hp == 0:
		death.emit()
	else:
		animation_end.emit()
	
		
func on_sprite_clicked():
	sprite_clicked.emit(get_index())

func on_sprite_mouse_in():
	mouse_in.emit(self.nome)

func on_sprite_mouse_out():
	mouse_out.emit()

func connect_button(button : Button):
	button.connect("pressed", on_sprite_clicked)
	sprite_2d.connect_button(button)

func reset_state():
	current_state = State.DEFAULT
