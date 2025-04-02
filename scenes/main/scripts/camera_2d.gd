extends Camera2D

signal mouse_ray_processed()

var _query_mouse := false
var _mouse_event : InputEvent

func _unhandled_input(event):
	if event is InputEventMouse:
		_query_mouse = true
		_mouse_event = event
		
func _physics_process(delta):
	if _query_mouse:
		_check_sprite_input()
		_query_mouse = false
		mouse_ray_processed.emit()
		
func _check_sprite_input():
	var not_hits = []
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
