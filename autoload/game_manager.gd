extends Node
## GameManager: gestisce lo stato globale del gioco.
## Stati: MENU (schermata iniziale), PLAYING (dentro un regno, il tempo scorre sempre),
## PAUSED (overlay ESC/salvataggio, blocca produzione e input di gioco).
## NB: eventi/milestone e la vittoria di un regno NON sono stati di questa FSM,
## sono notifiche gestite altrove via segnale (decisione presa nella sessione corrente,
## vedi design log).

signal game_state_changed(new_state: GameState)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
}

var current_state: GameState = GameState.MENU


func change_state(new_state: GameState) -> void:
	# Nessuna transizione "verso se stesso": evita di re-emettere il segnale
	# e di rieseguire gli effetti collaterali senza motivo.
	if new_state == current_state:
		return

	# Unica regola di validazione per ora: PAUSED si raggiunge solo da PLAYING,
	# e da PAUSED si torna solo a PLAYING. Tutto il resto è permesso.
	if new_state == GameState.PAUSED and current_state != GameState.PLAYING:
		push_warning("GameManager: transizione non valida verso PAUSED da %s" % GameState.keys()[current_state])
		return
	if current_state == GameState.PAUSED and new_state != GameState.PLAYING:
		push_warning("GameManager: da PAUSED si può tornare solo a PLAYING")
		return

	current_state = new_state
	_apply_state_side_effects(new_state)
	game_state_changed.emit(new_state)


func _apply_state_side_effects(state: GameState) -> void:
	# Effetto collaterale minimo: PAUSED ferma l'intero SceneTree, quindi anche
	# i Timer di produzione degli edifici si fermano automaticamente.
	# ATTENZIONE per il futuro: qualsiasi nodo che debba restare attivo durante
	# la pausa (es. il menu ESC stesso, altrimenti non riceverebbe più input)
	# dovrà avere process_mode = Node.PROCESS_MODE_ALWAYS impostato su quel nodo
	# specifico. Non serve adesso perché il menu ESC non esiste ancora.
	get_tree().paused = (state == GameState.PAUSED)

func is_playing() -> bool:
	return current_state == GameState.PLAYING
