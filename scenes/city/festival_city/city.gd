extends Node2D
@onready var battle = $"../../Battle"
@onready var root = $"../.."
@onready var sword_scene = $Cutscene
@onready var player = $Player
@onready var music =  $"../../AudioPlayer"

signal battle_won
signal battle_lost

# Called when the node enters the scene tree for the first time.
func _ready():
	var bg = load("res://assets/battle/background/tatame.png")
	root.battle_lost.connect(_on_root_battle_lost)
	root.battle_won.connect(_on_root_battle_won)
	battle.set_background(bg)
	music.set_stream(load("res://assets/bgm/Enchanted-Festival-Loop.mp3"))
	music.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_root_battle_lost():
	battle_lost.emit()
	
func _on_root_battle_won():
	battle_won.emit()
