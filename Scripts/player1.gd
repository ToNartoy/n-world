extends CharacterBody2D

# Prędkość ruchu w pikselach/sek.
@export var speed: float = 60.0
# Delikatne wygładzanie ruszania/hamowaaania:
@export var accel: float = 2000.0
@export var deccel: float = 2500.0

# --- NOWE ZMIENNE DLA ANIMACJI ---
# Referencja do węzła animacji (zmień nazwę, jeśli jest inna!)
@onready var anim = $AnimatedSprite2D

# Zmienna przechowująca ostatni kierunek, w którym patrzyła postać
# Domyślnie patrzymy w dół (Vector2.DOWN to skrót na Vector2(0, 1))
var last_direction = Vector2.DOWN
# ----------------------------------


func _physics_process(delta: float) -> void:
	# Odczyt WSAD (Input Map)
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	# --- LOGIKA RUCHU (Twoja oryginalna, jest świetna) ---
	if dir.length() > 0.0:
		dir = dir.normalized()
		# Przyspieszanie do docelowej prędkości
		velocity = velocity.move_toward(dir * speed, accel * delta)
	else:
		# Hamowanie, gdy nie wciskasz klawiszy
		velocity = velocity.move_toward(Vector2.ZERO, deccel * delta)

	# --- NOWA LOGIKA ANIMACJI ---
	update_animation()
	# -----------------------------

	# Porusz i obsłuż kolizje
	move_and_slide()


# --- NOWA FUNKCJA DO ZARZĄDZANIA ANIMACJAMI ---
func update_animation():
	# Sprawdzamy, czy postać FAKTYCZNIE się porusza (prędkość jest większa od 0)
	# Używamy małej wartości (np. 10), aby uniknąć "drgania" animacji przy hamowaniu
	if velocity.length() > 10.0:
		# Gracz się porusza.
		# Zapisujemy jego kierunek, żeby wiedzieć, jak ma stanąć 'idle'
		last_direction = velocity.normalized()
		
		# Sprawdzamy, która oś (X czy Y) ma większą wartość,
		# aby zdecydować, czy grać animację góra/dół czy lewo/prawo.
		if abs(velocity.x) > abs(velocity.y):
			# Ruch horyzontalny (lewo/prawo) jest silniejszy
			if velocity.x > 0:
				anim.play("run_right")
			else:
				anim.play("run_left")
		else:
			# Ruch wertykalny (góra/dół) jest silniejszy (lub równy)
			if velocity.y > 0:
				anim.play("run_down") # Twoja prośba dla klawisza 'S'
			else:
				anim.play("run_up")
	else:
		# Gracz stoi w miejscu (velocity jest bliskie zera).
		# Odtwarzamy animację 'idle' na podstawie OSTATNIEGO kierunku,
		# w którym się poruszał.
		
		if abs(last_direction.x) > abs(last_direction.y):
			# Ostatni ruch był bardziej horyzontalny
			if last_direction.x > 0:
				anim.play("idle_right")
			else:
				anim.play("idle_left")
		else:
			# Ostatni ruch był bardziej wertykalny
			if last_direction.y > 0:
				anim.play("idle_down") # Twoja prośba dla 'stania po S'
			else:
				anim.play("idle_up")
