extends CharacterBody2D

var direction : Vector2 = Vector2()
@onready var _animated_sprite = $AnimatedSprite2D
@onready var interact_box = $Collision_interact
@onready var colision = $ColisionPlayer
@onready var event = $EventColision
@onready var textbox = get_node("../Textbox")
@onready var codebox = get_node("../Codebox")

enum State{
	DOWN,
	LEFT,
	RIGHT,
	UP
}

var current_state = State.DOWN
var free_to_move = true
var sudo = true

func _ready():
	event.monitorable = true
	
func read_input():
	# Movement
	velocity = Vector2()
	if free_to_move:
		if Input.is_action_pressed("up"):
			velocity.y -= 1
			direction = Vector2(0, -1)
			_animated_sprite.play("run_up")
			current_state = State.UP
			interact_box.top()
		elif Input.is_action_pressed("down"):
			velocity.y += 1
			direction = Vector2(0, 1)
			_animated_sprite.play("run_down")
			current_state = State.DOWN
			interact_box.bottom()
		elif Input.is_action_pressed("left"):
			velocity.x -= 1
			direction = Vector2(-1, 0)
			_animated_sprite.play("run_left")
			current_state = State.LEFT
			interact_box.left()
		elif Input.is_action_pressed("right"):
			velocity.x += 1
			direction = Vector2(1, 0)
			_animated_sprite.play("run_right")	
			current_state = State.RIGHT
			interact_box.right()
		else:
			match(current_state):
				State.RIGHT:
					_animated_sprite.play("idle_right")
				State.UP:
					_animated_sprite.play("idle_up")
				State.DOWN:
					_animated_sprite.play("idle_down")
				State.LEFT:
					_animated_sprite.play("idle_left")
	else:
		match(current_state):
			State.RIGHT:
				_animated_sprite.play("idle_right")
			State.UP:
				_animated_sprite.play("idle_up")
			State.DOWN:
				_animated_sprite.play("idle_down")
			State.LEFT:
				_animated_sprite.play("idle_left")
				
			
	
	velocity = velocity.normalized()
	velocity = velocity * 1800
	
	move_and_slide()
	
	# Interaction
	if free_to_move:
		if Input.is_action_just_pressed("interact"):
			if interact_box.get_overlapping_areas():
				interact_box.get_overlapping_areas()[0].get_parent().interaction()
		if Input.is_action_just_pressed("depure") and sudo:
			if interact_box.get_overlapping_areas():
				codebox.queue_text(interact_box.get_overlapping_areas()[0].get_parent().name(),
				interact_box.get_overlapping_areas()[0].get_parent().depure())
	if Input.is_action_just_pressed("exit"):
		if codebox.get_state() != "Ready":
			interact_box.get_overlapping_areas()[0].get_parent().update_codigo(codebox.get_props())
		
func _physics_process(delta):
	read_input()

func set_movement(move):
	free_to_move = move

func set_sudo(s):
	sudo = s

func get_sudo():
	return sudo
