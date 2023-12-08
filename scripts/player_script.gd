extends CharacterBody2D

var direction : Vector2 = Vector2()
@onready var _animated_sprite = $AnimatedSprite2D
@onready var interact_box = $Collision_interact
@onready var textbox = get_node("../Textbox")
@onready var codebox = get_node("../Codebox")

enum State{
	DOWN,
	LEFT,
	RIGHT,
	UP
}

var current_state = State.DOWN

func read_input():
	# Movement
	velocity = Vector2()
	if textbox.get_state() == "Ready" and codebox.get_state() == "Ready":
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
				
			
	
	velocity = velocity.normalized()
	velocity = velocity * 100
	
	move_and_slide()
	
	# Interaction
	if textbox.get_state() == "Ready":
		if Input.is_action_just_pressed("interact"):
			if interact_box.get_overlapping_areas():
				textbox.queue_text(interact_box.get_overlapping_areas()[0].interaction())
		if Input.is_action_just_pressed("depure"):
			if interact_box.get_overlapping_areas():
				codebox.queue_text(interact_box.get_overlapping_areas()[0].name(),interact_box.get_overlapping_areas()[0].depure())
func _physics_process(delta):
	read_input()
