extends "res://scenes/main/scripts/interact.gd"

@onready var player_sprite = get_node("../Player/AnimatedSprite2D")
@onready var terminal_interface = $TerminalInterface

var current_state = State.BEFORE_SUDO
enum State{
	BEFORE_SUDO,
	SUDO,
	AFTER_SUDO
}
var error_count = 0

func _ready() -> void:
	terminal_interface.connect("window_closed", _on_terminal_windowed_closed)
	
	
func interaction():
	if PlayerState.is_able_to_move():
		PlayerState.set_on_interface(true)
	terminal_interface.show()
	match current_state:
		State.BEFORE_SUDO:
			Textbox.queue_char_text(["Certo, tente digitar 'sudo' nesse teclado e aperte enter."], ["res://assets/portraits/silhueta.png"])
		State.SUDO:
			Textbox.queue_char_text(["Pelo que me lembro, a senha era senha123."], ["res://assets/portraits/silhueta.png"])
		

func sudo_scene():
	PlayerState.set_on_scene(true)
	var tween = create_tween()
	tween.tween_property(player_sprite, "modulate", Color.GREEN, 1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(player_sprite, "scale", Vector2(3, 1), 1).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(player_sprite, "scale", Vector2(1, 3), 1).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(player_sprite, "scale", Vector2(1, 1), 1).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(player_sprite, "rotation", 360, 2).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(player_sprite, "rotation", 0, 1).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(player_sprite, "modulate", Color.WHITE, 1).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(player.set_sudo.bind(true))
	tween.tween_callback(PlayerState.set_on_scene.bind(false))

func _on_terminal_interface_sudo_typed():
	current_state = State.SUDO
	error_count = 0
	Textbox.queue_char_text(["Pelo que me lembro, a senha era senha123."], ["res://assets/portraits/silhueta.png"])


func _on_terminal_interface_sudo_activated():
	current_state = State.AFTER_SUDO
	terminal_interface.hide()
	PlayerState.set_on_interface(false)
	sudo_scene()


func _on_terminal_interface_command_missed():
	error_count += 1
	if error_count == 3:
		Textbox.queue_char_text(["Talvez você não tenha me ouvido... digite sudo nesse terminal e aperte enter"], ["res://assets/portraits/silhueta.png"])

func _on_terminal_interface_password_missed():
	error_count += 1
	if error_count > 5:
		Textbox.queue_char_text(["Eu já disse, a senha é senha123"], ["res://assets/portraits/silhueta.png"])

func _on_terminal_windowed_closed():
	PlayerState.set_on_interface(false)
