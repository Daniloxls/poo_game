extends CollisionShape2D
@onready var sprite = $Sprite

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func aparecer(frame):
	match(frame):
		0:
			sprite.set_animation("start")
		1:
			sprite.set_animation("middle")
		2:
			sprite.set_animation("end")
	sprite.show()
	
func esconder():
	sprite.hide()
