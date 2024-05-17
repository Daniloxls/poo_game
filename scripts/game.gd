extends Node2D
signal battle_won
signal battle_lost
@onready var level = $Level
@onready var inventory = $Inventory
@onready var battle = $Battle
@onready var music = $AudioPlayer
#Game é a cena principal, ela carrega e descarrega os niveis e mantem
# o inventario intacto entre cenas.


# Função que é chamada quando esse nó entra na arvore de cena
func _ready():
	music.set_stream(load("res://assets/bgm/Dream Eliot Corley.mp3"))
	music.play()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Chamada para trocar o nivel, antes de usar passar instance para como argumento da
#função é necessario instanciar o arquivo dessa forma:

# 	var root = get_node("Caminho relativo até esse nó")
#	var next_level = load("Caminho do nivel que você quer carregar")
#	var instance = next_level.instantiate()
#	root.change_level(instance)

func change_level(instance, entrance : int = 0):
	for node in level.get_children():
		node.queue_free()
	level.call_deferred("add_child", instance)
	instance.call_deferred("enter_stage", entrance)
	inventory.call_deferred("set_player", instance.find_child("Player"))
	battle.call_deferred("set_player", instance.find_child("Player"))


func _on_battle_battle_lost():
	battle_lost.emit()


func _on_battle_battle_won():
	battle_won.emit()
