extends CharacterBody2D

# Prędkość ruchu w pikselach/sek.
@export var speed: float = 60.0
# Delikatne wygładzanie ruszania/hamowania:
@export var accel: float = 2000.0
@export var deccel: float = 2500.0

# Referencja do węzła animacji (zmień nazwę, jeśli jest inna!)
@onready var anim = $AnimatedSprite2D

# Zmienna przechowująca ostatni kierunek, w którym patrzyła postać
var last_direction = Vector2.DOWN

# --- NOWA ZMIENNA STANU ATAKU ---
# Blokuje inne animacje, gdy trwa atak
var is_attacking = false
# ----------------------------------


# --- NOWA FUNKCJA _READY ---
# Ta funkcja odpala się raz, na starcie gry
func _ready() -> void:
	# Łączymy sygnał "koniec animacji" z naszą nową funkcją.
	# To jest kluczowe, by wiedzieć, kiedy atak się skończył.
	# (Zakładam, że Twoje animacje ataku NIE są zapętlone!)
	anim.animation_finished.connect(_on_animation_finished)
# -----------------------------


# --- NOWA FUNKCJA _INPUT ---
# Ta funkcja przechwytuje zdarzenia (jak kliknięcia)
func _input(event: InputEvent) -> void:
	# Sprawdź, czy wcisnęliśmy akcję "attack" (lewy klik)
	# ORAZ czy NIE jesteśmy już w trakcie ataku (zapobiega spamowi)
	if event.is_action_pressed("attack") and not is_attacking:
		
		# Ustawiamy flagę, że atakujemy
		is_attacking = true
		
		# Wybierz animację ataku na podstawie OSTATNIEGO KIERUNKU
		# (Dokładnie ta sama logika co w 'idle')
		if abs(last_direction.x) > abs(last_direction.y):
			# Atak w lewo/prawo
			if last_direction.x > 0:
				anim.play("attack1_right")
			else:
				anim.play("attack1_left")
		else:
			# Atak w górę/dół
			if last_direction.y > 0:
				anim.play("attack1_down")
			else:
				anim.play("attack1_up")
# -----------------------------


# --- NOWA FUNKCJA SYGNAŁU ---
# Ta funkcja zostanie automatycznie wywołana przez sygnał
# 'animation_finished' z węzła AnimatedSprite2D
func _on_animation_finished() -> void:
	# Pobieramy nazwę animacji, która się właśnie skończyła
	var anim_name = anim.animation
	
	# Jeśli to była animacja ataku, resetujemy naszą flagę.
	# Używamy 'begins_with', aby złapać "attack1_left", "attack1_right" itd.
	if anim_name.begins_with("attack1_"):
		is_attacking = false
# -----------------------------


func _physics_process(delta: float) -> void:
	# --- MODYFIKACJA LOGIKI RUCHU ---
	# Jeśli atakujemy, nie pozwól graczowi wybrać nowego kierunku
	# Ale pozwól mu się ślizgać/hamować (jak w Twoim kodzie)
	var dir = Vector2.ZERO
	
	# Pozwól graczowi wybrać kierunek tylko jeśli NIE atakuje
	if not is_attacking:
		dir = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		)

	# --- LOGIKA RUCHU (Twoja oryginalna) ---
	if dir.length() > 0.0:
		dir = dir.normalized()
		velocity = velocity.move_toward(dir * speed, accel * delta)
	else:
		# Hamowanie (działa też podczas ataku, super!)
		velocity = velocity.move_toward(Vector2.ZERO, deccel * delta)

	# --- AKTUALIZACJA ANIMACJI ---
	# Ta funkcja teraz wie, że ma ignorować bieg/stanie
	# jeśli 'is_attacking' jest aktywne
	update_animation()
	
	move_and_slide()


# --- ZMODYFIKOWANA FUNKCJA ANIMACJI ---
func update_animation():
	# --- KLUCZOWA ZMIANA! ---
	# Jeśli atakujemy, NIE RÓB NIC. Pozwól animacji ataku grać do końca.
	if is_attacking:
		return
	# --------------------------

	# Reszta kodu jest identyczna jak poprzednio
	if velocity.length() > 10.0:
		# Gracz się porusza.
		last_direction = velocity.normalized()
		
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0:
				anim.play("run_right")
			else:
				anim.play("run_left")
		else:
			if velocity.y > 0:
				anim.play("run_down") 
			else:
				anim.play("run_up")
	else:
		# Gracz stoi w miejscu.
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0:
				anim.play("idle_right")
			else:
				anim.play("idle_left")
		else:
			if last_direction.y > 0:
				anim.play("idle_down")
			else:
				anim.play("idle_up")
