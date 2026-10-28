extends CanvasLayer
## Orquestrador da batalha: rodadas e turnos guiados pela pilha de chamadas.
## Um fluxo só (corrotina): empilha a rodada, o topo age, desempilha, repete.

signal battle_won
signal battle_lost
signal turn_started(entity)
signal _acted  # o membro do grupo terminou a ação do turno

const MARKER_OFFSET := Vector2(-10, -110)

var stack := CallStack.new()
var combo := ComboMeter.new()

@onready var fx: BattleFx = $BattleFx
@onready var pacing: BattlePacing = fx.pacing  # o único ritmo da batalha
@onready var field: BattleField = $Field
@onready var target_selector: TargetSelector = $TargetSelector
@onready var ui: CanvasLayer = $UI
@onready var enemy_status: EnemyStatus = $UI/Root/EnemyStatus
@onready var party_status: PartyStatus = $UI/Root/PartyStatus
@onready var stack_panel: StackPanel = $UI/Root/StackPanel
@onready var marker: Label = $UI/Root/TurnMarker
@onready var action_menu: ActionMenu = $UI/Root/ActionMenu
@onready var item_picker: ItemPicker = $UI/Root/ItemPicker
@onready var console: BattleConsole = $UI/Root/BattleConsole
@onready var victory_panel: VictoryPanel = $UI/Root/VictoryPanel
@onready var defeat_panel: DefeatPanel = $UI/Root/DefeatPanel

var _running := false
var _group: Node2D          # o nó "Enemies" desta batalha
var _party: Array = []
var _enemies: Array = []    # todos, vivos ou destruídos (o console diz "é null")
var _down: Array = []       # destruídos/nocauteados já tratados
var _acting = null          # membro do grupo esperando comando; null fora do turno dele
var _max_combo := 0
var _marker_tween: Tween
var _inventory_mode := -1   # process_mode do Inventory antes da batalha


func _ready() -> void:
	fx.shake_target = field
	fx.overlay = $FxLayer
	stack_panel.pacing = pacing
	fx.hp_changed.connect(_refresh_status)
	stack_panel.bind(stack, func(e): return e.global_position)
	$UI/Root/ComboView.bind(combo)
	combo.changed.connect(func(level): _max_combo = maxi(_max_combo, level))
	action_menu.skill_chosen.connect(_on_skill_chosen)
	console.command_ready.connect(run_command.bind(true))
	console.exited.connect(_focus_menu)
	$UI/Root/ConsoleButton.pressed.connect(func(): if console.can_process(): console.open())
	_show(false)


func set_background(bg: Texture2D) -> void:
	$Background.texture = bg


func start_battle(enemy_group_path: String) -> void:
	if _running:
		return
	_running = true
	_show(true)
	console.process_mode = Node.PROCESS_MODE_INHERIT  # desligado desde o fim da anterior
	PlayerState.set_on_interface(true)
	_down.clear()
	_max_combo = 0
	_group = load(enemy_group_path).instantiate()
	_enemies = _combatants(_group)
	_party = _combatants(Party)
	field.place(_group, _enemies, _party)
	for e in _enemies:
		enemy_status.add_enemy(e)
	party_status.set_party(_party)
	console.set_context(context())
	await field.slide_in(_party, _enemies, [enemy_status, party_status], pacing.instant)
	_loop()


## O que o console enxerga agora: quem está em campo, quem age e os itens.
## Membro do grupo só é "ativo" enquanto o turno dele aceita comando.
func context() -> BattleContext:
	var c := BattleContext.new()
	c.combatants = _party + _enemies
	var top := stack.peek()
	if top and top.state != TurnFrame.State.KO:
		c.running = top.entity
		if not top.entity.is_party_member() or top.entity == _acting:
			c.active = top.entity
	c.items = Inventory.mochila.itens.filter(func(i): return i.QUANTITY > 0)
	return c


