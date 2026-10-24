class_name ComboMeter
extends RefCounted
## Medidor de combo: cada comando digitado no console soma bônus; botões zeram.

const MAX_LEVEL := 5
const BONUS_PER_LEVEL := 0.05

signal changed(level: int)

var level := 0


## Devolve o multiplicador desta ação e sobe o nível (até MAX_LEVEL).
func on_console_action() -> float:
	var multiplicador := 1.0 + level * BONUS_PER_LEVEL
	if level < MAX_LEVEL:
		level += 1
		changed.emit(level)
	return multiplicador


## Ação por botão: sem bônus e zera o combo.
func on_button_action() -> float:
	reset()
	return 1.0


func reset() -> void:
	if level != 0:
		level = 0
		changed.emit(level)
