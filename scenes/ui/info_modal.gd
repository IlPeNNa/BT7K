extends Control
## InfoModal: popup centrato con dimming, mostra le informazioni
## dell'edificio selezionato. Il gioco NON è in pausa mentre è aperto,
## quindi il testo "Pronto da raccogliere" si aggiorna in tempo reale
## collegandosi ai segnali dell'edificio, invece di essere scritto una
## sola volta all'apertura.

## Emesso alla chiusura: kingdom_thenorth.gd lo usa per far ricomparire
## la BuildingActionBar (che nel frattempo è stata nascosta, non svuotata).
signal closed

@onready var title_label: Label = $ModalPanel/VBoxContainer/TitleLabel
@onready var info_content_label: Label = $ModalPanel/VBoxContainer/InfoContentLabel
@onready var close_button: Button = $ModalPanel/VBoxContainer/CloseButton
@onready var dim_background: Control = $DimBackground

var _current_building: Sprite2D = null
var _swallow_next_release: bool = false

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close_modal)
	set_process_input(true)


func open_for_building(building: Sprite2D) -> void:
	_disconnect_current_building()
	_current_building = building
	_current_building.production_ready.connect(_refresh_info_text)
	_current_building.resource_collected.connect(_refresh_info_text)
	_refresh_info_text()
	visible = true


func close_modal() -> void:
	visible = false
	_disconnect_current_building()
	closed.emit()


func _refresh_info_text() -> void:
	if _current_building == null:
		return
	var data: BuildingData = _current_building.building_data
	title_label.text = data.display_name
	info_content_label.text = _build_info_text(data, _current_building)


func _disconnect_current_building() -> void:
	if _current_building == null:
		return
	if _current_building.production_ready.is_connected(_refresh_info_text):
		_current_building.production_ready.disconnect(_refresh_info_text)
	if _current_building.resource_collected.is_connected(_refresh_info_text):
		_current_building.resource_collected.disconnect(_refresh_info_text)
	_current_building = null


## _input() ha sempre priorità sopra _unhandled_input(), a prescindere
## dall'ordine dei nodi nell'albero. IMPORTANTE: dobbiamo inghiottire sia
## la pressione CHE il rilascio dello stesso click — la logica di
## selezione edificio in kingdom_thenorth.gd agisce sul RILASCIO, non
## sulla pressione. Marcare solo la pressione come "handled" lasciava
## passare il rilascio, che azzerava di nuovo la Action Bar appena
## riaperta (causa del bug "appare e sparisce subito").
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if visible:
				var modal_panel: Control = $ModalPanel
				if not modal_panel.get_global_rect().has_point(event.position):
					close_modal()
					_swallow_next_release = true
					get_viewport().set_input_as_handled()
		elif _swallow_next_release:
			_swallow_next_release = false
			get_viewport().set_input_as_handled()


## [HACK] concatenazione di stringhe semplice per l'MVP: se il pannello
## Info dovesse crescere con più campi dinamici (livelli, upgrade), meglio
## passare a un layout con più Label separate invece di un unico blocco.
func _build_info_text(data: BuildingData, building: Sprite2D) -> String:
	var lines: Array[String] = []

	if data.produces_resource != "":
		lines.append("Produce: %d %s ogni %.0f secondi" % [
			data.production_amount, data.produces_resource, data.production_interval_seconds
		])
		lines.append("Pronto da raccogliere: %s" % ("Sì" if building.is_ready_to_collect else "No"))
	else:
		lines.append("Questo edificio non produce risorse.")

	if data.population_capacity > 0:
		lines.append("Capacità popolazione: +%d" % data.population_capacity)

	lines.append("Demolibile: %s" % ("Sì" if data.is_removable else "No"))

	var cost_parts: Array[String] = []
	for resource_name in data.cost.keys():
		cost_parts.append("%d %s" % [data.cost[resource_name], resource_name])
	if cost_parts.size() > 0:
		lines.append("Costo: %s" % ", ".join(cost_parts))

	return "\n".join(lines)
