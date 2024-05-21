extends "res://scripts/enemy.gd"


# Called when the node enters the scene tree for the first time.
func _ready():
	nome = "Boneco"
	max_hp = 27
	animation.play("default")
	hp = max_hp


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#logica do inimigo
func logic(character_list, menu):
	# essa primeira parte serve para procurar um personagem vivo na party
	var id = randi_range(0,len(character_list)-1)
	if id == len(character_list):
		id = 0
	for i in range(4):
		if character_list[id].is_alive():
			break
		else:
			id += 1
			if id == len(character_list):
				id = 0
	# E essa parte é o ataque, ele atualiza a vida chamando a função de perder vida do personagem
	menu.update_health_slow(id, character_list[id].lose_health(randi_range(2, 5)))
