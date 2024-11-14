extends StaticBody2D


@onready var textbox = get_tree().get_current_scene().get_node("Textbox")

var ponte = []
var current_size = 1
var secret_dialogue = true
# Called when the node enters the scene tree for the first time.
func _ready():
	ponte = get_children()
	ponte[0].aparecer(0)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_size(size):
	if size > 13 and secret_dialogue:
		secret_dialogue = false
		textbox.queue_char_text(["Acho que você exagerou no tamanho garoto.",
						"Não tem problema, siga em frente e venha para cá"],
						["res://assets/portraits/silhueta.png",
						"res://assets/portraits/silhueta.png"])
	if size > len(ponte):
		size = len(ponte)
	elif size < 0:
		size = 0
	if size > current_size:
		for i in range(1, size-1):
			ponte[i].aparecer(1)
		for i in range(current_size, size):
			if i == 0:
				ponte[i].aparecer(0)
			elif i == size-1:
				ponte[i].aparecer(2)
			else:
				ponte[i].aparecer(1)
	elif size < current_size:
		for i in range(size, current_size):
			print(i)
			ponte[i].esconder()
	current_size = size
