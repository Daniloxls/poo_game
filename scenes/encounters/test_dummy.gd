extends "res://entities/encounters/enemy.gd"


# Called when the node enters the scene tree for the first time.
func _ready():
	nome = "Boneco_de_Teste"
	max_hp = 27
	animation.play("default")
	hp = max_hp
	def = 5
	vel = 2
	atk = 3
	enemy_ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#logica do inimigo
func logic(character_list, menu):
	var alive_characters = []
	# essa primeira parte serve para procurar um personagem vivo na party
	for char in character_list:
		if char.get_state() != 3:
			alive_characters.append(char)
	var target = alive_characters.pick_random()
	var id = character_list.find(target)
	# E essa parte é o ataque, ele atualiza a vida chamando a função de perder vida do personagem
	menu.change_char_health(id, character_list[id].take_damage(randi_range(2, 5)))
	current_state = State.DONE
