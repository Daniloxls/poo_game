extends Button


signal select_target
signal skill_end
signal mouse_in
signal mouse_out

var current_skill : SKILL
# Called when the node enters the scene tree for the first time.

func _ready():
	connect_signals()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_press():
	select_target.emit(current_skill.get_target(), get_index(), get_owner().name)

func _on_mouse_entered():
	mouse_in.emit(current_skill.SKLL_NAME)

func _on_mouse_exited():
	mouse_out.emit()

func set_skill(skill : SKILL):
	current_skill = skill

func connect_signals():
	connect("pressed", _on_press)
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	
