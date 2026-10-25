class_name ItemPicker
extends Control
## Lista de itens da mochila para o usarItem.

signal _done(item)

const THEME := preload("res://scenes/battle/ui/battle_theme.tres")

var _list: VBoxContainer
var _active := false


func _init() -> void:
	theme = THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"BattlePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	panel.add_child(_list)


func choose(items: Array) -> ITEM:
	if _active:
		_finish(null)
	if items.is_empty():
		return null
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for it in items:
		var b := Button.new()
		b.theme_type_variation = &"MethodButton"
		b.text = "%s  x%d" % [it.ITEM_NAME, it.QUANTITY]
		b.icon = it.ITEM_ICON
		b.expand_icon = true
		b.custom_minimum_size = Vector2(240, 44)
		b.pressed.connect(func(): _finish(it))
		_list.add_child(b)
	visible = true
	_active = true
	_list.get_child(0).grab_focus.call_deferred()
	return await _done


func _unhandled_input(event: InputEvent) -> void:
	if _active and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(null)


func _finish(item) -> void:
	_active = false
	visible = false
	_done.emit(item)
