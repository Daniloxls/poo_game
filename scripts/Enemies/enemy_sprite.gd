extends Sprite2D

signal input_event(viewport: Viewport, event: InputEvent, shape_idx: int)
signal mouse_entered()
signal mouse_exited()
signal mouse_clicked()

var mouse_over := false

@onready var collision_shape := $Area2D/CollisionShape2D

func _ready():
	# Connect signals for mouse interaction
	$Area2D.connect("mouse_entered", self._on_mouse_entered)
	$Area2D.connect("mouse_exited", self._on_mouse_exited)
	$Area2D.connect("input_event", self._on_input_event)

	# Update collision shape size to match the sprite's texture
	_update_collision_shape()

func _update_collision_shape():
	# Set the collision shape size to match the sprite's texture
	if texture:
		collision_shape.shape.extents = texture.get_size() / 2

func _on_mouse_entered():
	mouse_over = true
	mouse_entered.emit()
	modulate = Color.RED  # Highlight the sprite when the mouse enters

func _on_mouse_exited():
	mouse_over = false
	mouse_exited.emit()
	modulate = Color.WHITE  # Reset the sprite's color when the mouse exits

func _on_sprite_clicked():
	print("Sprite was clicked!")
	# Add your click handling logic here
	
func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int):
	# Emit the input_event signal for further processing
	input_event.emit(viewport, event, shape_idx)
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Emit the mouse_clicked signal when the left mouse button is pressed
			mouse_clicked.emit()


func _on_mouse_clicked():
	pass # Replace with function body.
