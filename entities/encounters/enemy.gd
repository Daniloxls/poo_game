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
@export var classe := ""
@export var portrait: Texture2D

var current_state = State.DEFAULT
# Called when the node enters the scene tree for the first time.
func enemy_ready():
	sprite_2d.connect("sprite_clicked", on_sprite_clicked)
	sprite_2d.connect("mouse_entered", on_sprite_mouse_in)
	sprite_2d.connect("mouse_exited", on_sprite_mouse_out)
	animation.connect("animation_finished", _on_animation_player_animation_finished)

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
	
# Contrato do combatente: só mudam o status, sem animação nem sinais.
func apply_damage(amount: int) -> int:
	var antes: int = hp
	hp = maxi(hp - amount, 0)
	return antes - hp

func apply_heal(amount: int) -> int:
	var antes: int = hp
	hp = mini(hp + amount, max_hp)
	return hp - antes

func is_party_member() -> bool:
	return false

func is_alive() -> bool:
	return hp > 0

func get_skills() -> Array:
	return []

func get_class_name() -> String:
	return classe

# Decide a ação do turno; a base não faz nada.
func choose_action(party: Array, enemies: Array) -> EnemyAction:
	return EnemyAction.new()

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
