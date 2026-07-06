extends Control
## MainHud: contenitore permanente del menu in basso a sinistra.
## Gestisce apertura/chiusura pannelli e popolamento dinamico del
## Menu Edifici (categorie: Abitazioni/Produzione/Difesa).

## Emesso alla selezione di un edificio da costruire.
## si collega qui kingdom_thenorth.gd
signal building_selected(building: BuildingData)

## Emesso quando l'utente attiva/disattiva la modalità demolizione.
signal demolish_mode_toggled(active: bool)

## Emesso quando il menu Edifici si chiude: serve a kingdom_thenorth.gd
## per nascondere il ghost preview, che altrimenti resta visibile anche
## dopo la chiusura del pannello (nessun'altra parte del codice lo spegneva).
signal buildings_menu_closed

## Emesso alla pressione di QUALUNQUE tab della barra in basso, a
## prescindere da quale. Serve a kingdom_thenorth.gd per chiudere la
## BuildingActionBar quando l'attenzione del giocatore va altrove.
signal any_menu_action

@onready var buildings_tab: Button = $BottomBar/TabRow/BuildingsTab
@onready var map_tab: Button = $BottomBar/TabRow/MapTab
@onready var research_tab: Button = $BottomBar/TabRow/ResearchTab
@onready var inventory_tab: Button = $BottomBar/TabRow/InventoryTab

@onready var buildings_panel: Control = $BuildingsPanel
@onready var housing_cat_btn: Button = $BuildingsPanel/CategoryTabs/HousingCatBtn
@onready var production_cat_btn: Button = $BuildingsPanel/CategoryTabs/ProductionCatBtn
@onready var defense_cat_btn: Button = $BuildingsPanel/CategoryTabs/DefenseCatBtn
@onready var buildings_grid: GridContainer = $BuildingsPanel/BuildingsGrid
@onready var demolish_bar: Control = $DemolishBar
@onready var demolish_button: Button = $DemolishBar/DemolishButton

const BUILDINGS_DATA_PATH := "res://data/buildings/"

# Cache di tutte le BuildingData caricate, per non rileggere il disco
# ogni volta che si cambia categoria.
var _all_buildings: Array[BuildingData] = []
var _current_category: BuildingData.Category = BuildingData.Category.HOUSING

var _active_panel: Control = null

# Tween attivo per l'animazione del pannello: lo teniamo tracciato per
# poterlo interrompere se l'utente clicca più volte di fretta, altrimenti
# più tween in parallelo si contendono position.y e la posizione "deriva".
var _panel_tween: Tween = null

# Posizione base (di riposo) del pannello, catturata UNA SOLA VOLTA in
# _ready(), prima che qualunque animazione la sposti. Leggere
# panel.position.y a runtime dentro l'animazione era la root cause del
# bug: se letta a metà di un tween precedente, non è più il valore
# originale e l'offset si accumula ad ogni click.
var _buildings_panel_base_y: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	buildings_panel.visible = false
	demolish_bar.visible = false
	demolish_button.toggled.connect(_on_demolish_toggled)
	_buildings_panel_base_y = buildings_panel.position.y

	buildings_tab.pressed.connect(func():
		any_menu_action.emit()
		_toggle_buildings_menu()
	)
	map_tab.pressed.connect(func():
		any_menu_action.emit()
		_toggle_panel(null)
	)
	research_tab.pressed.connect(func():
		any_menu_action.emit()
		_toggle_panel(null)
	)
	inventory_tab.pressed.connect(func():
		any_menu_action.emit()
		_toggle_panel(null)
	)

	housing_cat_btn.pressed.connect(func(): _select_category(BuildingData.Category.HOUSING))
	production_cat_btn.pressed.connect(func(): _select_category(BuildingData.Category.PRODUCTION))
	defense_cat_btn.pressed.connect(func(): _select_category(BuildingData.Category.DEFENSE))

	_load_all_buildings()
	_select_category(BuildingData.Category.HOUSING)
	
	# Fissiamo l'anchor via codice invece di fidarci del preset impostato
	# a mano nell'editor: è la root cause del bug "pannello fuori schermo
	# in alto" — l'anchor Bottom Left non si era applicato correttamente
	# e offset_top veniva letto dal bordo TOP invece che dal bordo BOTTOM.
	buildings_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE)
	buildings_panel.offset_bottom = -BUILDINGS_PANEL_BOTTOM_MARGIN
	buildings_panel.offset_top = buildings_panel.offset_bottom - BUILDINGS_PANEL_HEIGHT
	await get_tree().process_frame
	_buildings_panel_base_y = buildings_panel.position.y

