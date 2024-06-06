extends Node2D

var string = "forca > 8"


var dict = {
	"boolean teste_de_forca(int: forca){": [0,0],
	"\tboolean sucesso;": [0,0],
	"\tif (forca > 10){": [5,10],
	"\t\tsucesso = true\n\t}": [0,0],
	"\telse{": [0,0],
	"\t\tsucesso = false;\n\t}" : [0,0],
	"\treturn sucesso;\n}": [0,0]
}
# Called when the node enters the scene tree for the first time.
func _ready():
	for key in dict.keys():
		if dict[key] != [0,0]:
			print(key.substr(dict[key][0], dict[key][1]))
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func evaluate(command, variable_names = [], variable_values = []) -> void:
	var expression = Expression.new()
	var error = expression.parse(command, variable_names)
	if error != OK:
		push_error(expression.get_error_text())
		return

	var result = expression.execute(variable_values, self)

	if not expression.has_execute_failed():
		print(str(result))
