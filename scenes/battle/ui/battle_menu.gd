extends CanvasLayer

signal animation_end

@onready var enemy_container = $"EnemyContainer/Inimigo[ ]/VBoxContainer"
@onready var party_container = $"PartyContainer/Personagem[ ]/BattleCharContainer"
@onready var method_container = $MethodContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	for char in party_container.get_children():
		char.connect("animation_end", _on_char_animation_end)
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_characters(char_list):
	var party_status = party_container.get_children()
	for i in len(char_list):
		party_status[i+1].set_values(char_list[i])
		
func add_enemies(enemy_list):
	for enemy in enemy_list:
		var instance = load("res://scenes/battle/ui/EnemyButton.tscn")
		var enemy_button = instance.instantiate()
		enemy_button.set_text(enemy.get_name())
		enemy_container.add_child(enemy_button)
		enemy.connect_button(enemy_button)

func pop_enemy_button(id):
	enemy_container.remove_child(enemy_container.get_child(id))
	
func change_char_health(id, damage):
	party_container.get_child(id+1).change_hp(damage)
	
func add_to_method_text(text):
	method_container.add_text(text)
	
func pop_method_text():
	method_container.remove_text()

func clear_method_text():
	method_container.clear_text()
	
func _on_char_animation_end():
	animation_end.emit()