const PANEL_ANIM_DURATION := 0.2
const PANEL_HIDDEN_OFFSET_Y := 260.0  # deve combaciare con l'altezza del pannello
const BUILDINGS_PANEL_HEIGHT := 220.0
const BUILDINGS_PANEL_BOTTOM_MARGIN := 90.0  # spazio sopra la BottomBar, regola a occhio


func _toggle_panel(panel: Control) -> void:
	if _active_panel != null and _active_panel == panel:
		_animate_panel_out(_active_panel)
		if _active_panel == buildings_panel:
			buildings_menu_closed.emit()
		_active_panel = null
		return
	if _active_panel != null:
		_animate_panel_out(_active_panel)
		if _active_panel == buildings_panel:
			buildings_menu_closed.emit()
	_active_panel = panel
	if _active_panel != null:
		_animate_panel_in(_active_panel)


## Apre/chiude BuildingsPanel e DemolishBar insieme: sono la stessa
## "sessione" logica (il menu costruzioni), quindi condividono visibilità.
func _toggle_buildings_menu() -> void:
	var opening := _active_panel != buildings_panel
	_toggle_panel(buildings_panel)
	demolish_bar.visible = opening
	if not opening:
		demolish_button.button_pressed = false


func _on_demolish_toggled(active: bool) -> void:
	demolish_mode_toggled.emit(active)

func _animate_panel_in(panel: Control) -> void:
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()  # evita tween sovrapposti sulla stessa proprietà

	panel.visible = true
	panel.modulate.a = 0.0
	panel.position.y = _buildings_panel_base_y + PANEL_HIDDEN_OFFSET_Y

	_panel_tween = create_tween()
	_panel_tween.set_parallel(true)
	_panel_tween.tween_property(panel, "position:y", _buildings_panel_base_y, PANEL_ANIM_DURATION).set_ease(Tween.EASE_OUT)
	_panel_tween.tween_property(panel, "modulate:a", 1.0, PANEL_ANIM_DURATION)


func _animate_panel_out(panel: Control) -> void:
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()

	_panel_tween = create_tween()
	_panel_tween.set_parallel(true)
	_panel_tween.tween_property(panel, "position:y", _buildings_panel_base_y + PANEL_HIDDEN_OFFSET_Y, PANEL_ANIM_DURATION).set_ease(Tween.EASE_IN)
	_panel_tween.tween_property(panel, "modulate:a", 0.0, PANEL_ANIM_DURATION)
	_panel_tween.finished.connect(func(): panel.visible = false, CONNECT_ONE_SHOT)


## Scansiona data/buildings/ e carica tutte le BuildingData.
## [HACK] DirAccess a runtime: ok con 7 file, ma se gli edifici crescono
## molto conviene un registro esplicito (Array di path in un Resource)
## per evitare I/O ripetuto ad ogni _ready().
func _load_all_buildings() -> void:
	_all_buildings.clear()
	var dir := DirAccess.open(BUILDINGS_DATA_PATH)
	if dir == null:
		push_warning("MainHud: impossibile aprire %s" % BUILDINGS_DATA_PATH)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(BUILDINGS_DATA_PATH + file_name) as BuildingData
			if res != null:
				_all_buildings.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()


func _select_category(category: BuildingData.Category) -> void:
	_current_category = category
	_refresh_buildings_grid()


## Ricrea i bottoni ad ogni cambio categoria invece di nasconderli: con
## 5-7 edifici il costo è trascurabile e si evita di tracciare "quali
## bottoni esistono già".
func _refresh_buildings_grid() -> void:
	for child in buildings_grid.get_children():
		child.queue_free()

	for data in _all_buildings:
		if data.category != _current_category:
			continue
		var btn := Button.new()
		btn.text = "%s\n%s" % [data.display_name, _format_cost(data.cost)]
		btn.custom_minimum_size = Vector2(120, 60)
		btn.pressed.connect(func(): _on_building_selected(data))
		buildings_grid.add_child(btn)


func _format_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for resource_name in cost.keys():
		parts.append("%d %s" % [cost[resource_name], resource_name])
	return ", ".join(parts)


func _on_building_selected(data: BuildingData) -> void:
	demolish_button.button_pressed = false  # mutua esclusione: costruire disattiva demolire
	building_selected.emit(data)
