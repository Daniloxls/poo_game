extends StaticBody2D
@onready var sprite_a = $Sprite1
@onready var sprite_b = $Sprite2
@onready var sprite_c = $Sprite3
@onready var sprite_d = $Sprite4
@onready var sprite_e = $Sprite5
@onready var colision_a = $Colision1
@onready var colision_b = $Colision2
@onready var colision_c = $Colision3
@onready var colision_d = $Colision4
@onready var colision_e = $Colision5

var lista_colision = []
var lista_sprites = []
# Called when the node enters the scene tree for the first time.
func _ready():
	lista_colision = [colision_a, colision_b, colision_c, colision_d, colision_e]
	lista_sprites = [sprite_a, sprite_b, sprite_c, sprite_d, sprite_e]
	colision_a.set_deferred("disabled", true)
	sprite_a.hide()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_size(size):
	if size < 0:
		pass
	if size > 4:
		for i in range(4):
			lista_colision[i].set_deferred("disabled", true)
			lista_sprites[i].hide()
	else:
		for i in range(size):
			lista_colision[i].set_disabled(true)
			lista_sprites[i].hide()
		for i in range(3, size-1, -1):
			print(i)
			lista_colision[i].set_deferred("disabled", false)
			lista_sprites[i].show()
