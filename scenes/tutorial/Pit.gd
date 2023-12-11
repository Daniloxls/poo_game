extends StaticBody2D
@onready var sprite = $Sprite2D
@onready var colision = $CollisionShape2D
# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_size(size):
	colision.set_scale(Vector2(1 - (size * 0.25),1 - (size * 0.25)))
	sprite.apply_scale(Vector2(1 - (size * 0.25),1 - (size * 0.25)))
