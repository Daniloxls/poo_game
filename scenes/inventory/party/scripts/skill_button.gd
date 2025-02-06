extends Button


signal select_target
signal skill_end

var current_skill : SKILL
# Called when the node enters the scene tree for the first time.

func _ready():
	connect_signals()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_press():
	select_target.emit(current_skill.get_target())
	

func set_skill(skill : SKILL):
	current_skill = skill

func connect_signals():
	connect("pressed", _on_press)
	
