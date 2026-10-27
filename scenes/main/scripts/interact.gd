extends Node2D

# Interact é uma classe base para objetos interativos no jogo.
# Todos os objetos interativos estendem este script.

# 'area' define a área de interação visível para a colisão do jogador.
@onready var area = $Area2D

# 'colision' é o corpo de colisão do objeto, por padrão, está ligado.
@onready var colision = $StaticBody2D
@onready var glifos = $Glifos   # glifos de código subindo: marca de objeto depurável
# 'player' é uma referência ao nó do jogador,
# permitindo acesso para movê-lo ou alterar suas propriedades.
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var menu_button = $MenuButton

# Cor dos glifos de código que sobem de objetos depuráveis (mude no Inspetor).
@export var cor_glifos := Color("#bff6ff")

var has_popup := false
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
var triggered : bool

var _ancora_popup := Vector2.ZERO   # onde o objeto estava na tela quando o menu abriu

func _ready():
	if (codigo != {}) or (metodos != {}):
		has_popup = true
		glifos.show()
	ready_drop_menu()
	if not has_popup:
		# Hide the MenuButton if the object doesn't need a popup
		menu_button.hide()
		
# Chamado a cada quadro. 'delta' é o tempo decorrido desde o quadro anterior.
func _process(delta):
	pass

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
	Codebox.depure(self)
	
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
	# o MenuButton escala o popup pelo zoom da câmera (0.11 na cidade),
	# o que deixava o "Depurar" minúsculo; volta para o tamanho normal da interface
	popup.content_scale_factor = 1.0
	popup.transparent_bg = true   # cantos arredondados do tema_depurar
	popup.reset_size()
	if not popup.index_pressed.is_connected(depure):
		popup.index_pressed.connect(depure)
		popup.window_input.connect(_on_popup_input)
	popup.set_position(get_viewport().get_mouse_position())
	_ancora_popup = get_global_transform_with_canvas().origin
	if not get_tree().process_frame.is_connected(_fechar_popup_se_mexeu):
		get_tree().process_frame.connect(_fechar_popup_se_mexeu)


# O menu aberto recebe todos os cliques; o direito fora dele só fechava com
# o esquerdo. Agora qualquer clique fora fecha, sem reabrir no lugar novo.
func _on_popup_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and not Rect2(Vector2.ZERO, popup.size).has_point(event.position):
		popup.hide()


# A câmera (ou o objeto) andou: o menu ficaria solto na tela, então fecha.
func _fechar_popup_se_mexeu():
	if popup.visible and get_global_transform_with_canvas().origin.distance_to(_ancora_popup) < 1.0:
		return
	popup.hide()
	get_tree().process_frame.disconnect(_fechar_popup_se_mexeu)
