extends Control
## Dialog di conferma prima di spendere risorse per costruire, mostrato
## solo se SettingsManager.is_confirm_resource_spending_enabled().
## Stesso pattern di chiusura-su-click-esterno di InfoModal/PauseMenu.

signal confirmed
signal cancelled

@onready var dim_background: ColorRect = $DimBackground
@onready var modal_panel: PanelContainer = $ModalPanel
@onready var building_name_label: Label = $ModalPanel/Margin/Content/BuildingNameLabel
@onready var cost_list: VBoxContainer = $ModalPanel/Margin/Content/CostList
@onready var confirm_button: Button = $ModalPanel/Margin/Content/ButtonsRow/ConfirmButton
@onready var cancel_button: Button = $ModalPanel/Margin/Content/ButtonsRow/CancelButton

var _swallow_next_release: bool = false


func _ready() -> void:
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)


func open_for(data: BuildingData) -> void:
	building_name_label.text = data.display_name
	_populate_costs(data.cost)
	visible = true


func _populate_costs(cost: Dictionary) -> void:
	for child in cost_list.get_children():
		child.queue_free()
	for resource_name in cost.keys():
		var label := Label.new()
		label.text = "%d %s" % [cost[resource_name], resource_name]
		cost_list.add_child(label)


func _on_confirm_pressed() -> void:
	visible = false
	confirmed.emit()


func _on_cancel_pressed() -> void:
	visible = false
	cancelled.emit()


## Priorità sopra _unhandled_input: intercetta il click fuori da ModalPanel
## per trattarlo come Annulla, e "inghiotte" anche il rilascio successivo
## (altrimenti kingdom_thenorth.gd riceverebbe quello stesso click come
## un normale click sulla mappa, es. deselezionando o piazzando).
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not modal_panel.get_global_rect().has_point(event.global_position):
				_swallow_next_release = true
				_on_cancel_pressed()
				get_viewport().set_input_as_handled()
		elif _swallow_next_release:
			_swallow_next_release = false
			get_viewport().set_input_as_handled()
