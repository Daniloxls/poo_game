# Editor de código do jogo (com partes travadas)

Painel lateral com editor de Java para o jogador, feito para usar junto com o
`addons/java_interpreter`. Testado no **Godot 4.3**.

- Fica na borda direita da tela e recolhe para uma aba fina ("CÓDIGO").
  O jogador pode arrastar a borda esquerda para deixar mais largo.
- Cores de Java, números de linha, botão Executar (ou Ctrl+Enter), Recomeçar
  e um console embaixo para a saída e os erros.
- Erros do interpretador marcam a linha em vermelho (bolinha na margem e
  dica ao passar o mouse). Clicar no erro do console leva até a linha.
- **O level designer escolhe o que pode ser editado**, até pedaços de uma
  linha (só a condição de um `if`, só um número...).

Para ver funcionando, abra `exemplos/demo_editor/demo_editor.tscn` e aperte F6
(três fases com o robô: só a condição, valor + bloco, e código livre).

## Instalar

Copie `addons/java_code_editor/` para o projeto (precisa também do
`addons/java_interpreter/`). As classes são globais, não precisa ativar plugin.

| Arquivo | Classe | Papel |
|---|---|---|
| `java_code_panel.gd` | `JavaCodePanel` | O painel lateral completo (o que você vai usar no jogo). |
| `locked_code_edit.gd` | `LockedCodeEdit` | O editor em si (um `CodeEdit`), com as travas. Dá para usar sozinho num layout seu. |
| `editable_markup.gd` | `JavaEditableMarkup` | Lê a marcação `{| |}`. |
| `java_region_highlighter.gd` | `JavaRegionHighlighter` | Cores de Java; apaga (acinzenta) o que está travado. |

## Marcando o que o jogador pode editar

O designer escreve o código normalmente e envolve as partes editáveis com
`{|` e `|}`. **Tudo fora das marcas fica travado.** As marcas não aparecem para
o jogador e não vão para o interpretador.

### Pedaço de uma linha

```java
while ({|temParedeNaFrente()|}) {
    andar();
}
```

O jogador só consegue mudar `temParedeNaFrente()`: os parênteses, o `while`
e o resto ficam travados. Pode apagar tudo e escrever outra coisa, mas não
pode pôr Enter (fica numa linha só). Para começar vazio: `if ({||}) {`.

### Bloco de várias linhas

Com o marcador **sozinho na linha**, as linhas entre eles viram um bloco
livre. Ali o jogador pode criar e apagar linhas à vontade:

```java
public void executar() {
    andarVarios(passos);
    {|
    // escreva aqui o resto do caminho
    |}
}
```

As linhas com `{|` e `|}` somem. Um bloco vazio (`{|` logo seguido de `|}`)
vira uma linha em branco já com o recuo certo.

### Vários pedaços, e código livre

Pode ter quantas marcas quiser no mesmo código, de um tipo ou do outro.
Sem nenhuma marca, o código fica todo livre (se quiser que fique só para
leitura, ponha `editor.livre_sem_marcas = false`).

Erros de marcação (esqueceu de fechar, fechou sem abrir, uma dentro da outra)
aparecem no Output do Godot com o número da linha, e `open_code` devolve `false`.

## Para o jogador

- O que dá para editar aparece com uma caixa azul e cores normais; o resto
  fica apagado, com um cadeado na margem.
- Tentar mudar uma parte travada não faz nada: a linha pisca e a barra de
  status explica ("Essa parte do código está travada...").
- **Tab** pula para a próxima parte editável (e já seleciona o conteúdo);
  Shift+Tab volta. Dentro de um bloco, Tab recua o código normalmente.
- Ctrl+Z / Ctrl+Y desfazem e refazem. Recomeçar volta ao código original
  (e também dá para desfazer).

## Usando no jogo

```gdscript
var java := JavaInterpreter.new()
@onready var painel := JavaCodePanel.new()

func _ready():
    $CanvasLayer.add_child(painel)            # CanvasLayer = fica por cima do jogo
    painel.open_code(CODIGO_DA_FASE, "Porta da fase 1", "Complete a condição do if")
    painel.run_requested.connect(_executar)
    java.output.connect(painel.print_output)  # System.out.println vai pro console

func _executar(codigo: String):
    if not java.load_source(codigo, "porta"):
        painel.show_error(java.get_error_text(), java.last_error.line)
        return
    # ... create_object / call_method ...
    if java.has_error():
        painel.show_error(java.get_error_text(), java.last_error.line)
    else:
        painel.print_success("A porta abriu!")
```

O texto do editor é exatamente o código que vai para o interpretador, então
a linha do erro é a linha que o jogador vê.

### API do `JavaCodePanel`

| | |
|---|---|
| `open_code(template, titulo = "", dica = "") -> bool` | Carrega o código (com marcas) e abre o painel. |
| `get_code() -> String` | Código atual, limpo. |
| `get_region_texts() -> PackedStringArray` | O que o jogador escreveu em cada parte editável, na ordem. Bom para conferir a resposta (ex.: a condição tem `!`?). |
| `show_error(msg, linha)` | Mostra o erro no console e marca a linha. |
| `print_output(texto)`, `print_success(texto)`, `clear_output()` | Console. |
| `set_running(bool)` | Desliga o botão Executar enquanto o jogo anima. |
| `expand()`, `collapse()`, `toggle()`, `aberto` | Abrir e recolher. |
| `is_typing() -> bool` | `true` se o jogador está digitando: use para o personagem não andar com as teclas. |
| `editor` | O `LockedCodeEdit` (para `get_state()`, cores etc.). |
| sinais | `run_requested(code)`, `code_changed`, `toggled(aberto)` |
| exports | `largura`, `largura_minima`, `comecar_aberto`, `fonte_codigo`, `tamanho_fonte`, `altura_console` |

### Salvar o progresso do jogador

```gdscript
var estado := painel.editor.get_state()      # Dictionary simples, vai em JSON
painel.editor.set_state(estado)              # volta com as mesmas travas
```

### Fonte

O editor usa uma fonte monoespaçada do sistema (JetBrains Mono, Consolas,
DejaVu Sans Mono...). Em jogo exportado, principalmente na Web, é melhor
colocar um `.ttf` no projeto e passar em `fonte_codigo`.

### Pausar o jogo enquanto edita

O painel tem `process_mode = ALWAYS`, então funciona com o jogo pausado.
Se quiser pausar: `painel.toggled.connect(func(aberto): get_tree().paused = aberto)`.

## Como a trava funciona (para quem for mexer no código)

O editor não tenta bloquear cada tecla. Depois de cada mudança ele compara o
texto novo com o último texto aceito e descobre o trecho que mudou. Se esse
trecho está inteiro dentro de uma região editável, aceita e atualiza as
posições das regiões; se não, volta o texto como estava. Assim qualquer jeito
de editar é coberto (digitar, colar, recortar, Ctrl+Backspace, completar
chaves, recuo automático...). Por isso o desfazer também é próprio do editor:
o desfazer do Godot poderia trazer de volta uma mudança proibida.

Limitações conhecidas: um cursor só (sem multicursor), sem quebra automática
de linha, e arrastar texto com o mouse está desligado.

## Testes

```
godot --headless --path . --script res://tests/test_editor.gd
```

42 testes: marcação, trava (digitar nas bordas, apagar, seleção que passa da
região, Enter em região de uma linha), desfazer/refazer, salvar estado, linha
do erro batendo com o interpretador e as três fases da demo resolvidas.
