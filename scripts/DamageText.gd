extends Label

# DamageText é o numero que aparece quando algum personagem toma dano

# Posição que o numero deve aparecer em relação ao cursor
const FONT_POSITION = Vector2(-23,-9)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Função recebe o numero do dano e mostra ele fazendo uma curva para algum lado
func number_animation(n):
	show()
	var tween = create_tween()
	var start = FONT_POSITION
	var middle
	var end
	# aleatoriza se é para esquerda ou direita
	match(randi_range(1,2)):
		1:
			middle = Vector2 (randi_range(10, 16), randi_range(-8, -16))
			end = Vector2(randi_range(20, 28), 8)
		2:
			middle = Vector2 (randi_range(-10, -16), randi_range(-8, -16))
			end = Vector2(randi_range(-20, -28), 8)
			
	# Adiciona o offset da posição
	middle += FONT_POSITION
	end += FONT_POSITION
	set_text(str(n))
	# Realiza a função de criar a curva 100 vezes 
	tween.tween_method(_quadratic_bezier.bind(start, middle, end)
	,0, 100, 0.4)
	# Dá uma pausa de 0..4 segundos antes de esconder o numero e volta o numero
	# para a posição original
	tween.tween_interval(0.4)
	tween.tween_callback(hide)
	tween.tween_callback(set_position.bind(FONT_POSITION))
	
# Calcula um ponto de uma curva com base no tempo e nos três pontos passados
# e coloca o numero nessa posição
func _quadratic_bezier(t: float, p0: Vector2, p1: Vector2, p2: Vector2):
	t = t/100
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	set_position(r)


	
