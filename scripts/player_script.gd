extends CharacterBody2D

# 'player_script' script que contem todas funções do personagem do jogador
# 'direction' a direção que o personagem se move
var direction : Vector2 = Vector2()
# '_animated_sprite' o sprite do personagem
@onready var _animated_sprite = $AnimatedSprite2D
# 'interact_box' caixas em volta do jogador que servem para ele interagir com o mundo
@onready var interact_box = $Collision_interact
# 'colision' colisão do jogdor
@onready var colision = $ColisionPlayer
# 'event' colisão que apenas eventos veem
@onready var event = $EventColision

@onready var camera = $Camera2D

@onready var black_screen = $Camera2D/BlackScreen

@onready var textbox = get_node("../Textbox")
@onready var codebox = get_node("../Codebox")
@onready var inventory = get_node("Inventory")

# Direção para onde o player está olhando
enum State{
	DOWN,
	LEFT,
	RIGHT,
	UP
}

enum Movement{
	WALKING,
	IDLE
}

var current_state = State.DOWN
var current_movement = Movement.IDLE
var free_to_move = true
var in_scene = false
var on_battle = false

# event.monitorable faz com que ele possa ser visto pelos eventos
func _ready():
	event.monitorable = true
	
func read_input():
	# Movimento
	# Muda a animação e acelera o jogador na direção que está sendo apertada
	# Tambem liga a caixa de interação respectiva
	velocity = Vector2()
	if !in_scene:
		if free_to_move and !on_battle:
			if Input.is_action_pressed("up"):
				velocity.y -= 1
				direction = Vector2(0, -1)
				current_state = State.UP
				interact_box.top()
				current_movement = Movement.WALKING
			elif Input.is_action_pressed("down"):
				velocity.y += 1
				direction = Vector2(0, 1)
				current_state = State.DOWN
				interact_box.bottom()
				current_movement = Movement.WALKING
			if Input.is_action_pressed("left"):
				velocity.x -= 1
				direction = Vector2(-1, 0)
				current_state = State.LEFT
				interact_box.left()
				current_movement = Movement.WALKING
			elif Input.is_action_pressed("right"):
				velocity.x += 1
				direction = Vector2(1, 0)
				current_state = State.RIGHT
				interact_box.right()
				current_movement = Movement.WALKING
			elif (!(Input.is_action_pressed("up")) and !(Input.is_action_pressed("down"))):
				current_movement = Movement.IDLE
			if current_movement == Movement.WALKING:
				match(current_state):
					State.RIGHT:
						_animated_sprite.play("walk_right")
					State.UP:
						_animated_sprite.play("walk_up")
					State.DOWN:
						_animated_sprite.play("walk_down")
					State.LEFT:
						_animated_sprite.play("walk_left")
			else:
				# Se o jogador não está se movendo mostra sprite de parado na direção atual
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
					
			
				
			
	# Acelera o jogador, se ele segurar shift acelera mais
	velocity = velocity.normalized()
	if Input.is_action_pressed("run"):
		velocity = velocity * 3600
	else:
		velocity = velocity * 2300
	
	move_and_slide()
	
	# Interação
	if free_to_move and !on_battle and !in_scene:
		# Se o jogador aperta 'Z' chama a função de interact do objeto que o player está olhando
		if Input.is_action_just_pressed("interact"):
			if interact_box.get_overlapping_areas() and textbox.get_state() == "Ready":
				interact_box.get_overlapping_areas()[0].get_parent().interaction()
		# Se o jogador aperta 'X' pega o codigo do objeto que está em frente ao personagem e
		# coloca na codebox
		if Input.is_action_just_pressed("depure"):
			if interact_box.get_overlapping_areas():
				codebox.queue_text(interact_box.get_overlapping_areas()[0].get_parent().name(),
				interact_box.get_overlapping_areas()[0].get_parent().depure(),
				interact_box.get_overlapping_areas()[0].get_parent().get_methods())
		# Botão provisorio para abrir o inventario
		if Input.is_action_just_pressed("a"):
			inventory.aparecer()
			pass
	# Se o jogador aperta 'X' e se a caixa de codigo está aberta, se for o caso
	# insere o codigo editado de volta no objeto
	if Input.is_action_just_pressed("exit"):
		if codebox.get_state() != "Ready":
			interact_box.get_overlapping_areas()[0].get_parent().update_codigo(codebox.get_props())
			interact_box.get_overlapping_areas()[0].get_parent().update_methods(codebox.get_methods())
	

func _physics_process(_delta):
	read_input()

func set_movement(move):
	free_to_move = move
	
func set_on_battle(obt):
	on_battle = obt
	
func set_in_scene(scene):
	in_scene = scene
	
func can_edit_code():
	if interact_box.get_overlapping_areas():
		if interact_box.get_overlapping_areas()[0].get_parent().name() != "":
			return true
		else:
			return false
			
func set_animation(animation, direction):
	match(animation):
		"idle":
			match(direction):
				"right":
					_animated_sprite.play("idle_right")
				"up":
					_animated_sprite.play("idle_up")
				"down":
					_animated_sprite.play("idle_down")
				"left":
					_animated_sprite.play("idle_left")
		"walk":
			match(direction):
				"right":
					_animated_sprite.play("walk_right")
				"up":
					_animated_sprite.play("walk_up")
				"down":
					_animated_sprite.play("walk_down")
				"left":
					_animated_sprite.play("walk_left")
					

func set_sprite(sprite):
	_animated_sprite.play(sprite)
