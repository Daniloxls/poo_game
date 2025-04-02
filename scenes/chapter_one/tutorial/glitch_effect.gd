extends "res://scenes/main/scripts/event.gd"

@onready var portal = $Portal/Sprite
@onready var espinhos = $Espinhos/Sprite
@onready var estatica = $ScreenFlash
@onready var estatica_sprite = $ScreenFlash/Sprite


func _on_area_2d_area_entered(area):
	if !triggered:
		triggered = true
		var tween = create_tween()
		estatica.show()
		tween.tween_property(estatica_sprite, "modulate",Color(255, 255, 255, 0), 1).set_trans(Tween.TRANS_SINE)
		portal.set_frame_and_progress(1,0)
		espinhos.set_frame_and_progress(1,0)
