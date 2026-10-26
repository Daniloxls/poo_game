extends "res://entities/npc/npc_script.gd"

const DIALOGO = preload("res://scenes/chapter_one/festival_city/dialogos/teste_forca.dialogue")

@onready var peso = $Peso
@onready var teste = $TesteDeForca
@onready var camera = get_node("../Player/Camera2D")
@onready var tickets = get_node("../Tickets")

# Lidas e escritas por teste_forca.dialogue.
var quer_tentar := false
var erros := 0
var game_won := false


func _ready():
	_animated_sprite.set_sprite_frames(SPRITE)


func interaction():
	if game_won:
		await Dialogo.iniciar(DIALOGO, "ja_ganhou", [self])
		return
	quer_tentar = false
	await Dialogo.iniciar(DIALOGO, "convite", [self])
	if not quer_tentar:
		return
	var result = teste.testar(4)
	PlayerState.set_on_scene(true)
	var tween = create_tween()
	var current_pos = player.get_position()
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
	else:
		tween.tween_property(peso, "position", peso.get_position() + Vector2(0, -800), 0.3)
		tween.tween_property(peso, "position", peso.get_position(), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	await tween.finished

	if result:
		game_won = true
		await Dialogo.iniciar(DIALOGO, "ganhou", [self])
	else:
		await Dialogo.iniciar(DIALOGO, "perdeu", [self])
		if Historia.cmdzinho_resgatado:
			erros = mini(erros + 1, 3)
			await Dialogo.iniciar(DIALOGO, "dica", [self])

	tween = create_tween()
	tween.tween_property(camera, "offset", Vector2(0, 0), 1)
	if game_won:
		tween.tween_callback(tickets.show)
		tween.tween_callback(tickets.recieve_tickets.bind(10))
	tween.tween_callback(player.set_sprite.bind("walk_left"))
	tween.tween_property(player, "position", Vector2(4973, -12123), abs(7000 - 4973)/500)
	tween.tween_callback(player.set_z_index.bind(2))
	tween.tween_callback(teste.set_colision.bind(true))
	tween.tween_callback(PlayerState.set_on_scene.bind(false))
	await tween.finished


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
