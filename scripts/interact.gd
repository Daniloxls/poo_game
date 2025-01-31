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
@onready var codebox = get_tree().get_current_scene().get_node("Codebox")
@onready var textbox = get_tree().get_current_scene().get_node("Textbox")
@onready var menu_button = get_node("MenuButton")

var has_popup := false
var mouse_over := false 
var popup
# O nome que aparece na caixa de código.
var nome = ""

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
	if (codigo != {}) or (metodos != {}):
		has_popup = true
	ready_drop_menu()
	if has_popup:
		# Connect the about_to_popup signal to set the popup position
		menu_button.get_popup().connect("about_to_popup", self._on_menu_button_about_to_popup)
		# Connect mouse_entered and mouse_exited signals
		area.connect("mouse_entered", self._on_mouse_entered)
		area.connect("mouse_exited", self._on_mouse_exited)
	else:
		# Hide the MenuButton if the object doesn't need a popup
		menu_button.hide()
		
# Chamado a cada quadro. 'delta' é o tempo decorrido desde o quadro anterior.
func _process(delta):
	pass

func _unhandled_input(event: InputEvent):
	if has_popup and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Check if the mouse is over this object's Area2D
			print("clicou")
			if mouse_over:
				# Open the popup manually
				menu_button.show_popup()
				# Set the popup position to the mouse location
				call_deferred("_set_popup_position")
			
func ready_drop_menu():
	if (codigo == {}) and (metodos == {}):
		menu_button.hide()
	popup = menu_button.get_popup()
	
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
func set_codigo(new_codigo):
	codigo = new_codigo

func set_metodos(new_methods):
	metodos = new_methods
	
func set_colision(value: bool) -> void:
	colision.set_collision_layer_value(1, value)
	
# Função chamada pelo personagem para visualizar
# e alterar o código deste objeto durante a depuração.
func depure(index):
	codebox.depure(self)
	
func get_codigo():
	return codigo
	
func get_metodos():
	return metodos
	
# Retorna o nome do objeto.
func get_nome():
	return nome


func _on_menu_button_about_to_popup():
	call_deferred("_set_popup_position")

func _set_popup_position():
	popup = menu_button.get_popup()
	popup.connect("index_pressed", depure)
	popup.set_position(get_viewport().get_mouse_position())
	
func _on_mouse_entered():
	# Mouse entered the Area2D
	mouse_over = true

func _on_mouse_exited():
	# Mouse exited the Area2D
	mouse_over = false
