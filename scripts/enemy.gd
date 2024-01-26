extends Node2D

signal death
signal animation_end

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite
@onready var healthbar = $Healthbar

var nome = "Boneco"
var hp

const MAX_HP = 32

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

func lose_health(damage):
	hp -= damage
	if hp < 0:
		hp = 0
	var hp_percentage = float(hp)/MAX_HP
	print(hp_percentage)
	healthbar.show()
	healthbar.change_hp_percent(hp_percentage)
	if hp == 0:
		animation.play("death")
		death.emit()
	else:
		animation.play("get_hit")
	


func _on_healthbar_animation_end():
	animation_end.emit()
	pass # Replace with function body.
