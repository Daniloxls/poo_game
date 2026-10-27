extends "res://scenes/main/scripts/java_interact.gd"

# Tenda do Tritomos: a bola de cristal mostra o retorno de leitorDePensamento().
# O jogador só muda o 'return'; o interpretador garante que volte uma String.
# Erros no código aparecem no painel de código (Executar), não na tela dele.
# A tela é TelaTritomos.tscn.

@onready var interface = $VidenteInterface
@onready var pensamento_field: LineEdit = $VidenteInterface/%Pensamento
@onready var think_button: Button = $VidenteInterface/%Pensar
@onready var imagem: TextureRect = $VidenteInterface/%Imagem
@onready var linha: Control = $VidenteInterface/%Linha
@onready var bilhete: Control = $VidenteInterface/%Bilhete
@onready var bolha: Control = $VidenteInterface/%Bolha
@onready var rabo: Control = $VidenteInterface/%Rabo
@onready var brilho: Control = $VidenteInterface/%Brilho
@onready var nevoa: Control = $VidenteInterface/%Nevoa
@onready var tickets = $"../Tickets"

const DIALOGO = preload("res://scenes/chapter_one/festival_city/dialogos/tritomos.dialogue")
# O balão com o que a bola mostrou fica à direita dela, com o bico apontando para a bola.
const ALTURA_DA_BOLA := 304.0          # y do centro da bola de cristal no painel
const LARGURA_MAXIMA_BOLHA := 310.0    # até a borda direita da moldura

var palavra := ""   # lida por tritomos.dialogue
var conversando := false   # tem conversa do Tritomos em andamento
var first_interaction = true
var _efeitos: Array[Tween] = []

enum State{
	FIRST,
	OPEN,
	BEATEN,
	FINISHED,
	CLOSED
}
var current_state = State.FIRST
# Called when the node enters the scene tree for the first time.
func _ready():
	glifos.show()
	nome = "LeitorDePensamento"
	dica_java = "Você só pode mudar o que a função retorna."
	codigo_java = """public class LeitorDePensamento {

    public String leitorDePensamento(Personagem jogador) {
        String resposta = jogador.getPensamento();
        return {|resposta|};
    }
}
"""
	ready_drop_menu()
	think_button.pressed.connect(_on_button_pressed)
	$VidenteInterface/%Fechar.pressed.connect(_on_close_pressed)
	pensamento_field.text_submitted.connect(func(_t): _on_button_pressed())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("x") and !pensamento_field.has_focus():
		if current_state != State.CLOSED and current_state != State.FIRST and not conversando:
			close_window()

func interaction():
	PlayerState.set_on_interface(true)
	triggered = true
	open_window()
	if current_state == State.FINISHED:
		return
	if first_interaction:
		await Dialogo.iniciar(DIALOGO, "boas_vindas", [self])
		first_interaction = false
	current_state = State.OPEN


# O que a bola de cristal mostra para 'pensamento'. Null se o código der erro
# ou não devolver uma String (a mensagem fica em ultimo_erro).
func ler_pensamento(pensamento: String):
	var jogador := JavaRuntime.personagem({"nome": "Turin", "pensamento": pensamento})
	var r = executar_java("leitorDePensamento", [jogador])
	if ultimo_erro == "" and r is not String:
		JavaRuntime.erro_do_jogo(self, "A bola de cristal não mostrou nada: leitorDePensamento() precisa retornar uma String, não null.")
	return r if ultimo_erro == "" else null


# Executar no painel de código: roda o leitor para o erro aparecer lá.
func ao_executar_codigo() -> void:
	ler_pensamento("")


func open_window():
	interface.show()

func close_window():
	triggered = false
	interface.hide()
	_limpar_bola()
	PlayerState.set_on_interface(false)
	if current_state != State.FINISHED:
		linha.show()
		current_state = State.CLOSED


func _on_button_pressed():
	if conversando:
		return
	var pensamento = pensamento_field.get_text()
	var visto = ler_pensamento(pensamento)
	conversando = true
	if visto == null:   # código com erro: a bola fica embaçada (o erro está no painel de código)
		_mostrar_nevoa()
		await Dialogo.iniciar(DIALOGO, "embacada", [self])
		_limpar_bola()
		conversando = false
		return
	pensamento_field.clear()
	palavra = visto
	_mostrar_palavra(visto)
	if visto == pensamento:
		await Dialogo.iniciar(DIALOGO, "acertou", [self])
		conversando = false
		if current_state == State.OPEN:
			close_window()
	else:
		current_state = State.BEATEN
		await Dialogo.iniciar(DIALOGO, "errou", [self])
		tickets.show()
		tickets.recieve_tickets(10)
		imagem.texture = load("res://assets/props/city/vidente_left.png")
		current_state = State.FINISHED
		linha.hide()
		bilhete.show()
		conversando = false
		close_window()


func _on_close_pressed():
	if conversando:
		return
	close_window()


# O que a bola mostrou aparece num balão ao lado dela, com a bola brilhando.
func _mostrar_palavra(texto: String) -> void:
	_limpar_bola()
	var rotulo: Label = $VidenteInterface/%Palavra
	rotulo.text = texto
	# palavra comprida diminui a letra para o balão não passar da moldura
	var tamanho := 34
	rotulo.add_theme_font_size_override("font_size", tamanho)
	bolha.reset_size()
	while bolha.size.x > LARGURA_MAXIMA_BOLHA and tamanho > 16:
		tamanho -= 2
		rotulo.add_theme_font_size_override("font_size", tamanho)
		bolha.reset_size()
	bolha.position.y = ALTURA_DA_BOLA - bolha.size.y / 2
	rabo.position.y = ALTURA_DA_BOLA - rabo.size.y / 2
	bolha.pivot_offset = Vector2(0, bolha.size.y / 2)
	for n in [bolha, rabo, brilho]:
		n.show()
	var t := create_tween()
	t.tween_property(bolha, "scale", Vector2.ONE, 0.3).from(Vector2(0.4, 0.4)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_efeitos.append(t)
	var pulso := create_tween().set_loops()
	pulso.tween_property(brilho, "scale", Vector2(1.15, 1.15), 0.6).from(Vector2.ONE).set_trans(Tween.TRANS_SINE)
	pulso.tween_property(brilho, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	_efeitos.append(pulso)


# Bola embaçada: nuvens cinza rodando em cima dela.
func _mostrar_nevoa() -> void:
	_limpar_bola()
	nevoa.show()
	nevoa.rotation = 0.0
	var t := create_tween().set_loops()
	t.tween_property(nevoa, "rotation", TAU, 4.0).from(0.0)
	_efeitos.append(t)


func _limpar_bola() -> void:
	for t in _efeitos:
		t.kill()
	_efeitos.clear()
	for n in [bolha, rabo, brilho, nevoa]:
		n.hide()
