extends CharacterBody2D

var direction : Vector2 = Vector2()
@onready var _animated_sprite = $AnimatedSprite2D
func read_input():
	velocity = Vector2()
	if Input.is_action_pressed("up"):
		velocity.y -= 1
		direction = Vector2(0, -1)
		_animated_sprite.play("run_up")
	elif Input.is_action_pressed("down"):
		velocity.y += 1
		direction = Vector2(0, 1)
		_animated_sprite.play("run_down")
	elif Input.is_action_pressed("left"):
		velocity.x -= 1
		direction = Vector2(-1, 0)
		_animated_sprite.play("run_left")
	elif Input.is_action_pressed("right"):
		velocity.x += 1
		direction = Vector2(1, 0)
		_animated_sprite.play("run_right")
	else:
		_animated_sprite.play("idle_down")
	velocity = velocity.normalized()
	velocity = velocity * 100
	move_and_slide()
func _physics_process(delta):
	read_input()
