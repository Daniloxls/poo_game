extends "res://scripts/character.gd"

var menu_sprite

# Called when the node enters the scene tree for the first time.
func _ready():
	# Status de teste para o personagem
	nome = "Kath"
	hp = 24
	max_hp = 24
	mp = 32
	max_mp = 32
	level = 1
	menu_sprite = load("res://assets/characters/legacy/Kath.png")
	atk = 10
	def = 12
	vel = 17
	xp = 0
	rpg_class = load("res://scenes/inventory/classes/commoner.tres")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
