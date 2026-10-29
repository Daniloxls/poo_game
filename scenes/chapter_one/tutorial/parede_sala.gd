extends StaticBody2D
## Parede de saída de uma sala do tutorial: some quando o item do checklist marca.

const ABERTA := preload("res://assets/props/placeholder/ParedeRetratiuDown.png")
const REGIAO_ABERTA := Rect2(0, 2360, 500, 1500)   # as lajes recolhidas, no pé da imagem

var aberta := false

@onready var sprite: Sprite2D = $Sprite
@onready var shape: CollisionShape2D = $Shape


func abrir() -> void:
	if aberta:
		return
	aberta = true
	var t := create_tween()
	t.tween_property(sprite, "modulate:a", 0.0, 0.4)
	await t.finished
	sprite.texture = ABERTA
	sprite.region_rect = REGIAO_ABERTA
	sprite.modulate.a = 1.0
	shape.set_deferred("disabled", true)
