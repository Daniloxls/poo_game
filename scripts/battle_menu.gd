extends Node2D
# 'animation_end' sinal emitido quando acaba uma animação
# Exemplo: barra de vida descendo após um dano
signal animation_end

# 'monster_stats' painel com todas informações dos monstros
@onready var monster_stats = $MonsterStatus
# 'actions' menu com opções da batalha
@onready var actions = $Actions
@onready var cursor = $Actions/Cursor
# lista com os status de cada personagem na party
@onready var characters = $PlayerStatus/MarginContainer/HBoxContainer.get_children()
# lista com os nomes dos monstros, todos ficam em uma string só
@onready var monster_list = $MonsterStatus/MarginContainer/HBoxContainer/Label2

# Altura para o cursor ficar na primeira opção do menu
const CURSOR_INITIAL_Y = -43
var cursor_pos = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_cursor_pos():
	cursor.set_pos_y(CURSOR_INITIAL_Y + (40 * cursor_pos))
	
# funcão que muda o cursor_pos e faz ele dar a volta se passou da primera opção 
func move_cursor_up():
	if cursor_pos == 0:
		cursor_pos = 2
		update_cursor_pos()
	else:
		cursor_pos = 0
		update_cursor_pos()
		
# mesma coisa mas faz o cursor voltar para a primeira se ele passou da ultima
func move_cursor_down():
	if cursor_pos == 2:
		cursor_pos = 0
		update_cursor_pos()
	else:
		cursor_pos = 2
		update_cursor_pos()


func get_cursor_pos():
	return cursor_pos


func hide_cursor():
	cursor.hide()
	
func show_cursor():
	cursor.show()
	
# Recebe uma lista nomes de monstro e colocas todos na label que lista os monstro
func set_monster_names(list):
	var names = ''
	for monstro in list:
		names += monstro + '\n'
	monster_list.set_text(names)
	
# Funções para esconder e mostrar status dos personagens
func hide_char_status(id):
	characters[id].hide()
	
func show_char_status(id):
	characters[id].show()
	
# Função para mudar o nome de um personagem no menu
func set_character_name(id, nome):
	characters[id].set_nome(nome)

# Muda a quantidade da barra de vida sem animação
func update_health_instant(id, percentage):
	characters[id].set_health_instant(percentage)
	
# Muda a quantidade da barra de vida com animação
func update_health_slow(id, percentage):
	characters[id].set_health_slow(percentage)
	
# O mesmo para mana
func update_mana_instant(id, value):
	characters[id].set_mana_instant(value)
	
func update_mana_slow(id, value):
	characters[id].set_mana_slow(value)


# Recebe os sinais de cada 'personagem' para saber quando suas animações acabaram
# Personagens nesse caso são as barras de vida e mana de cada um
func _on_char_1_animation_end():
	animation_end.emit()

func _on_char_2_animation_end():
	animation_end.emit()

func _on_char_3_animation_end():
	animation_end.emit()

func _on_char_4_animation_end():
	animation_end.emit()