## Executa a ação do membro da vez (botão ou console). Fora do turno dele, não faz nada.
func run_command(cmd: ResolvedCommand, from_console: bool) -> void:
	if _acting == null or cmd == null or not cmd.ok or cmd.actor != _acting:
		return
	if cmd.skill.SKILL_SCRIPT == null:  # habilidade sem script: avisa e o turno não se perde
		fx.play_error(cmd.actor, BattleContext.method_name(cmd.skill) + "() ainda não tem implementação")
		_open_menu()
		return
	_acting = null
	action_menu.close()
	console.set_context(context())  # digitado durante a ação: erro de turno, texto fica
	var mult: float = combo.on_console_action() if from_console else combo.on_button_action()
	var outcomes: Array = cmd.skill.SKILL_SCRIPT.new().resolve(cmd.actor, cmd.targets, mult)
	for t in cmd.targets:
		if t is ITEM:
			Inventory.mochila.gastar(t)
	await _play(cmd.actor, BattleContext.method_name(cmd.skill) + "()", outcomes)
	await _after_action()
	_acted.emit()


# --- fluxo ---------------------------------------------------------------

func _loop() -> void:
	while true:
		if stack.is_empty():
			for c in CallStack.push_order(_party + _enemies):
				stack.push(c)
				await _stack_idle()
		var frame := stack.peek()
		await _take_turn(frame)
		if _living(_enemies).is_empty() or _living(_party).is_empty():
			break  # acabou na hora, mesmo com frames sobrando
		if stack.peek() == frame:
			stack.pop()
			await _stack_idle()
	await _end(_living(_enemies).is_empty())


func _take_turn(frame: TurnFrame) -> void:
	var who = frame.entity
	pacing.latched = false  # um toque solto entre sequências não pula este turno
	turn_started.emit(who)
	if frame.state == TurnFrame.State.KO:
		return  # nocauteado: desempilha sem agir
	_point_at(who)
	if who.is_party_member():
		_acting = who
		_open_menu()
		await _acted
	else:
		console.set_context(context())
		await pacing.wait(0.2)  # o jogador vê de quem é a vez
		var action: EnemyAction = who.choose_action(_party, _living(_enemies))
		if action.error_text != "":
			await fx.play_error(who, action.error_text)
		else:
			await _play(who, action.method_name + "()", action.outcomes)
		await _after_action()
	_point_at(null)


func _open_menu() -> void:
	var typing := console.is_typing()
	console.set_context(context())
	action_menu.open_for(_acting, _acting.get_skills(), _acting.global_position)
	if typing:
		console.open.call_deferred()  # quem estava digitando continua no console


func _on_skill_chosen(skill: SKILL) -> void:
	var actor = _acting
	if actor == null:
		return
	action_menu.close()
	# o seletor e a mochila usam Esc: o console sai de cena enquanto isso
	var console_open := console.visible
	console.close()
	console.process_mode = Node.PROCESS_MODE_DISABLED
	var targets := []
	var cancelled := false
	for kind in BattleContext.param_kinds(skill):
		var pick = await _pick(kind)
		if pick == null:
			cancelled = true
			break
		targets.append(pick)
	console.process_mode = Node.PROCESS_MODE_INHERIT
	console.visible = console_open  # volta à vista sem roubar o foco de quem usou o menu
	if _acting != actor:
		return
	if cancelled:
		_open_menu()
		return
	var cmd := ResolvedCommand.new()
	cmd.ok = true
	cmd.actor = actor
	cmd.skill = skill
	cmd.targets = targets
	await run_command(cmd, false)


func _pick(kind: int):
	if kind == SKILL.Targets.ITE:
		var items := context().items
		if items.is_empty():
			fx.play_error(_acting, "A mochila está vazia")  # o clique não some sem resposta
			return null
		return await item_picker.choose(items)
	var cands := []
	if kind != SKILL.Targets.ENEMY:
		cands += _living(_party)
	if kind != SKILL.Targets.ALLY:
		cands += _living(_enemies)
	var r: Array = await target_selector.choose(cands, _sprite_of)
	return r[0] if not r.is_empty() else null


## Aplica os resultados no status e toca a sequência do golpe.
func _play(actor, method_label: String, outcomes: Array) -> void:
	for o: ActionOutcome in outcomes:
		if o.kind == ActionOutcome.Kind.DAMAGE:
			o.target.apply_damage(o.amount)
		elif o.kind == ActionOutcome.Kind.HEAL:
			o.target.apply_heal(o.amount)
	await fx.play_action(actor, method_label, outcomes, _sprite_of, func(c): return c.get_max_hp())


