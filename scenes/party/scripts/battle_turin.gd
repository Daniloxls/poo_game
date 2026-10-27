extends "res://scenes/party/scripts/character.gd"

var menu_sprite

# Called when the node enters the scene tree for the first time.
func _ready():
	# Status de teste para o personagem
	animation.play("default")
	nome = "Turin"
	hp = 10
	max_hp = 26
	pp = 25
	max_pp = 25
	level = 1
	menu_sprite = load("res://assets/characters/legacy/Turin.png")
	atk = 12
	def = 14
	vel = 13
	xp = 0
	rpg_class = load("res://rpg_classes/commoner.tres")
	original_pos = self.get_global_position()
	sprite.connect("sprite_clicked", on_sprite_clicked)
	sprite.connect("mouse_entered", on_sprite_mouse_in)
	sprite.connect("mouse_exited", on_sprite_mouse_out)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
