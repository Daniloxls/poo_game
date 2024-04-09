extends Node2D
@onready var level = $Level

#Game é a cena principal, ela carrega e descarrega os niveis e mantem
# o inventario intacto entre cenas.


# Função que é chamada quando esse nó entra na arvore de cena
func _ready():
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

func change_level(instance):
	for node in level.get_children():
		node.queue_free()
	level.call_deferred("add_child", instance)
