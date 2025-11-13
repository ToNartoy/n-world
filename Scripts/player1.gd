extends CharacterBody2D

@export var speed: float = 60.0 # Zaktualizowana prędkość!
@export var accel: float = 2000.0
@export var deccel: float = 2500.0

@onready var invincibility_timer = $InvincibilityTimer
@onready var anim = $AnimatedSprite2D

var last_direction = Vector2.DOWN
var is_attacking = false
var is_invincible = false
var is_hurting = false

# --- POPRAWIONA ŚCIEŻKA: Referencja do Hitboxu ---
# Skoro Hitbox jest dzieckiem AnimatedSprite2D:
@onready var hitbox = $AnimatedSprite2D/Hitbox 

# --- POPRAWIONA ŚCIEŻKA: Przechowujemy kształt ---
@onready var hitbox_shape = $AnimatedSprite2D/Hitbox/CollisionShape2D


func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("attack") and not is_attacking:
		is_attacking = true
		hitbox_shape.disabled = false
		
		# Sprawdzamy kierunek i OBRACAMY HITBOX
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0:
				anim.play("attack1_right")
				hitbox.rotation_degrees = 0   # Obrót w prawo
			else:
				anim.play("attack1_left")
				hitbox.rotation_degrees = 180 # Obrót w lewo
		else:
			if last_direction.y > 0:
				anim.play("attack1_down")
				hitbox.rotation_degrees = 90  # Obrót w dół
			else:
				anim.play("attack1_up")
				hitbox.rotation_degrees = -90 # Obrót w górę
				
	elif event.is_action_pressed("attack2") and not is_attacking:
		is_attacking = true
		hitbox_shape.disabled = false
		
		# To samo dla ataku 2
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0:
				anim.play("attack2_right")
				hitbox.rotation_degrees = 0
			else:
				anim.play("attack2_left")
				hitbox.rotation_degrees = 180
		else:
			if last_direction.y > 0:
				anim.play("attack2_down")
				hitbox.rotation_degrees = 90
			else:
				anim.play("attack2_up")
				hitbox.rotation_degrees = -90


func _on_animation_finished() -> void:
	var anim_name = anim.animation
	
	if anim_name.begins_with("attack1_") or anim_name.begins_with("attack2_"):
		is_attacking = false
		# Wyłączamy hitbox po ataku
		hitbox_shape.disabled = true 

	# Obsługa animacji 'hurt' i 'death' gracza
	if anim_name.begins_with("hurt_"):
		# Wróć do idle po otrzymaniu obrażeń (uproszczone)
		anim.play("idle_down") 
	
	if anim_name.begins_with("death_"):
		# Po animacji śmierci np. zatrzymaj grę
		get_tree().paused = true
	
	if anim_name.begins_with("hurt_"):
		is_hurting = false
		# Po bólu wracamy do idle, żeby nie zacięło się na ostatniej klatce
		# (Możesz też pozwolić update_animation to zrobić w następnej klatce)


# To jest funkcja, którą podłączyłeś z sygnału 'area_entered' Hitboxu
	# W skrypcie gracz.gd
func _on_Hitbox_area_entered(area):
	# Sprawdzamy, czy 'area', którą trafiliśmy, jest w grupie 'enemy'
	if area.is_in_group("enemy"):
		# 'area.owner' to główny węzeł wroga (enemy1)
		# Przekazujemy teraz DWA argumenty: obrażenia ORAZ kierunek ataku
		area.owner.take_damage(1, last_direction)


# --- Reszta skryptu ---

# Zmienne zdrowia gracza (dodane na dole, by były razem)
var is_dead = false
var health = 10 

func _physics_process(delta: float) -> void:
	
	if is_dead or is_attacking or is_hurting: # Nie ruszaj się, gdy martwy lub atakujesz
		# Tylko hamuj
		velocity = velocity.move_toward(Vector2.ZERO, deccel * delta)
		move_and_slide()
		return # Wyjdź wcześniej, nie przetwarzaj nowego ruchu

	var dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if dir.length() > 0.0:
		dir = dir.normalized()
		velocity = velocity.move_toward(dir * speed, accel * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deccel * delta)

	update_animation()
	move_and_slide()


func update_animation():
	if is_attacking or is_dead or is_hurting: # Nie animuj biegu, gdy martwy/atakujesz
		return

	if velocity.length() > 10.0:
		last_direction = velocity.normalized()
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0: anim.play("run_right")
			else: anim.play("run_left")
		else:
			if velocity.y > 0: anim.play("run_down") 
			else: anim.play("run_up")
	else:
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0: anim.play("idle_right")
			else: anim.play("idle_left")
		else:
			if last_direction.y > 0: anim.play("idle_down")
			else: anim.play("idle_up")


func player_take_damage(damage_amount):
	# Jeśli jesteśmy nietykalni LUB martwi, nie rób nic
	if is_invincible or is_dead:
		return

	health -= damage_amount
	print("AŁA! Dostałem obrażenia! Aktualne HP: ", health) # Nasz dowód w konsoli
	
	# Włączamy nietykalność
	is_invincible = true
	invincibility_timer.start()
	
	# Włączamy stan "bólu" (blokuje ruch)
	is_hurting = true
	
	# --- TO JEST TA CZĘŚĆ, KTÓRĄ USUNĄŁEŚ (Obsługa Śmierci) ---
	if health <= 0:
		is_dead = true
		
		# Wybierz animację śmierci na podstawie kierunku
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0:
				anim.play("death_right")
			else:
				anim.play("death_left")
		else:
			if last_direction.y > 0:
				anim.play("death_down")
			else:
				anim.play("death_up")
	# -----------------------------------------------------------
	else:
		# Gracz żyje -> Odegraj animację bólu (hurt)
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0:
				anim.play("hurt_right")
			else:
				anim.play("hurt_left")
		else:
			if last_direction.y > 0:
				anim.play("hurt_down")
			else:
				anim.play("hurt_up")

func _on_Invincibility_Timer_timeout():
	# Czas nietykalności minął, wyłączamy ją
	is_invincible = false
	# (Opcjonalnie: wyłącz miganie)
	# anim.modulate = Color(1, 1, 1, 1.0)


# Ta funkcja została właśnie utworzona przez sygnał
func _on_PlayerHurtbox_area_entered(area):
	print("!!! [GRACZ]: Czuję cię! Dotknął mnie: ", area.name)
