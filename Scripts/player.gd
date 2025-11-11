extends CharacterBody2D

# Prędkość ruchu w pikselach/sek.
@export var speed: float = 220.0
# Delikatne wygładzanie ruszania/hamowania:
@export var accel: float = 2000.0
@export var deccel: float = 2500.0

func _physics_process(delta: float) -> void:
	# Odczyt WSAD (Input Map)
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if dir.length() > 0.0:
		dir = dir.normalized()
		# Przyspieszanie do docelowej prędkości
		velocity = velocity.move_toward(dir * speed, accel * delta)
	else:
		# Hamowanie, gdy nie wciskasz klawiszy
		velocity = velocity.move_toward(Vector2.ZERO, deccel * delta)

	# Porusz i obsłuż kolizje
	move_and_slide()
