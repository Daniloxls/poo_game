extends "res://entities/encounters/enemy.gd"


# Called when the node enters the scene tree for the first time.
func _ready():
	nome = "Boneco_de_Teste"
	classe = "Boneco"
	max_hp = 27
	animation.play("default")
	hp = max_hp
	def = 5
	vel = 2
	atk = 3
	enemy_ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func choose_action(party: Array, enemies: Array) -> EnemyAction:
	var action := EnemyAction.new()
	var vivos := party.filter(func(c): return c.is_alive())
	if not vivos.is_empty():
		action.outcomes.append(ActionOutcome.make(vivos.pick_random(), ActionOutcome.Kind.DAMAGE, randi_range(2, 5), DamageType.Kind.SOCO))
	return action

