extends CharacterBody2D

@onready var anim = $AnimatedSprite2D

var health = 3
var is_dead = false

# Musimy przechowywać ostatni kierunek IDLE, gdy wróg się NIE rusza
# To się przyda, gdy wróg sam zacznie się poruszać.
var idle_direction_suffix = "_down" # Domyślnie patrzy w dół


func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("idle" + idle_direction_suffix)


# TĘ FUNKCJĘ WYWOŁA ATAK GRACZA - Z AKTUALIZACJĄ!
func take_damage(damage_amount, attack_direction):
	
	
	if is_dead:
		return # Nie da się zabić trupa

	health -= damage_amount
	
	# --- NAJWAŻNIEJSZA ZMIANA! ---
	# Chcemy, żeby wróg patrzył NA GRACZA,
	# więc odwracamy wektor kierunku ataku.
	# (np. atak "up" (0, -1) staje się "down" (0, 1))
	var look_at_direction = -attack_direction
	# --------------------------------
	

	# --- NOWA LOGIKA KIERUNKOWA ---
	# Teraz używamy 'look_at_direction' zamiast 'attack_direction'
	var anim_suffix = ""
	if abs(look_at_direction.x) > abs(look_at_direction.y):
		if look_at_direction.x > 0:
			anim_suffix = "_right"
		else:
			anim_suffix = "_left"
	else:
		if look_at_direction.y > 0:
			anim_suffix = "_down"
		else:
			anim_suffix = "_up"
	
	# Zapisujemy, w którą stronę wróg teraz patrzy
	idle_direction_suffix = anim_suffix
	# -------------------------------

	
	if health <= 0:
		is_dead = true
		# Zakładając, że masz CharacterBody2D, to jest dobra praktyka:
		if "set_physics_process" in self:
			set_physics_process(false) 
		
		# Odegraj animację śmierci z poprawnym kierunkiem!
		anim.play("death" + anim_suffix) 
	else:
		# Odegraj animację bólu z poprawnym kierunkiem!
		anim.play("hurt" + anim_suffix)


# Funkcja czyszcząca po animacjach
func _on_animation_finished():
	var anim_name = anim.animation
	
	# Jeśli skończyła się animacja 'hurt' (z dowolnym kierunkiem)
	if anim_name.begins_with("hurt_"):
		# Wróć do stanu 'idle' w kierunku, w którym otrzymał obrażenia
		anim.play("idle" + idle_direction_suffix) 
		
	# Jeśli skończyła się animacja 'death'
	if anim_name.begins_with("death_"):
		# Usuń wroga ze sceny
		queue_free()

# TODO: W _physics_process wroga musisz dodać logikę ruchu
# i aktualizować 'idle_direction_suffix' na podstawie jego WŁASNEGO ruchu,
# tak jak to robimy w skrypcie gracza.


func _on_TouchDamage_area_entered(area):
	print("--- DIAGNOSTYKA KOLIZJI ---")
	print("1. Wykryłem obiekt o nazwie: ", area.name)
	
	# Sprawdźmy grupę
	var czy_w_grupie = area.is_in_group("player")
	print("2. Czy ten obiekt jest w grupie 'player'? ", czy_w_grupie)
	
	if czy_w_grupie:
		print("3. Grupa OK! Próbuję pobrać właściciela (Gracza)...")
		var cel = area.owner
		# Jeśli owner to null, spróbujmy rodzica (częsty błąd w Godot)
		if cel == null:
			cel = area.get_parent()
			print("   (Uwaga: area.owner był pusty, używam get_parent())")
			
		print("4. Znalazłem cel: ", cel.name)
		
		if cel.has_method("player_take_damage"):
			print("5. Cel ma funkcję 'player_take_damage'. WYWOŁUJĘ JĄ!")
			cel.player_take_damage(1)
		else:
			print("BŁĄD KRYTYCZNY: Cel ", cel.name, " NIE MA funkcji player_take_damage!")
	else:
		print("BŁĄD LOGICZNY: Obiekt ", area.name, " NIE JEST w grupie 'player'. Sprawdź pisownię w węźle!")
	print("---------------------------")
