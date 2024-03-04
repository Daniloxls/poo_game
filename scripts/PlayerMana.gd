extends MarginContainer
@onready var mp_a = $MarginContainer/HBoxContainer/Value
@onready var mp_b = $MarginContainer/HBoxContainer/Value2
@onready var mp_c = $MarginContainer/HBoxContainer/Value3
@onready var mp_d = $MarginContainer/HBoxContainer/Value4

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_mana_instant(value, id):
	var tween = create_tween()
	match(id):
		0:
			mp_a.set_text("MP " + str(value))
		1:
			mp_b.set_text("MP " + str(value))
		2:
			mp_c.set_text("MP " + str(value))
		3:
			mp_d.set_text("MP " + str(value))

func update_mana_slow(value, id):
	var tween = create_tween()
	var current = get_current_mp(id) 
	match(id):
		0:
			tween.tween_method(update_mana_instant.bind(id), current, value, 0.8)
		1:
			tween.tween_method(update_mana_instant.bind(id), current, value, 0.8)
		2:
			tween.tween_method(update_mana_instant.bind(id), current, value, 0.8)
		3:
			tween.tween_method(update_mana_instant.bind(id), current, value, 0.8)

func get_current_mp(id):
		match(id):
			0:
				return int(mp_a.text)
			1:
				return int(mp_b.text)
			2:
				return int(mp_c.text)
			3:
				return int(mp_d.text)
