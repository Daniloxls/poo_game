extends Node2D
@onready var player = $Player
@onready var textbox = $Textbox
@onready var codebox = $Codebox
@onready var up_arrow = $UpArrow
@onready var left_arrow = $LeftArrow
@onready var right_arrow = $RightArrow
@onready var down_arrow = $DownArrow
# Called when the node enters the scene tree for the first time.
func _ready():
	up_arrow.hide()
	left_arrow.hide()
	right_arrow.hide()
	down_arrow .hide()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("up"):
		up_arrow.show()
	if Input.is_action_just_pressed("down"):
		down_arrow.show()
	if Input.is_action_just_pressed("left"):
		left_arrow.show()
	if Input.is_action_just_pressed("right"):
		right_arrow.show()
	if Input.is_action_just_released("up"):
		up_arrow.hide()
	if Input.is_action_just_released("down"):
		down_arrow.hide()
	if Input.is_action_just_released("left"):
		left_arrow.hide()
	if Input.is_action_just_released("right"):
		right_arrow.hide()
	pass

