extends CanvasLayer

signal scene_start
signal scene_end

const PAGE_CENTER = Vector2(-63,-67)
const PAGE_LEFT = Vector2(-145, -67)
const PAGE_RIGHT = Vector2(0, -67)
const PAGE_UP = Vector2(-63, -80)
const PAGE_DOWN = Vector2(-63, 0)

@onready var texture_rect = $TextureRect
@onready var textbox = $Textbox
@onready var black_screen = $BlackScreen

var quadros = []
var scene_index = 0
var size = 0
var dialogue = []
var current_state = State.READY
var scene_directions = []
var scene_tween : Tween


enum Direction {
	NONE,
	DOWN,
	LEFT,
	UP,
	RIGHT
}
enum State{
	ON_TEXT,
	ON_IMAGE,
	READY,
	FINISH
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	read_input()
	if Input.is_action_just_pressed("up"):
		shift_up()
	elif Input.is_action_just_pressed("down"):
		shift_down()
	elif Input.is_action_just_pressed("left"):
		shift_left()
	elif Input.is_action_just_pressed("right"):
		shift_right()

	if Input.is_action_just_pressed("y"):
		hide_scene()
		
	if Input.is_action_just_pressed("p"):
		scene_index += 1
		texture_rect.set_texture(quadros[scene_index])
	if Input.is_action_just_pressed("o"):
		scene_index -= 1
		texture_rect.set_texture(quadros[scene_index])

func read_input():
	if Input.is_action_just_pressed("interact"):
		if current_state == State.ON_IMAGE:
			_on_textbox_text_finish()
			
func play(dlg, direction = [], path = "", scene_size = 10):
	dialogue = dlg
	size = scene_size
	scene_directions = direction
	var tween  = create_tween()
	tween.tween_property(black_screen,"color", Color("#000000"), 3)
	tween.tween_callback(texture_rect.show)
	tween.tween_property(black_screen,"color", Color("#00000000"), 0.5)
	scene_tween = tween
	for i in size:
		quadros.append(load(path + str(i) + ".png"))
	if dialogue:
		tween.tween_callback(textbox.queue_text.bind(dialogue[0]))
		current_state = State.ON_TEXT
	else:
		current_state = State.ON_IMAGE
	if scene_directions:
		match scene_directions[scene_index]:
			Direction.NONE:
				texture_rect.set_position(PAGE_CENTER)
			Direction.UP:
				texture_rect.set_position(PAGE_DOWN)
			Direction.RIGHT:
				texture_rect.set_position(PAGE_LEFT)
			Direction.DOWN:
				texture_rect.set_position(PAGE_UP)
			Direction.LEFT:
				texture_rect.set_position(PAGE_RIGHT)
		tween.tween_callback(slide_scene)
	texture_rect.set_texture(quadros[scene_index])
	scene_start.emit()
	
	
func shift_right():
	if scene_tween:
		scene_tween.kill()
		scene_tween = null
	var tween  = create_tween()
	texture_rect.set_position(PAGE_LEFT)
	tween.tween_property(texture_rect, "position", PAGE_RIGHT, 9.5)
	scene_tween = tween

func shift_left():
	if scene_tween:
		scene_tween.kill()
		scene_tween = null
	var tween  = create_tween()
	texture_rect.set_position(PAGE_RIGHT)
	tween.tween_property(texture_rect, "position", PAGE_LEFT, 9.5)
	scene_tween = tween

func shift_up():
	if scene_tween:
		scene_tween.kill()
		scene_tween = null
	var tween  = create_tween()
	texture_rect.set_position(PAGE_DOWN)
	tween.tween_property(texture_rect, "position", PAGE_UP, 5)
	scene_tween = tween

func shift_down():
	if scene_tween:
		scene_tween.kill()
		scene_tween = null
	var tween  = create_tween()
	texture_rect.set_position(PAGE_UP)
	tween.tween_property(texture_rect, "position", PAGE_DOWN, 5)
	scene_tween = tween
	
func center_image():
	if scene_tween:
		scene_tween.kill()
		scene_tween = null
	texture_rect.set_position(PAGE_CENTER)
	
	
func hide_scene():
	if scene_tween:
		scene_tween.kill()
		scene_tween = null
	var tween  = create_tween()
	tween.tween_property(black_screen,"color", Color("#000000"), 3)
	tween.tween_callback(texture_rect.hide)
	tween.tween_property(black_screen,"color", Color("#00000000"), 1.5)
	tween.tween_callback(end_scence)
	scene_tween = tween
	
	
func end_scence():
	scene_end.emit()
	quadros = []
	scene_index = 0
	size = 0
	dialogue = []
	current_state = State.READY
	scene_directions = []
	
	
func slide_scene():
	match scene_directions[scene_index]:
		Direction.NONE:
			center_image()
		Direction.UP:
			shift_up()
		Direction.RIGHT:
			shift_right()
		Direction.DOWN:
			shift_down()
		Direction.LEFT:
			shift_left()
	
	
func _on_textbox_text_finish():
	scene_index += 1
	if scene_index == size:
		current_state = State.FINISH
		hide_scene()
	else:
		texture_rect.set_texture(quadros[scene_index])
		if scene_directions:
			match scene_directions[scene_index]:
				Direction.NONE:
					center_image()
				Direction.UP:
					shift_up()
				Direction.RIGHT:
					shift_right()
				Direction.DOWN:
					shift_down()
				Direction.LEFT:
					shift_left()
		if dialogue[scene_index] == [""]:
			current_state = State.ON_IMAGE
		else:
			textbox.queue_text(dialogue[scene_index])
			current_state = State.ON_TEXT
