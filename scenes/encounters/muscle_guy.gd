extends "res://entities/encounters/enemy.gd"

@onready var lutador = get_tree().current_scene.get_node("LutadorNPC/LutadorInteract")
@onready var error = $ErrorLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	nome = "Montanha"
	classe = "Lutador"
	max_hp = 32
	animation.play("default")
	hp = max_hp
	def = 12
	vel = 3
	atk = 5
	enemy_ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func choose_action(party: Array, enemies: Array) -> EnemyAction:
	var action := EnemyAction.new()
	var alvo = party[0]
	# o ataque usa o código Java do Lutador (que o jogador pode ter editado)
	var dano: int = lutador.calcular_dano(alvo)
	if dano < 0:
		action.error_text = "atacar() falhou: o código do Lutador tem erro"
	else:
		action.outcomes.append(ActionOutcome.make(alvo, ActionOutcome.Kind.DAMAGE, dano, DamageType.Kind.SOCO))
	return action

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
	current_state = State.DEFAULT
	if hp == 0:
		death.emit()
	else:
		animation_end.emit()
