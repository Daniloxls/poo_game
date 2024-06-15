extends "res://scripts/npc_script.gd"

@onready var cutscene = $"../Cutscene"
var triggered = false
var test_direction = [4,2, 4, 1, 4, 1,3,1, 3, 1]
var test_dialogue = [["Havia uma vez um talentoso mago programador chamado Antônio POO. Sua habilidade era tamanha que ele podia manipular a realidade por meio da programação. Mas seu desejo insaciável por poder e desprezo pelas regras o conduziram a um caminho sombrio e perigoso."],
["Antônio começou a experimentar com poderes proibidos, distanciando-se das técnicas tradicionais dos magos programadores. Recusou-se a seguir a abordagem orientada a objetos, uma norma entre os magos. Sua magia tornou-se corrompida, e sua alma, antes pura, agora se tingia de escuridão."],
["As consequências foram desastrosas. Ele semeou caos e destruição, desafiando as autoridades e ameaçando o próprio reino. Eventualmente, foi expulso da ordem dos programadores e banido do reino. A dor da traição e a sede de vingança ardiam em seu coração."],
["Mas Anti-POO não permaneceu em exílio por muito tempo. Ele retornou, mais poderoso e determinado do que nunca. Enfrentou e derrotou muitos soldados do reino, deixando um rastro de devastação por onde passava. Sua vingança estava apenas começando."],
["No entanto, nem todos haviam perdido a esperança. Alan, um velho amigo de Anti-POO, tentou convencê-lo a se render, a abandonar o caminho da destruição. Mas suas palavras caíram em ouvidos surdos. Anti-POO estava além da redenção."],
["Desesperado, o rei ordenou que Alan forjasse uma armadura capaz de resistir à magia corrupta de Anti-POO. Além disso, Alan criou uma espada mágica, capaz de cortar todo o código gerado pela programação do vilão. Ele sabia que a única forma de impedir Anti-POO era enfrentá-lo em batalha."],
["A batalha foi feroz e brutal. Alan, com sua armadura e espada mágica, enfrentou seu antigo amigo. Os dois se encararam, sabendo que apenas um sairia vitorioso."],
["Após uma luta acirrada, Alan finalmente derrotou Anti-POO. A espada mágica cortou através do código corrompido, encerrando o reinado de terror do vilão."],
["Mas a vitória teve um custo alto. O reino estava em ruínas, com vidas perdidas e destruição por toda parte. O sacrifício necessário para derrotar Anti-POO deixou cicatrizes profundas."],
["Alan, incapaz de matar seu velho amigo, selou Anti-POO em um local secreto. Apenas ele conhecia a localização, e o segredo foi bem guardado. Temendo que outros seguissem o mesmo caminho sombrio, o rei proibiu o uso da programação, na esperança de evitar futuras catástrofes."]]

var scene_path = "res://assets/cutscene/antipoo_past/"

var scene_size = 10



func interaction():
	triggered = true
	textbox.queue_text(["Olá, Turin. Eu me chamo MacAlistair.", "Você teve muita sorte por eu estar por perto quando o Anti-POO atacou você e a mocinha ali.", "Quem é Anti-POO? Ah, esses jovens de hoje em dia...", "Deixe-me contar uma história para vocês."])
	pass




func _on_textbox_text_finish():
	if triggered:
		cutscene.play(test_dialogue, test_direction, scene_path, scene_size)
	pass # Replace with function body.
