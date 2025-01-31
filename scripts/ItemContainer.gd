extends MarginContainer
# ItemContainer é uma celula do inventario que mostra um item

signal mouseover
signal mouseout
signal click

@onready var item_icon = $ItemContainer/ItemIcon

@onready var item_name = $ItemContainer/ItemName
@onready var quantity = $ItemContainer/ItemQuantity
@onready var button = $Button

var local_item : ITEM
var description
# Called when the node enters the scene tree for the first time.
func _ready():
	button.connect("mouse_entered", _on_mouse_entered)
	button.connect("mouse_exited", _on_mouse_exited)
	button.connect("pressed", _on_click)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Função que apenas coloca as informações do item na celula
func set_item(item : ITEM):
	local_item = item
	item_icon.set_texture(item.get_icon())
	item_name.set_text(item.get_item_name())
	quantity.set_text(str(item.get_quantity()))
	description = item.get_item_text()

func get_item():
	return local_item
	
func update_item_quantity(qtd: int):
	quantity.set_text(str(qtd))
	
func _on_click():
	click.emit(self)

func _on_mouse_entered():
	mouseover.emit(description)
	
func _on_mouse_exited():
	mouseout.emit()
