extends "res://scripts/enemy.gd"

@onready var lutador = get_node("../../../Level/City/LutadorNPC")

# Called when the node enters the scene tree for the first time.
func _ready():
	nome = "Montanha"
	max_hp = 32
	animation.play("default")
	hp = max_hp


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func logic(character_list, menu):
	var metodos =  lutador.get_methods()
	var executar = metodos["0"][0].substr(metodos["0"][1],metodos["0"][2])
	var alvo = {}
	alvo["alvo"] = character_list[0]
	if executar.is_valid_int():
		menu.update_health_slow(0, character_list[0].lose_health(int(executar)))
	elif executar.get_slice(".", 0) in alvo.keys():
		var dano =  evaluate(executar.get_slice(".", 1), alvo[executar.get_slice(".", 0)])
		menu.update_health_slow(0, character_list[0].lose_health(dano))
	else:
		pass
	
	
func evaluate(command, object = self, variable_names = [], variable_values = []) -> int:
	var expression = Expression.new()
	var error = expression.parse(command, variable_names)
	if error != OK:
		push_error(expression.get_error_text())
		return 0
	var result = expression.execute(variable_values, object)
	if not expression.has_execute_failed():
		if result:
			return result
		else:
			return 0
	else:
		return 0


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		death.emit()
