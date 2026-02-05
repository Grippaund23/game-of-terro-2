extends CharacterBody2D

# Questa variabile indica la velocità orizzontale del personaggio.
@export var move_speed: float = 220.0
# Questa variabile indica la forza del salto.
@export var jump_velocity: float = -420.0
# Questa variabile indica i punti vita massimi del personaggio.
@export var max_health: int = 100
# Questa variabile indica quanti danni infligge un singolo attacco.
@export var attack_damage: int = 20
# Questa variabile indica la durata in secondi della finestra di hitbox attiva.
@export var attack_duration: float = 0.12
# Questa variabile indica il tempo minimo tra due attacchi consecutivi.
@export var attack_cooldown: float = 0.35
# Questa stringa contiene il nome dell'azione Input Map per muoversi a sinistra.
@export var left_action: StringName = &"p1_left"
# Questa stringa contiene il nome dell'azione Input Map per muoversi a destra.
@export var right_action: StringName = &"p1_right"
# Questa stringa contiene il nome dell'azione Input Map per saltare.
@export var jump_action: StringName = &"p1_jump"
# Questa stringa contiene il nome dell'azione Input Map per attaccare.
@export var attack_action: StringName = &"p1_attack"

# Questo nodo Sprite2D serve per visualizzare il personaggio.
@onready var sprite: Sprite2D = $Sprite2D
# Questo nodo CollisionShape2D rappresenta il corpo fisico del personaggio.
@onready var body_collision: CollisionShape2D = $CollisionShape2D
# Questo nodo Area2D rappresenta la hitbox dell'attacco.
@onready var attack_area: Area2D = $AttackArea2D
# Questo nodo CollisionShape2D è la forma fisica della hitbox.
@onready var attack_collision: CollisionShape2D = $AttackArea2D/CollisionShape2D

# Questa variabile contiene i punti vita correnti.
var current_health: int
# Questa variabile dice se il personaggio è vivo o no.
var is_alive: bool = true
# Questa variabile conta il tempo rimanente prima del prossimo attacco disponibile.
var cooldown_left: float = 0.0
# Questa variabile conta il tempo rimanente della hitbox attiva.
var attack_time_left: float = 0.0
# Questa variabile evita colpi multipli sullo stesso bersaglio durante un singolo attacco.
var has_hit_this_attack: bool = false
# Questa variabile salva la direzione in cui guarda il personaggio (1 destra, -1 sinistra).
var facing_direction: int = 1

# Questa funzione viene chiamata quando il nodo entra in scena.
func _ready() -> void:
	# Impostiamo la vita corrente al valore massimo all'avvio.
	current_health = max_health
	# Mettiamo il personaggio nel gruppo "players" per riconoscerlo facilmente.
	add_to_group("players")
	# Disattiviamo la hitbox di attacco all'inizio.
	attack_area.monitoring = false
	# Colleghiamo il segnale di collisione della hitbox alla funzione di gestione colpo.
	attack_area.body_entered.connect(_on_attack_area_body_entered)

# Questa funzione viene chiamata ad ogni frame fisico.
func _physics_process(delta: float) -> void:
	# Se il personaggio non è vivo, blocchiamo movimento e attacchi.
	if not is_alive:
		# Usiamo comunque la fisica per far fermare il corpo in modo pulito.
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Se non è a terra, applichiamo la gravità verticale.
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta

	# Calcoliamo input orizzontale: destra vale +1, sinistra vale -1.
	var horizontal_input: float = Input.get_action_strength(right_action) - Input.get_action_strength(left_action)
	# Applichiamo la velocità orizzontale usando il valore configurabile.
	velocity.x = horizontal_input * move_speed

	# Se si preme salto e siamo a terra, applichiamo la velocità di salto.
	if Input.is_action_just_pressed(jump_action) and is_on_floor():
		velocity.y = jump_velocity

	# Se c'è input orizzontale, aggiorniamo la direzione in cui guarda il personaggio.
	if horizontal_input > 0.0:
		facing_direction = 1
	elif horizontal_input < 0.0:
		facing_direction = -1

	# Aggiorniamo il flip dello sprite in base alla direzione.
	sprite.flip_h = facing_direction < 0
	# Spostiamo la hitbox davanti al personaggio in base alla direzione.
	attack_area.position.x = abs(attack_area.position.x) * facing_direction

	# Gestiamo il timer di cooldown dell'attacco.
	if cooldown_left > 0.0:
		cooldown_left -= delta

	# Se si preme il tasto attacco e il cooldown è finito, iniziamo l'attacco.
	if Input.is_action_just_pressed(attack_action) and cooldown_left <= 0.0:
		_start_attack()

	# Se l'attacco è attivo, riduciamo il timer e spegniamo la hitbox quando scade.
	if attack_time_left > 0.0:
		attack_time_left -= delta
		if attack_time_left <= 0.0:
			attack_area.monitoring = false

	# Applichiamo movimento e collisioni del CharacterBody2D.
	move_and_slide()

