class_name VictoryPanel
extends ResultPanel


func show_result(lines: Array[String]) -> void:
	await _present("Vitória!", lines, Color("#fff8e7"))
