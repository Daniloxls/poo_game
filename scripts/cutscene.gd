extends CanvasLayer

const PAGE_LEFT = Vector2(-145, -67)
const PAGE_RIGHT = Vector2(0, -67)
const PAGE_UP = Vector2(-63, -80)
const PAGE_DOWN = Vector2(-63, 0)
@onready var texture_rect = $TextureRect

var quadros = []
var index_image = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	var path = "res://assets/cutscene/antipoo_past/"
	for i in 10:
		quadros.append(load(path + str(i) + ".png"))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("up"):
		shift_up()
	elif Input.is_action_just_pressed("down"):
		shift_down()
	elif Input.is_action_just_pressed("left"):
		shift_left()
	elif Input.is_action_just_pressed("right"):
		shift_right()
	
	if Input.is_action_just_pressed("p"):
		index_image += 1
		texture_rect.set_texture(quadros[index_image])
	if Input.is_action_just_pressed("o"):
		index_image -= 1
		texture_rect.set_texture(quadros[index_image])

func shift_right():
	var tween = create_tween()
	texture_rect.set_position(PAGE_LEFT)
	tween.tween_property(texture_rect, "position", PAGE_RIGHT, 9.5)

func shift_left():
	var tween = create_tween()
	texture_rect.set_position(PAGE_RIGHT)
	tween.tween_property(texture_rect, "position", PAGE_LEFT, 9.5)

func shift_up():
	var tween = create_tween()
	texture_rect.set_position(PAGE_DOWN)
	tween.tween_property(texture_rect, "position", PAGE_UP, 5)

func shift_down():
	var tween = create_tween()
	texture_rect.set_position(PAGE_UP)
	tween.tween_property(texture_rect, "position", PAGE_DOWN, 5)
	
