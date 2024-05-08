extends Node2D

# Interact é uma classe base para objetos interativos no jogo.
# Todos os objetos interativos estendem este script.

# 'area' define a área de interação visível para a colisão do jogador.
@onready var area = $Area2D

# 'colision' é o corpo de colisão do objeto, por padrão, está ligado.
@onready var colision = $StaticBody2D
# 'player' é uma referência ao nó do jogador,
# permitindo acesso para movê-lo ou alterar suas propriedades.
@onready var player = get_node("../Player")
@onready var codebox = get_node("../Codebox")

# O nome que aparece na caixa de código.
var nome

# Lista de strings que serão exibidas como diálogo quando o jogador interagir com este objeto.
var texto = []

# 'codigo' contém as propriedades do objeto que podem ser alteradas durante a depuração pelo jogador.
# Para tornar uma variável acessível para o jogador, prefixe o nome dela com '1'.
# A caixa de código só permite alterações de variaveis nesses formatos.
# Exemplo: {"1boolean variavel_editavel": true, "boolean variavel_nao_editavel": true}
var codigo = {}

var metodos = {}
# 'portraits' guarda uma lista de caminhos para as imagens de personagens,
# caso a interação envolva diálogo com personagens.
var portraits = [""]

# Quando o código de um objeto está sendo depurado pelo jogador,
# esta variável é definida como true.
var depuring = false


func _ready():
	pass

# Chamado a cada quadro. 'delta' é o tempo decorrido desde o quadro anterior.
func _process(delta):
	pass

# Função chamada pelo personagem quando interage com o objeto ao pressionar 'Z'.
func interaction():
	pass
	
# Define o texto de interação do objeto.
func set_texto(new_texto):
	texto = new_texto
	
	
# Retorna a lista de retratos associados a este objeto.
func get_portraits():
	return portraits
	
	
# Define os retratos associados a este objeto.
func set_portraits(new_portraits):
	portraits = new_portraits
	

# Usado para alterar tanto o nome quanto o código do objeto.
func set_codigo(new_nome, new_codigo):
	nome = new_nome
	codigo = new_codigo

# Usado para alterar apenas o código do objeto.
func update_codigo(new_codigo):
	codigo = new_codigo
	
# Função chamada pelo personagem para visualizar
# e alterar o código deste objeto durante a depuração.
func depure():
	depuring = true
	return codigo
	
func methods():
	return metodos
	
# Retorna o nome do objeto.
func name():
	return nome
