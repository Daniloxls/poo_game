extends CanvasLayer
@onready var  label = $Label
var tickets : int = 30

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func recieve_tickets(quant: int) -> void:
	tickets += quant
	label.set_text("X " + str(tickets))

func get_tickets():
	return tickets
