extends Area2D
@onready var top_box = $Box_up
@onready var left_box = $Box_left
@onready var bottom_box = $Box_down
@onready var right_box = $Box_right

# Caixas de colisão ao redor do jogador para interação com o mundo
func _ready():
	top_box.disabled = true
	left_box.disabled = true
	right_box.disabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func turn_all_off():
	top_box.disabled = true
	left_box.disabled = true
	right_box.disabled = true
	bottom_box.disabled = true
	
func top():
	turn_all_off()
	top_box.disabled = false
	
func bottom():
	turn_all_off()
	bottom_box.disabled = false

func left():
	turn_all_off()
	left_box.disabled = false
	
func right():
	turn_all_off()
	right_box.disabled = false
