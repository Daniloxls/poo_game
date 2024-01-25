extends Node2D
@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite


# Called when the node enters the scene tree for the first time.
func _ready():

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
