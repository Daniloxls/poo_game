extends "res://scripts/character.gd"

var menu_sprite

# Called when the node enters the scene tree for the first time.
func _ready():
	# Status de teste para o personagem
	animation.play("default")
	nome = "Turin"
	hp = 2
	max_hp = 26
	mp = 25
	max_mp = 25
	level = 1
	menu_sprite = load("res://assets/characters/legacy/Turin.png")
	atk = 12
	def = 14
	vel = 13
	xp = 0
	rpg_class = load("res://scenes/inventory/classes/protector.tres")
	battle_options.set_button_functions(rpg_class.SKILLS)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
