extends "res://entities/npc/npc_script.gd"

var teste_try = 1

var count_errors:int = 0

var dialogo_error = ["Acho que é possível tentar “acessar o código” do teste de força","Às vezes, nem sempre a sua força deve ser grande.","Acho que você pode diminuir o peso desse teste."]


@onready var peso = $Peso
@onready var teste = $TesteDeForca
@onready var camera = get_node("../Player/Camera2D")
@onready var tickets = get_node("../Tickets")
@onready var cmdzinho = $"../Cmdzinho_Follower"


var triggered = false
var scene = false
var game_won = false
var animation_end = false

func _ready():
	texto = ["Estou impressionado! Parabéns tome 10 tickets para você",
	"Não foi dessa vez, mas não fique triste você pode tentar de novo"]
	Textbox.connect("text_finish", _on_textbox_text_finish)
	Textbox.connect("choice_closed", _on_textbox_choise_closed)
	_animated_sprite.set_sprite_frames(SPRITE)


func interaction():
	if !scene and !game_won:
		triggered = true
		Textbox.queue_text(["Teste sua força para ganhar tickets!"])
	else:
		Textbox.queue_text(["Desculpe garoto, só uma vitoria por pessoa."])
	
func _on_textbox_text_finish():
	if triggered:
		Textbox.display_choice("Você quer tentar garoto ?", ["Sim", "Não"])
	elif scene:
		scene = false
		var comando = teste.get_metodos()["0"][0].substr(5, teste.get_metodos()["0"][2])
		var result = evaluate(comando, ["forca"], [4])
		var tween = create_tween()
		var current_pos = player.get_position()
		tween.tween_callback(player.set_state.bind(States.Player_State.ON_SCENE))
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
			tween.tween_callback(Textbox.queue_text.bind(texto[0]))
		else:
			tween.tween_property(peso, "position", peso.get_position() + Vector2(0, -800), 0.3)
			tween.tween_property(peso, "position", peso.get_position(), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
			await tween.tween_callback(Textbox.queue_text.bind(texto[1])).finished
			cmdzinho.textbox.queue_char_text([dialogo_error[count_errors]],["res://assets/portraits/cmd_feliz.png"])
			count_errors += 1
			if count_errors == 3:
				count_errors = 2
			
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
		tween.tween_callback(player.set_state.bind(States.Player_State.FREE))


func _on_textbox_choise_closed():
	if triggered:
		triggered = false
		match(Textbox.get_choice()):
			0:
				Textbox.queue_text(["Certo, pegue o martelo e dê o seu melhor!"])
				scene = true
			1:
				Textbox.queue_text(["Tudo bem, quem sabe depois"])
				


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
