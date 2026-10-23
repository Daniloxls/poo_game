# Objetos com código Java de verdade

Objetos que estendem `scenes/main/scripts/java_interact.gd` têm o código em Java,
executado pelo interpretador (`addons/java_interpreter`). O item "Depurar" do
menu abre o painel de código (`addons/java_code_editor`) no lado direito da tela,
em vez da Codebox. Os objetos antigos (`codigo`/`metodos`) continuam usando a
Codebox, então dá para migrar um puzzle de cada vez.

## Criando um objeto

```gdscript
extends "res://scenes/main/scripts/java_interact.gd"

func _ready():
    shader_rect.show()
    nome = "Porta"
    classe_java = "Porta"
    dica_java = "Mude a condição para abrir a porta."
    codigo_java = """public class Porta {

    private native void abrir();   // feito em GDScript, logo abaixo

    public void tentar(String senha) {
        if ({|senha.equals("1234")|}) {
            abrir();
        }
    }
}
"""
    ready_drop_menu()

# Chamado pelo Java (private native void abrir();)
func abrir():
    $AnimatedSprite2D.set_frame_and_progress(1, 0)

func interaction():
    executar_java("tentar", ["0000"])
    if ultimo_erro != "":
        Textbox.queue_text(["O código da porta tem um erro."])
```

- O que fica entre `{|` e `|}` é o que o jogador pode editar. O resto fica travado.
  Com `{|` e `|}` sozinhos na linha, vira um bloco de várias linhas.
- `executar_java(metodo, args)` roda um método da classe e devolve o retorno
  (ou `null` com erro; a mensagem fica em `ultimo_erro` e aparece no console
  do painel).
- Métodos `native` no Java chamam o método de mesmo nome no script do objeto.
- `JavaRuntime.personagem(x)` cria um `Personagem` Java a partir de um nó de
  batalha ou de um Dictionary (`getNome`, `getHp`, `getMaxHp`, `getForca`,
  `getAtaque`, `getDefesa`).
- Ganchos: `ao_abrir_codigo()`, `ao_executar_codigo()` (o jogador apertou
  Executar e compilou), `ao_fechar_codigo()`. `resetar_codigo_java()` volta ao original.

Exemplos convertidos: `strenght_test.gd` (Teste de Força, retorno boolean) e
`fighter_npc.gd` + `muscle_guy.gd` (Lutador, método native `causarDano`).

## Testes

```
godot --headless --path . --script res://tests/run_tests_java.gd        # interpretador
godot --headless --path . --script res://tests/test_integracao_java.gd  # cidade do festival
```
