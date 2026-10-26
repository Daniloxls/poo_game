extends Node
## Preferências do jogador para as falas.

enum Velocidade { LENTA, NORMAL, RAPIDA, INSTANTANEA }

var velocidade_texto: Velocidade = Velocidade.NORMAL
var avanco_automatico: bool = false


func segundos_por_letra() -> float:
	match velocidade_texto:
		Velocidade.LENTA: return 0.05
		Velocidade.RAPIDA: return 0.015
		Velocidade.INSTANTANEA: return 0.0
	return 0.03


func atraso_avanco(letras: int) -> float:
	return 1.2 + 0.035 * letras
