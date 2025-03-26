extends AnimatedSprite2D

signal input_event(viewport: Viewport, event: InputEvent, shape_idx: int)
signal mouse_entered()
signal mouse_exited()
signal mouse_clicked()
signal sprite_clicked()


@onready var collision_shape := $Area2D/CollisionShape2D

var mouse_over := false


# Called when the node enters the scene tree for the first time.
func _ready():
	$Area2D.connect("mouse_entered", self._on_mouse_entered)
	$Area2D.connect("mouse_exited", self._on_mouse_exited)
	$Area2D.connect("input_event", self._on_input_event)
	connect("mouse_clicked", _on_sprite_clicked)
	_update_collision_shape()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _update_collision_shape():
	get
	# Set the collision shape size to match the sprite's texture
	var texture = get_sprite_frames().get_frame_texture("default", 0)
	if texture:
		collision_shape.shape.extents = texture.get_size() / 2

func _on_mouse_entered():
	mouse_over = true
	mouse_entered.emit()

func _on_mouse_exited():
	mouse_over = false
	mouse_exited.emit()

func _on_sprite_clicked():
	sprite_clicked.emit()
	
	
func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int):
	# Emit the input_event signal for further processing
	input_event.emit(viewport, event, shape_idx)
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Emit the mouse_clicked signal when the left mouse button is pressed
			mouse_clicked.emit()
