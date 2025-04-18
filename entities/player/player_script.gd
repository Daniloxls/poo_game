extends CharacterBody2D

# 'player_script' script que contem todas funções do personagem do jogador
# 'direction' a direção que o personagem se move
var direction : Vector2 = Vector2()
# '_animated_sprite' o sprite do personagem
@onready var _animated_sprite = $AnimatedSprite2D
# 'interact_box' caixas em volta do jogador que servem para ele interagir com o mundo
@onready var interact_box = $Collision_interact
# 'event' colisão que apenas eventos veem
@onready var event = $EventColision

@onready var camera = $Camera2D


# Estado que o jogador está, em um dialogo, cena ou com uma interface aberta

# Direção para onde o player está olhando
enum Direction{
	DOWN,
	LEFT,
	RIGHT,
	UP
}

enum Movement{
	WALKING,
	IDLE
}

var current_direction = Direction.DOWN
var current_movement = Movement.IDLE

# event.monitorable faz com que ele possa ser visto pelos eventos
func _ready():
	pass
	
func read_input():
	# Movimento
	# Muda a animação e acelera o jogador na direção que está sendo apertada
	# Tambem liga a caixa de interação respectiva
	velocity = Vector2()
	if PlayerState.is_able_to_move():
		if Input.is_action_pressed("up"):
			velocity.y -= 1
			direction = Vector2(0, -1)
			current_direction = Direction.UP
			interact_box.top()
			current_movement = Movement.WALKING
		elif Input.is_action_pressed("down"):
			velocity.y += 1
			direction = Vector2(0, 1)
			current_direction = Direction.DOWN
			interact_box.bottom()
			current_movement = Movement.WALKING
		if Input.is_action_pressed("left"):
			velocity.x -= 1
			direction = Vector2(-1, 0)
			current_direction = Direction.LEFT
			interact_box.left()
			current_movement = Movement.WALKING
		elif Input.is_action_pressed("right"):
			velocity.x += 1
			direction = Vector2(1, 0)
			current_direction = Direction.RIGHT
			interact_box.right()
			current_movement = Movement.WALKING
		elif (!(Input.is_action_pressed("up")) and !(Input.is_action_pressed("down"))):
			current_movement = Movement.IDLE
		if current_movement == Movement.WALKING:
			match(current_direction):
				Direction.RIGHT:
					_animated_sprite.play("walk_right")
				Direction.UP:
					_animated_sprite.play("walk_up")
				Direction.DOWN:
					_animated_sprite.play("walk_down")
				Direction.LEFT:
					_animated_sprite.play("walk_left")
		else:
			# Se o jogador não está se movendo mostra sprite de parado na direção atual
			match(current_direction):
				Direction.RIGHT:
					_animated_sprite.play("idle_right")
				Direction.UP:
					_animated_sprite.play("idle_up")
				Direction.DOWN:
					_animated_sprite.play("idle_down")
				Direction.LEFT:
					_animated_sprite.play("idle_left")
					
	elif !PlayerState.is_on_scene:
		match(current_direction):
			Direction.RIGHT:
				_animated_sprite.play("idle_right")
			Direction.UP:
				_animated_sprite.play("idle_up")
			Direction.DOWN:
				_animated_sprite.play("idle_down")
			Direction.LEFT:
				_animated_sprite.play("idle_left")
	# Acelera o jogador, se ele segurar shift acelera mais
	velocity = velocity.normalized()
	velocity = velocity * 3600
	move_and_slide()
	
	# Interação
	if PlayerState.is_able_to_move():
		# Se o jogador aperta 'Z' chama a função de interact do objeto que o player está olhando
		if Input.is_action_just_pressed("interact"):
				if interact_box.get_overlapping_areas() and Textbox.get_state() == "Ready":
					interact_box.get_overlapping_areas()[0].get_parent().interaction()
	if Input.is_action_just_pressed("exit"):
		# Fechar inventario, codebox, qualquer inteface que esteja aberta
		pass
	

func _physics_process(_delta):
	read_input()

	
func set_sprite(sprite):
	_animated_sprite.play(sprite)
