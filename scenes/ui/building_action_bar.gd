extends Control
## BuildingActionBar: barra fissa in basso al centro con nome edificio e
## pulsanti azione (Info, Raccogli). Appare con uno slide-in dal basso
## quando si seleziona un edificio piazzato, e scompare con uno slide-out
## verso il basso quando l'attenzione del giocatore va altrove (click su
## terreno vuoto, apertura di un altro menu, pressione di un tasto).

@onready var building_name_label: Label = $Panel/VBoxContainer/BuildingNameLabel
@onready var info_button: Button = $Panel/VBoxContainer/HBoxContainer/InfoButton
@onready var collect_button: Button = $Panel/VBoxContainer/HBoxContainer/CollectButton

signal info_requested(building: Sprite2D)

const ANIM_DURATION := 0.1
## Deve essere >= altezza del box: se troppo piccolo, la barra "spunta"
## da dentro lo schermo invece che entrare da fuori. Regola se cambi Size.
const HIDDEN_OFFSET_Y := 150.0

var _current_building: Sprite2D = null
var _base_position_y: float = 0.0
var _tween: Tween = null

func _ready() -> void:
	visible = false
	info_button.pressed.connect(_on_info_pressed)
	collect_button.pressed.connect(_on_collect_pressed)

	# Catturata UNA SOLA VOLTA: leggerla dentro l'animazione causerebbe lo
	# stesso bug di accumulo già risolto su BuildingsPanel (offset che
	# cresce ad ogni apertura se letto a metà di un tween precedente).
	_base_position_y = position.y


func show_for_building(building: Sprite2D) -> void:
	if _current_building != null and _current_building.production_ready.is_connected(_refresh_collect_visibility):
		_current_building.production_ready.disconnect(_refresh_collect_visibility)
	if _current_building != null and _current_building.resource_collected.is_connected(_refresh_collect_visibility):
		_current_building.resource_collected.disconnect(_refresh_collect_visibility)

	_current_building = building
	building_name_label.text = building.building_data.display_name
	_current_building.production_ready.connect(_refresh_collect_visibility)
	_current_building.resource_collected.connect(_refresh_collect_visibility)
	_refresh_collect_visibility()

	if not visible:
		_animate_in()
	# Se era già visibile (click diretto da un edificio a un altro), il testo
	# è già aggiornato sopra: niente animazione, la barra resta ferma.


func hide_panel() -> void:
	if not visible:
		return  # evita di accodare un'animazione su un pannello già nascosto

	if _current_building != null:
		if _current_building.production_ready.is_connected(_refresh_collect_visibility):
			_current_building.production_ready.disconnect(_refresh_collect_visibility)
		if _current_building.resource_collected.is_connected(_refresh_collect_visibility):
			_current_building.resource_collected.disconnect(_refresh_collect_visibility)
	_current_building = null

	_animate_out()


## Nasconde temporaneamente la barra (es. quando si apre InfoModal) SENZA
## perdere il riferimento all'edificio selezionato — a differenza di
## hide_panel(), qui basta chiamare show_again() per farla ricomparire
## con gli stessi dati, senza dover recliccare l'edificio.
func hide_temporarily() -> void:
	if not visible:
		return
	_animate_out()


func show_again() -> void:
	if _current_building == null:
		return
	_animate_in()


func _animate_in() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	visible = true
	position.y = _base_position_y + HIDDEN_OFFSET_Y
	modulate.a = 0.0

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position:y", _base_position_y, ANIM_DURATION).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, ANIM_DURATION)


func _animate_out() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position:y", _base_position_y + HIDDEN_OFFSET_Y, ANIM_DURATION).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, ANIM_DURATION)
	_tween.finished.connect(func(): visible = false, CONNECT_ONE_SHOT)


func _refresh_collect_visibility() -> void:
	collect_button.visible = _current_building != null and _current_building.is_ready_to_collect


func _on_info_pressed() -> void:
	info_requested.emit(_current_building)


func _on_collect_pressed() -> void:
	_current_building.collect_resource()
	_refresh_collect_visibility()
