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

@onready var textbox = get_node("../Textbox")
@onready var codebox = get_node("../Codebox")
@onready var inventory = get_node("../../../Inventory")

# Direção para onde o player está olhando
enum State{
	DOWN,
	LEFT,
	RIGHT,
	UP
}

var current_state = State.DOWN
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
				_animated_sprite.play("walk_up")
				current_state = State.UP
				interact_box.top()
			elif Input.is_action_pressed("down"):
				velocity.y += 1
				direction = Vector2(0, 1)
				_animated_sprite.play("walk_down")
				current_state = State.DOWN
				interact_box.bottom()
			elif Input.is_action_pressed("left"):
				velocity.x -= 1
				direction = Vector2(-1, 0)
				_animated_sprite.play("walk_left")
				current_state = State.LEFT
				interact_box.left()
			elif Input.is_action_pressed("right"):
				velocity.x += 1
				direction = Vector2(1, 0)
				_animated_sprite.play("walk_right")	
				current_state = State.RIGHT
				interact_box.right()
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
	if free_to_move and !on_battle:
		# Se o jogador aperta 'Z' chama a função de interact do objeto que o player está olhando
		if Input.is_action_just_pressed("interact"):
			if interact_box.get_overlapping_areas():
				interact_box.get_overlapping_areas()[0].get_parent().interaction()
		# Se o jogador aperta 'X' pega o codigo do objeto que está em frente ao personagem e
		# coloca na codebox
		if Input.is_action_just_pressed("depure"):
			if interact_box.get_overlapping_areas():
				codebox.queue_text(interact_box.get_overlapping_areas()[0].get_parent().name(),
				interact_box.get_overlapping_areas()[0].get_parent().depure())
		# Botão provisorio para abrir o inventario
		if Input.is_action_just_pressed("a"):
			inventory.aparecer()
	# Se o jogador aperta 'X' e se a caixa de codigo está aberta, se for o caso
	# insere o codigo editado de volta no objeto
	if Input.is_action_just_pressed("exit"):
		if codebox.get_state() != "Ready":
			interact_box.get_overlapping_areas()[0].get_parent().update_codigo(codebox.get_props())
	
		
func _physics_process(delta):
	read_input()

func set_movement(move):
	free_to_move = move
	
func set_on_battle(obt):
	on_battle = obt
	
func set_in_scene(scene):
	in_scene = scene
	
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