## Inimigo sem HP sai da pilha e do campo; membro do grupo sem HP fica com o frame em KO.
func _after_action() -> void:
	for c in _party + _enemies:
		if c.is_alive() or c in _down:
			continue
		_down.append(c)
		if c.is_party_member():
			stack.mark_knocked_out(c)
			await fx.play_party_knocked_out(c)
		else:
			stack.remove(c)
			enemy_status.remove_enemy(c)
			await fx.play_enemy_destroyed(c, c.get_nome(), _living(_enemies).is_empty())


func _end(won: bool) -> void:
	_acting = null
	action_menu.close()
	console.close()
	console.process_mode = Node.PROCESS_MODE_DISABLED  # F2 no painel de fim não abre o console
	console.set_context(null)  # os combatentes desta batalha vão ser liberados
	console.text = ""
	_point_at(null)
	await _stack_idle()
	victory_panel.instant = pacing.instant
	defeat_panel.instant = pacing.instant
	if won:
		var lines: Array[String] = []
		for e in _enemies:
			lines.append("%s derrotado" % e.get_nome())
		lines.append("Maior combo: x%d" % _max_combo)
		await victory_panel.show_result(lines)
	else:
		await defeat_panel.show_result("Dica: comandos digitados no console enchem o combo.")
	# a tecla que fechou o painel não pode chegar ao mapa como "interact": o
	# "just pressed" vale por quadro de física, então espera dois deles passarem
	await get_tree().physics_frame
	await get_tree().physics_frame
	pacing.restore()
	combo.reset()
	stack.clear()
	stack_panel.clear()
	enemy_status.clear()
	for n in $FxLayer.get_children():  # números e balões que ainda não sumiram
		n.queue_free()
	_group.queue_free()
	_enemies.clear()
	field.release()
	party_status.set_party([])
	_party.clear()
	PlayerState.set_on_interface(false)
	_show(false)
	_running = false
	# por último: quem ouve (revanche, diálogo) encontra a batalha já limpa
	(battle_won if won else battle_lost).emit()


# --- auxiliares ----------------------------------------------------------

func _show(on: bool) -> void:
	visible = on
	ui.visible = on
	$FxLayer.visible = on
	# escondida, nada da batalha lê teclas (o F2 do console, por exemplo)
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	# o inventário consulta a tecla "e" todo quadro: na batalha ela é do console
	# (chamadas como spend_item continuam funcionando)
	if on:
		_inventory_mode = Inventory.process_mode
		Inventory.process_mode = Node.PROCESS_MODE_DISABLED
	elif _inventory_mode != -1:
		Inventory.process_mode = _inventory_mode


## O console soltou o foco: o teclado/controle volta ao menu do membro da vez.
func _focus_menu() -> void:
	if _acting != null and not action_menu.buttons().is_empty():
		action_menu.buttons()[0].grab_focus()


## ▼ amarelo balançando sobre quem age; o chip do grupo acende.
func _point_at(who) -> void:
	if _marker_tween:
		_marker_tween.kill()
	marker.visible = who != null
	party_status.set_active(who)
	if who == null:
		return
	var p: Vector2 = who.global_position + MARKER_OFFSET
	marker.position = p
	_marker_tween = create_tween().set_loops()
	_marker_tween.tween_property(marker, "position:y", p.y - 8.0, 0.3)
	_marker_tween.tween_property(marker, "position:y", p.y, 0.3)


func _stack_idle() -> void:
	if stack_panel.is_busy():
		await stack_panel.animation_finished


func _refresh_status(target) -> void:
	if target.is_party_member():
		party_status.refresh(target)
	else:
		enemy_status.refresh(target)


# Só combatentes (o grupo pode ter outros nós).
func _combatants(parent: Node) -> Array:
	return parent.get_children().filter(func(n): return n.has_method("is_party_member"))


func _sprite_of(c) -> Node2D:
	return c


func _living(l: Array) -> Array:
	return l.filter(func(c): return c.is_alive())
