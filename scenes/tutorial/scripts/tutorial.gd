extends Node2D

signal battle_tutorial_end

@onready var player = $Player
@onready var up_arrow = $DesenhosParede/UpArrow
@onready var left_arrow = $DesenhosParede/LeftArrow
@onready var right_arrow = $DesenhosParede/RightArrow
@onready var down_arrow = $DesenhosParede/DownArrow
@onready var root = $"../.."
# Called when the node enters the scene tree for the first time.
func _ready():
	#player.set_state(States.Player_State.ON_SCENE)
	root.battle_won.connect(_on_tutorial_battle_end)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("up"):
		up_arrow.set_frame(1)
	if Input.is_action_just_pressed("down"):
		down_arrow.set_frame(1)
	if Input.is_action_just_pressed("left"):
		left_arrow.set_frame(1)
	if Input.is_action_just_pressed("right"):
		right_arrow.set_frame(1)
	if Input.is_action_just_released("up"):
		up_arrow.set_frame(0)
	if Input.is_action_just_released("down"):
		down_arrow.set_frame(0)
	if Input.is_action_just_released("left"):
		left_arrow.set_frame(0)
	if Input.is_action_just_released("right"):
		right_arrow.set_frame(0)



func _on_tutorial_battle_end():
	battle_tutorial_end.emit()
