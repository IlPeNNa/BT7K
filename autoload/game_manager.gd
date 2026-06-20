extends Node
## GameManager: gestisce lo stato globale del gioco (fasi: Menu, Build, Play, Pause, Event).
## Per ora è uno stub: la state machine vera la implementiamo nel task dedicato.

signal game_state_changed(new_state: String)

var current_state: String = "Menu"

func change_state(new_state: String) -> void:
	current_state = new_state
	game_state_changed.emit(new_state)
