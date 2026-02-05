extends Node

# Questa variabile controlla quanti secondi attendere prima del respawn.
@export var respawn_delay: float = 1.0

# Questo nodo è il punto di spawn del Player 1.
@onready var player1_spawn: Marker2D = get_parent().get_node("SpawnPointP1")
# Questo nodo è il punto di spawn del Player 2.
@onready var player2_spawn: Marker2D = get_parent().get_node("SpawnPointP2")
# Questo nodo è l'istanza del Player 1 in scena.
@onready var player1: CharacterBody2D = get_parent().get_node("Player1")
# Questo nodo è l'istanza del Player 2 in scena.
@onready var player2: CharacterBody2D = get_parent().get_node("Player2")

# Questa funzione viene chiamata quando il GameManager entra in scena.
func _ready() -> void:
	# Garantiamo che l'Input Map contenga tutte le azioni richieste dal gioco.
	_setup_input_map()
	# Posizioniamo subito i due player nei loro spawn iniziali con vita piena.
	player1.respawn_at(player1_spawn.global_position)
	player2.respawn_at(player2_spawn.global_position)

# Questa funzione crea le azioni input se non sono ancora presenti.
func _setup_input_map() -> void:
	# Registriamo i controlli del Player 1 (A, D, W, F).
	_ensure_action_with_key(&"p1_left", KEY_A)
	_ensure_action_with_key(&"p1_right", KEY_D)
	_ensure_action_with_key(&"p1_jump", KEY_W)
	_ensure_action_with_key(&"p1_attack", KEY_F)
	# Registriamo i controlli del Player 2 (frecce, L).
	_ensure_action_with_key(&"p2_left", KEY_LEFT)
	_ensure_action_with_key(&"p2_right", KEY_RIGHT)
	_ensure_action_with_key(&"p2_jump", KEY_UP)
	_ensure_action_with_key(&"p2_attack", KEY_L)

# Questa funzione assicura che una singola azione esista e abbia il tasto corretto.
func _ensure_action_with_key(action_name: StringName, keycode: Key) -> void:
	# Se l'azione non esiste la creiamo.
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	# Controlliamo se l'azione ha già il keycode richiesto.
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			return
	# Se il tasto richiesto non c'è, lo aggiungiamo all'azione.
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = keycode
	InputMap.action_add_event(action_name, key_event)

# Questa funzione riceve la richiesta di respawn da un player eliminato.
func request_respawn(player: Node) -> void:
	# Aspettiamo qualche istante per rendere chiara l'eliminazione.
	await get_tree().create_timer(respawn_delay).timeout
	# Se il nodo non è più valido, usciamo senza errori.
	if not is_instance_valid(player):
		return
	# Se il player è il primo, respawniamo nel suo punto dedicato.
	if player == player1:
		player1.respawn_at(player1_spawn.global_position)
	# Se il player è il secondo, respawniamo nel suo punto dedicato.
	elif player == player2:
		player2.respawn_at(player2_spawn.global_position)
