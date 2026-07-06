extends Control
## MainMenu: schermata iniziale. Nuova Partita / Carica Partita (disabilitato
## se non esiste un salvataggio) / Esci. Imposta il flag di SaveManager prima
## di cambiare scena — kingdom_thenorth.gd lo legge al proprio _ready().

const KINGDOM_THENORTH_SCENE: String = "res://scenes/world/kingdom_thenorth.tscn"

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var load_game_button: Button = $VBoxContainer/LoadGameButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton

func _ready() -> void:
	load_game_button.disabled = not SaveManager.has_save()

	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_button.pressed.connect(func(): SettingsManager.open_settings(self))

func _on_new_game_pressed() -> void:
	SaveManager.load_requested = false
	get_tree().change_scene_to_file(KINGDOM_THENORTH_SCENE)

func _on_load_game_pressed() -> void:
	SaveManager.load_requested = true
	get_tree().change_scene_to_file(KINGDOM_THENORTH_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
