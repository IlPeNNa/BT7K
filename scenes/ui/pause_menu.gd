extends Control
## PauseMenu: overlay di pausa richiamato con ESC. Deve restare attivo
## DURANTE la pausa stessa (process_mode = Always). Bottone "Carica Partita"
## rimosso: in conflitto concettuale con la futura lista salvataggi del
## Main Menu.

@onready var resume_button: Button = $MenuPanel/VBoxContainer/ResumeButton
@onready var save_button: Button = $MenuPanel/VBoxContainer/SaveButton
@onready var main_menu_button: Button = $MenuPanel/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $MenuPanel/VBoxContainer/QuitButton
@onready var settings_button: Button = $MenuPanel/VBoxContainer/SettingsButton
@onready var menu_panel: Control = $MenuPanel

@onready var kingdom: Node = get_tree().current_scene

var _swallow_next_release: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_button.pressed.connect(func(): SettingsManager.open_settings(self))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if GameManager.current_state == GameManager.GameState.PLAYING:
			_open()
		elif GameManager.current_state == GameManager.GameState.PAUSED:
			_close()

func _open() -> void:
	visible = true
	GameManager.change_state(GameManager.GameState.PAUSED)

func _close() -> void:
	visible = false
	GameManager.change_state(GameManager.GameState.PLAYING)

func _on_resume_pressed() -> void:
	_close()

func _on_save_pressed() -> void:
	kingdom.save_game()


func _on_main_menu_pressed() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	GameManager.change_state(GameManager.GameState.MENU)
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func _on_quit_pressed() -> void:
	# Salva automaticamente prima di chiudere: nessun progresso perso
	# chiudendo distrattamente dal menu di pausa.
	kingdom.save_game()
	get_tree().quit()


## Stessa tecnica e stessa root cause di InfoModal: bisogna inghiottire
## anche il rilascio del click, non solo la pressione, altrimenti
## kingdom_thenorth.gd riceve comunque il rilascio e reagisce come se
## fosse un click sulla mappa.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if visible and not menu_panel.get_global_rect().has_point(event.position):
				_close()
				_swallow_next_release = true
				get_viewport().set_input_as_handled()
		elif _swallow_next_release:
			_swallow_next_release = false
			get_viewport().set_input_as_handled()
