extends CanvasLayer

signal text_submit
signal close
@onready var line_edit: LineEdit = $LineEdit
@onready var submit_button: Button = $SubmitButton
@onready var close_button: Button = $CloseButton


var regex = RegEx.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	regex.compile("[aAsS]")
	line_edit.connect("text_changed", on_line_edit_text_changed)
	submit_button.connect("pressed", on_submit_button_pressed)
	close_button.connect("pressed", on_close_button_pressed)
	

func _process(delta: float) -> void:
	pass

func on_line_edit_text_changed(new_text):
	var filtered_text = regex.sub(new_text, "", true)
	line_edit.text = filtered_text
	line_edit.caret_column = filtered_text.length()

func on_submit_button_pressed():
	text_submit.emit(line_edit.get_text())

func on_close_button_pressed():
	close.emit()