# Questa funzione avvia la logica di un nuovo attacco.
func _start_attack() -> void:
	# Attiviamo la hitbox per rilevare il bersaglio.
	attack_area.monitoring = true
	# Impostiamo la durata della finestra di colpo.
	attack_time_left = attack_duration
	# Impostiamo il cooldown prima del prossimo attacco.
	cooldown_left = attack_cooldown
	# Resettiamo il blocco colpo singolo.
	has_hit_this_attack = false

# Questa funzione viene chiamata quando la hitbox tocca un corpo.
func _on_attack_area_body_entered(body: Node) -> void:
	# Se il personaggio è morto, non può colpire nessuno.
	if not is_alive:
		return
	# Se abbiamo già colpito in questo attacco, ignoriamo altri contatti.
	if has_hit_this_attack:
		return
	# Ignoriamo noi stessi per evitare auto-colpi.
	if body == self:
		return
	# Verifichiamo che il bersaglio abbia il metodo take_damage.
	if body.has_method("take_damage"):
		# Applichiamo danno al bersaglio.
		body.take_damage(attack_damage)
		# Segniamo che in questo swing abbiamo già fatto danno.
		has_hit_this_attack = true

# Questa funzione riduce la vita quando il personaggio riceve un colpo.
func take_damage(amount: int) -> void:
	# Se è già morto, non serve processare altro danno.
	if not is_alive:
		return
	# Sottraiamo il danno dalla vita corrente.
	current_health -= amount
	# Se la vita è arrivata a zero o meno, gestiamo la morte.
	if current_health <= 0:
		die()

# Questa funzione gestisce la morte del personaggio.
func die() -> void:
	# Impostiamo lo stato morto.
	is_alive = false
	# Rendiamo il personaggio invisibile mentre è eliminato.
	visible = false
	# Disattiviamo la collisione del corpo per non bloccare la mappa.
	body_collision.disabled = true
	# Disattiviamo la hitbox di attacco durante la morte.
	attack_area.monitoring = false
	# Azzeriamo la velocità per fermare subito il personaggio.
	velocity = Vector2.ZERO
	# Cerchiamo il GameManager nel parent e chiediamo il respawn.
	var game_manager: Node = get_parent().get_node_or_null("GameManager")
	if game_manager != null and game_manager.has_method("request_respawn"):
		game_manager.request_respawn(self)

# Questa funzione ripristina il personaggio a vita piena in uno spawn.
func respawn_at(spawn_position: Vector2) -> void:
	# Ripristiniamo la posizione del personaggio.
	global_position = spawn_position
	# Ripristiniamo vita piena.
	current_health = max_health
	# Riattiviamo lo stato vivo.
	is_alive = true
	# Rendiamo il personaggio visibile di nuovo.
	visible = true
	# Riattiviamo la collisione del corpo.
	body_collision.disabled = false
	# Spegniamo la hitbox per sicurezza al respawn.
	attack_area.monitoring = false
	# Azzeriamo i timer interni dell'attacco.
	attack_time_left = 0.0
	cooldown_left = 0.0
	# Azzeriamo la velocità per evitare movimenti residui.
	velocity = Vector2.ZERO
