extends Node2D
@onready var area = $Area2D
@onready var player = get_node("../Player")
@onready var codebox = get_node("../Codebox")
var nome
var texto
var codigo
var portraits
var depuring = false

# Called when the node enters the scene tree for the first time.
func _ready():
	set_texto(["Eesse teclado deve ser para colocar a senha"])
	set_codigo("Teclado Numerico", {"1String senha" : "senha123"})
	set_portraits([""])
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func interaction():
	return texto

func set_texto(new_texto):
	texto = new_texto
	
func set_codigo(new_nome, new_codigo):
	nome = new_nome
	codigo = new_codigo

func update_codigo(new_codigo):
	codigo = new_codigo
	
func depure():
	depuring = true
	return codigo
	
func get_portraits():
	return portraits
	
func set_portraits(new_portraits):
	portraits = new_portraits
	
func name():
	return nome
