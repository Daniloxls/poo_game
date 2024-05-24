extends "res://scripts/npc_script.gd"

@onready var peso = $Peso
@onready var teste = $TesteDeForca
@onready var camera = get_node("../Player/Camera2D")
@onready var tickets = get_node("../Tickets")
var triggered = false
var scene = false
var game_won = false
var animation_end = false

func _ready():
	texto = [["Estou impressionado! Parabéns tome 10 tickets para você"],
	["Não foi dessa vez, mas não fique triste você pode tentar de novo"]]
	pass

func set_sprite(sprite):
	_animated_sprite.play(sprite)

func play_animation(animation):
	animation_player.play(animation)
	
func set_texto(new_texto):
	texto = new_texto
	
func get_portraits():
	return portraits
	
func set_portraits(new_portraits):
	portraits = new_portraits
	
func set_codigo(new_nome, new_codigo):
	nome = new_nome
	codigo = new_codigo

func update_codigo(new_codigo):
	codigo = new_codigo
	
func depure():
	depuring = true
	return codigo


func methods():
	return {}
	
func interaction():
	if !scene and !game_won:
		textbox.queue_text(["Teste sua força para ganhar tickets!"])
		triggered = true
	else:
		textbox.queue_text(["Desculpe garoto, só uma vitoria por pessoa."])
func _on_textbox_text_finish():
	if triggered:
		textbox.display_choice("Você quer tentar garoto ?", ["Sim", "Não"])
	elif scene:
		scene = false
		var comando = teste.get_methods()["0"][0].substr(5, teste.get_methods()["0"][2])
		var result = evaluate(comando, ["forca"], [4])
		var tween = create_tween()
		var current_pos = player.get_position()
		tween.tween_callback(player.set_in_scene.bind(true))
		if current_pos.y < -12650:
			tween.tween_callback(player.set_sprite.bind("walk_left"))
			tween.tween_property(player, "position", Vector2(4500, current_pos.y), abs(current_pos.x - 4500)/500)
			current_pos = Vector2(4500, current_pos.y)
		if current_pos.y < -12123:
			tween.tween_callback(player.set_sprite.bind("walk_down"))
		else:
			tween.tween_callback(player.set_sprite.bind("walk_up"))
		tween.tween_property(player, "position", Vector2(current_pos.x, -12123), abs(current_pos.y + 12123)/500)
		current_pos = Vector2(current_pos.x, -12123)
		if current_pos.x < 4973:
			tween.tween_callback(player.set_sprite.bind("walk_right"))
			tween.tween_property(player, "position", Vector2(4973, current_pos.y), abs(current_pos.x - 4973)/500)
			current_pos = Vector2(4973, current_pos.y)
		tween.tween_callback(player.set_sprite.bind("walk_right"))
		tween.tween_callback(player.set_z_index.bind(6))
		tween.tween_callback(teste.set_colision.bind(false))
		tween.tween_property(player, "position", Vector2(7000, -12326), abs(current_pos.x - 7000)/500)
		current_pos = Vector2(7000, -12326)
		tween.tween_callback(player.set_sprite.bind("idle_right"))
		tween.tween_property(camera, "offset", Vector2(0, -1400), 1)
		tween.tween_property(player, "position", current_pos + Vector2(0, -300), 0.15)
		tween.tween_property(player, "position", current_pos, 0.1)
		if result:
			tween.tween_property(peso, "position", peso.get_position() + Vector2(0, -2750), 0.6)
			tween.tween_property(peso, "position", peso.get_position(), 0.9).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
			game_won = true
			tween.tween_callback(textbox.queue_text.bind(texto[0]))
		else:
			tween.tween_property(peso, "position", peso.get_position() + Vector2(0, -800), 0.3)
			tween.tween_property(peso, "position", peso.get_position(), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
			tween.tween_callback(textbox.queue_text.bind(texto[1]))
		tween.tween_property(camera, "offset", Vector2(0, 0), 1)
		animation_end = true
	elif animation_end:
		var tween = create_tween()
		animation_end = false
		if game_won:
			tween.tween_callback(tickets.show)
			tween.tween_callback(tickets.recieve_tickets.bind(10))
		tween.tween_callback(player.set_sprite.bind("walk_left"))
		tween.tween_property(player, "position", Vector2(4973, -12123), abs(7000 - 4973)/500)
		tween.tween_callback(player.set_z_index.bind(2))
		tween.tween_callback(teste.set_colision.bind(true))
		tween.tween_callback(player.set_in_scene.bind(false))


func _on_textbox_choise_closed():
	if triggered:
		triggered = false
		match(textbox.get_choice()):
			0:
				textbox.queue_text(["Certo, pegue o martelo e dê o seu melhor!"])
				scene = true
			1:
				textbox.queue_text(["Tudo bem, quem sabe depois"])
				
func name():
	return nome

func evaluate(command, variable_names = [], variable_values = []) -> bool:
	var expression = Expression.new()
	var error = expression.parse(command, variable_names)
	if error != OK:
		push_error(expression.get_error_text())
		return false

	var result = expression.execute(variable_values, self)

	if not expression.has_execute_failed():
		if result and result is bool:
			return result
		else:
			return false
	else:
		return false
