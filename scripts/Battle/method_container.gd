extends TabContainer

@onready var method_label = $batalha_script/VBoxContainer/MethodLabel

var method_names = [] 
# Called when the node enters the scene tree for the first time.
func _ready():
	set_tab_disabled(0, true)

func clear_text() -> void:
	method_names = []
	
func add_text(text : String) -> void :
	method_names.append(text)
	update_text()

func remove_text():
	method_names.pop_back()
	update_text()
	
func update_text():
	method_label.clear()
	method_label.add_text("		")
	for i in len(method_names):
		match i:
			0:
				method_label.push_color(Color("#228096"))
			1:
				method_label.push_color(Color("#25b541"))
		method_label.add_text(method_names[i])
		method_label.push_color(Color("#ffffff"))
		match i:
			0:
				method_label.add_text(".")
			1:
				method_label.add_text("(")
			2:
				method_label.add_text(",")
	if len(method_names) > 1:
		method_label.add_text(")")
