extends Node2D

signal death
signal animation_end
signal health_change

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite
@onready var damage_text = $DamageText

var nome = "Alan"
var hp = 32
const MAX_HP = 32
var mp = 32
const MAX_MP = 32

# Called when the node enters the scene tree for the first time.
func _ready():
	#healthbar.hide()
	animation.play("default")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func hit_animation():
	animation.play("get_hit")

func heal_animation():
	animation.play("heal")
	
func get_cursor_pos():
	var current_animation : String = $Sprite.animation
	var sprite_texture : Texture2D = $Sprite.sprite_frames.get_frame_texture(current_animation, 0)
	var size = sprite_texture.get_size()
	return(Vector2(position) + Vector2(0, size.y/3))

func get_turn_cursor_pos():
	var current_animation : String = $Sprite.animation
	var sprite_texture : Texture2D = $Sprite.sprite_frames.get_frame_texture(current_animation, 0)
	var size = sprite_texture.get_size()
	return(Vector2(position) + Vector2(size.x, size.y/3))
	
func get_nome():
	return nome

func get_hp():
	return hp
	
func get_mp():
	return mp
	
func get_health_percentage():
	return float(hp)/MAX_HP
	
func is_alive():
	if hp> 0:
		return true
	else:
		return false
func gain_health(value):
	hp += value
	if hp > MAX_HP:
		hp = MAX_HP
	animation.play("heal")
	return float(hp)/MAX_HP
	
func lose_health(value):
	hp -= value
	if hp < 0:
		hp = 0
	if hp == 0:
		animation.play("death")
		death.emit()
	else:
		animation.play("get_hit")
	damage_text.number_animation(value)
	return float(hp)/MAX_HP


func _on_healthbar_animation_end():
	animation_end.emit()
	pass # Replace with function body.
