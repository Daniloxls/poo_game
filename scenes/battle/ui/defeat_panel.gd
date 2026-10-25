class_name DefeatPanel
extends ResultPanel


## Neutro de propósito: derrota é "tente de novo", não castigo.
func show_result(tip: String) -> void:
	await _present("Fim da batalha", [tip], Color("#d9d9de"))
