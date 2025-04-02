extends Button

@onready var battle_inventory = $".."
@onready var mochila = $"../BattleInventoryTabs/Mochila"

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("pressed", close_inventory)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	read_input()

func read_input():
	if Input.is_action_just_pressed("Escape") and battle_inventory.is_visible():
		close_inventory()
		
func close_inventory():
	battle_inventory.hide()
	mochila.emit_signal("close")
