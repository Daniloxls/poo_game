extends MarginContainer


var personagem
@onready var class_name_label = $TabContainer/Status/VBoxContainer/ClassNameLabel
@onready var char_status_a = $TabContainer/Status/VBoxContainer/HBoxContainer/RichTextLabel
@onready var char_status_b = $TabContainer/Status/VBoxContainer/HBoxContainer/RichTextLabel2
@onready var char_texture = $TabContainer/Status/VBoxContainer/HBoxContainer/TextureRect
@onready var code_label = $TabContainer/Status/VBoxContainer/CodeLabel
@onready var equipamento_tab = $TabContainer/Equipamento


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_personagem(personagem):
	char_texture.set_texture(personagem.get_sprite())
	class_name_label.clear()
	char_status_a.clear()
	char_status_b.clear()
	code_label.clear()
	equipamento_tab.set_character(personagem)
	class_name_label.push_color(Color("#cf6d1d"))
	class_name_label.append_text("public class ")
	class_name_label.push_color(Color("#228096"))
	class_name_label.append_text(personagem.get_class_name())
	class_name_label.push_color(Color("#ffffff"))
	class_name_label.append_text("{")
	
	#Linha do Nome do Personagem
	char_status_a.push_color(Color("#228096"))
	char_status_a.append_text("String ")
	char_status_a.push_color(Color("#66e1f8"))
	char_status_a.append_text("nome ")
	char_status_a.push_color("#ffffff")
	char_status_a.append_text("= ")
	char_status_a.push_color(Color("green"))
	char_status_a.append_text('"'+ personagem.get_nome() + '"')
	char_status_a.push_color("#ffffff")
	char_status_a.append_text(";\n")
	
	#Linha da vida do Personagem
	char_status_a.push_color(Color("#cf6d1d"))
	char_status_a.append_text("int ")
	char_status_a.push_color(Color("#66e1f8"))
	char_status_a.append_text("hp ")
	char_status_a.push_color("#ffffff")
	char_status_a.append_text("= ")
	char_status_a.push_color(Color("#228096"))
	char_status_a.append_text(str(personagem.get_max_hp()))
	char_status_a.push_color("#ffffff")
	char_status_a.append_text(";\n")
	
	#Linha da magia do Personagem
	char_status_a.push_color(Color("#cf6d1d"))
	char_status_a.append_text("int ")
	char_status_a.push_color(Color("#66e1f8"))
	char_status_a.append_text("pp ")
	char_status_a.push_color("#ffffff")
	char_status_a.append_text("= ")
	char_status_a.push_color(Color("#228096"))
	char_status_a.append_text(str(personagem.get_max_mp()))
	char_status_a.push_color("#ffffff")
	char_status_a.append_text(";\n")
	
	#Linha do ataque do Personagem
	char_status_a.push_color(Color("#cf6d1d"))
	char_status_a.append_text("int ")
	char_status_a.push_color(Color("#66e1f8"))
	char_status_a.append_text("atk ")
	char_status_a.push_color("#ffffff")
	char_status_a.append_text("= ")
	char_status_a.push_color(Color("#228096"))
	char_status_a.append_text(str(personagem.get_atk()))
	char_status_a.push_color("#ffffff")
	char_status_a.append_text(";\n")
	
	#Linha da defesa do Personagem
	char_status_a.push_color(Color("#cf6d1d"))
	char_status_a.append_text("int ")
	char_status_a.push_color(Color("#66e1f8"))
	char_status_a.append_text("def ")
	char_status_a.push_color("#ffffff")
	char_status_a.append_text("= ")
	char_status_a.push_color(Color("#228096"))
	char_status_a.append_text(str(personagem.get_def()))
	char_status_a.push_color("#ffffff")
	char_status_a.append_text(";\n")
	
	#Linha da velocidade do Personagem
	char_status_a.push_color(Color("#cf6d1d"))
	char_status_a.append_text("int ")
	char_status_a.push_color(Color("#66e1f8"))
	char_status_a.append_text("vel ")
	char_status_a.push_color("#ffffff")
	char_status_a.append_text("= ")
	char_status_a.push_color(Color("#228096"))
	char_status_a.append_text(str(personagem.get_vel()))
	char_status_a.push_color("#ffffff")
	char_status_a.append_text(";\n")
	
	#Linha de nivel do Personagem
	char_status_b.push_color(Color("#cf6d1d"))
	char_status_b.append_text("int ")
	char_status_b.push_color(Color("#66e1f8"))
	char_status_b.append_text("level ")
	char_status_b.push_color("#ffffff")
	char_status_b.append_text("= ")
	char_status_b.push_color(Color("#228096"))
	char_status_b.append_text(str(personagem.get_level()))
	char_status_b.push_color("#ffffff")
	char_status_b.append_text(";\n")
	
	#Linha de nivel do Personagem
	char_status_b.push_color(Color("#cf6d1d"))
	char_status_b.append_text("int ")
	char_status_b.push_color(Color("#66e1f8"))
	char_status_b.append_text("exp ")
	char_status_b.push_color("#ffffff")
	char_status_b.append_text("= ")
	char_status_b.push_color(Color("#228096"))
	char_status_b.append_text(str(personagem.get_xp()))
	char_status_b.push_color("#ffffff")
	char_status_b.append_text(";\n")
	
	#Linha de nivel do Personagem
	char_status_b.push_color(Color("#cf6d1d"))
	char_status_b.append_text("int ")
	char_status_b.push_color(Color("#66e1f8"))
	char_status_b.append_text("prox_nivel ")
	char_status_b.push_color("#ffffff")
	char_status_b.append_text("= ")
	char_status_b.push_color(Color("#228096"))
	char_status_b.append_text(str(personagem.get_next_level_xp()))
	char_status_b.push_color("#ffffff")
	char_status_b.append_text(";\n")
	
	code_label.push_color(Color("#808080"))
	code_label.append_text("\t//Habilidades\n")
	for i in personagem.get_skills():
		code_label.push_color(Color("#cf6d1d"))
		code_label.append_text("\tpublic void ")
		code_label.push_color(Color("#25b541"))
		code_label.append_text(str(i.get_skill_name()))
		code_label.push_color(Color("#ffffff"))
		code_label.append_text("(")
		for j in i.get_target_argument():
			code_label.push_color(Color("#228096"))
			code_label.append_text(j)
			code_label.push_color(Color("#4477a6"))
			code_label.append_text(" alvo")
		code_label.push_color(Color("#ffffff"))
		code_label.append_text("){};\n")
		code_label.push_color(Color("#808080"))
		code_label.append_text("\t//")
		code_label.append_text(i.get_description())
		code_label.append_text("\n")
	
	code_label.push_color(Color("#ffffff"))
	code_label.append_text("\n};")

