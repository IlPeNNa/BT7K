extends Node
## SettingsManager: volume audio (bus Master/Music/SFX) e overlay di
## luminosità simulata, applicati globalmente. Registrato come SCENA
## autoload (non solo script) perché, a differenza degli altri manager, ha
## bisogno di nodi UI propri visibili sopra qualunque scena attiva.

const SETTINGS_PATH: String = "user://settings.json"

@onready var brightness_overlay: ColorRect = $CanvasLayer/BrightnessOverlay
@onready var settings_panel: Control = $CanvasLayer/SettingsPanel
@onready var master_slider: HSlider = $CanvasLayer/SettingsPanel/DimBackground/Panel/Margin/VBoxContainer/MasterRow/MasterSlider
@onready var music_slider: HSlider = $CanvasLayer/SettingsPanel/DimBackground/Panel/Margin/VBoxContainer/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $CanvasLayer/SettingsPanel/DimBackground/Panel/Margin/VBoxContainer/SFXRow/SFXSlider
@onready var brightness_slider: HSlider = $CanvasLayer/SettingsPanel/DimBackground/Panel/Margin/VBoxContainer/BrightnessRow/BrightnessSlider
@onready var camera_focus_toggle: CheckButton = $CanvasLayer/SettingsPanel/DimBackground/Panel/Margin/VBoxContainer/CameraFocusRow/CameraFocusToggle
@onready var confirm_spend_toggle: CheckButton = $CanvasLayer/SettingsPanel/DimBackground/Panel/Margin/VBoxContainer/ConfirmSpendRow/ConfirmSpendToggle
@onready var close_button: Button = $CanvasLayer/SettingsPanel/DimBackground/Panel/Margin/VBoxContainer/CloseButton
var _caller_to_restore: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	settings_panel.visible = false

	# Carica prima di connettere i segnali — così impostare .value durante
	# il caricamento NON scatena ancora _save_settings(), evitando che i
	# valori salvati vengano subito riscritti con i default.
	var loaded: bool = _load_settings()

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	camera_focus_toggle.toggled.connect(_on_camera_focus_toggled)
	confirm_spend_toggle.toggled.connect(_on_confirm_spend_toggled)
	close_button.pressed.connect(close_settings)

	if not loaded:
		# Prima avvio: nessun file salvato, inizializza con i valori di default
		# e forza manualmente gli effetti collaterali (bus audio, overlay).
		master_slider.value = 1.0
		music_slider.value = 1.0
		sfx_slider.value = 1.0
		brightness_slider.value = 1.0
		_on_brightness_changed(1.0)
		camera_focus_toggle.button_pressed = false  # default OFF: nessuno zoom finché l'utente non lo attiva
		confirm_spend_toggle.button_pressed = false  # default OFF: nessuna conferma richiesta
	else:
		# File caricato: i valori sono già negli slider, forza solo gli effetti
		# collaterali che i segnali avrebbero scatenato (ma non l'hanno fatto
		# perché i segnali non erano ancora connessi durante _load_settings()).
		_on_master_changed(master_slider.value)
		_on_music_changed(music_slider.value)
		_on_sfx_changed(sfx_slider.value)
		_on_brightness_changed(brightness_slider.value)
	
func open_settings(caller: Control = null) -> void:
	# Nasconde temporaneamente chi ha aperto le Impostazioni (Main Menu o
	# Pause Menu) — evita che i due pannelli semi-trasparenti si sovrappongano
	# visivamente. Ripristinato alla chiusura.
	_caller_to_restore = caller
	if _caller_to_restore:
		_caller_to_restore.visible = false
	settings_panel.visible = true

func close_settings() -> void:
	settings_panel.visible = false
	if _caller_to_restore:
		_caller_to_restore.visible = true
		_caller_to_restore = null

## Letto da kingdom_thenorth.gd prima di animare la camera sulla selezione.
func is_camera_focus_enabled() -> bool:
	return camera_focus_toggle.button_pressed

## Letto dal codice di piazzamento prima di scalare le risorse.
func is_confirm_resource_spending_enabled() -> bool:
	return confirm_spend_toggle.button_pressed

func _linear_from_bus(bus_name: String) -> float:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))

func _on_master_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	_save_settings()

func _on_music_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	_save_settings()

func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
	_save_settings()

func _on_brightness_changed(value: float) -> void:
	# "Luminosità": valore alto = schermo normale, valore basso = più scuro.
	# L'overlay (velo nero) si comporta al contrario (più alpha = più scuro),
	# quindi invertiamo qui: alpha = 1.0 - value.
	brightness_overlay.color = Color(0, 0, 0, 1.0 - value)
	_save_settings()

func _on_camera_focus_toggled(_value: bool) -> void:
	_save_settings()

func _on_confirm_spend_toggled(_value: bool) -> void:
	_save_settings()


func _save_settings() -> void:
	var data: Dictionary = {
		"master": master_slider.value,
		"music": music_slider.value,
		"sfx": sfx_slider.value,
		"brightness": brightness_slider.value,
		"camera_focus_enabled": camera_focus_toggle.button_pressed,
		"confirm_resource_spending": confirm_spend_toggle.button_pressed,
	}
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_settings() -> bool:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return false # prima avvio: resta sui valori di default degli slider
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	
	# Impostare il .value degli slider scatena automaticamente i segnali
	# value_changed → _on_*_changed → applica il volume/luminosità reale.
	# Niente chiamate manuali ai bus audio: lasciamo fare al flusso già esistente.
	master_slider.value = parsed.get("master", 1.0)
	music_slider.value = parsed.get("music", 1.0)
	sfx_slider.value = parsed.get("sfx", 1.0)
	brightness_slider.value = parsed.get("brightness", 1.0)
	camera_focus_toggle.button_pressed = parsed.get("camera_focus_enabled", false)
	confirm_spend_toggle.button_pressed = parsed.get("confirm_resource_spending", false)
	
	return true
