extends Node2D
## Script della scena "Il Nord": ghost preview + piazzamento sulla griglia
## isometrica di costruzione (128x64), controllo cella occupata, zone calde
## (sostituiscono l'adiacenza al Municipio), demolizione con rimborso
## parziale, salvataggio/caricamento.

const AFFORDABLE_TINT: Color = Color(0.5, 1.0, 0.6, 0.65)
const UNAFFORDABLE_TINT: Color = Color(1.0, 0.5, 0.5, 0.65)
const HEAT_ZONE_TINT: Color = Color(1.0, 0.6, 0.2, 0.25)
const DEMOLISH_REFUND_PERCENTAGE: float = 0.5
const DRAG_THRESHOLD_PIXELS: float = 6.0
const READY_ICON_CLICK_RADIUS: float = 24.0
const CAMERA_CENTER_DURATION: float = 0.25

const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 4.0
const ZOOM_STEP: float = 0.1

const PLACED_BUILDING_SCENE: PackedScene = preload("res://scenes/buildings/placed_building.tscn")
const GREAT_HALL_DATA: BuildingData = preload("res://data/buildings/great_hall.tres")
const GREAT_HALL_START_CELL: Vector2i = Vector2i(4,4)

@onready var building_grid: TileMapLayer = $BuildingGrid
@onready var heat_zone_visual: Node2D = $HeatZoneVisual
@onready var ghost: Node2D = $GhostPreview
@onready var ghost_footprint: Polygon2D = $GhostPreview/Footprint
@onready var ghost_sprite: Sprite2D = $GhostPreview/BuildingSprite
@onready var placed_buildings: Node2D = $PlacedBuildings
@onready var main_hud: Control = $UILayer/MainHud
@onready var building_action_bar: Control = $UILayer/BuildingActionBar
@onready var info_modal: Control = $UILayer/InfoModal

@onready var camera: Camera2D = $Camera2D

@export var selected_building: BuildingData = preload("res://data/buildings/house.tres")
@export var heat_sources: Array[HeatSourceData] = [
	preload("res://data/heat_sources/great_hall_warmth.tres"),
]

var occupied_cells: Dictionary = {}
var _building_registry: Dictionary = {}
var _current_cell: Vector2i = Vector2i.ZERO
var _is_demolish_mode: bool = false
var _warm_cells: Dictionary = {}
var _is_left_button_held: bool = false
var _is_dragging_camera: bool = false
var _drag_press_position: Vector2 = Vector2.ZERO
var _camera_tween: Tween = null

func _ready() -> void:
	var diamond_points := PackedVector2Array([
		Vector2(0, -32), Vector2(64, 0), Vector2(0, 32), Vector2(-64, 0),
	])
	ghost_footprint.polygon = diamond_points
	ghost.visible = false

	_compute_warm_cells()
	_create_heat_zone_visuals(diamond_points)

	_build_registry()

	main_hud.building_selected.connect(_on_building_selected)
	main_hud.demolish_mode_toggled.connect(_on_demolish_mode_toggled)
	main_hud.buildings_menu_closed.connect(_on_buildings_menu_closed)
	main_hud.any_menu_action.connect(building_action_bar.hide_panel)
	building_action_bar.info_requested.connect(_on_info_requested)
	info_modal.closed.connect(building_action_bar.show_again)

	if SaveManager.load_requested:
		SaveManager.load_requested = false
		load_game()
	else:
		_instantiate_building_at_cell(GREAT_HALL_DATA, GREAT_HALL_START_CELL)

	GameManager.change_state(GameManager.GameState.PLAYING)

func _get_all_surrounding_cells(cell: Vector2i) -> Array[Vector2i]:
	# Gli 8 vicini "veri" (lato + angolo) di una cella. I vicini ad angolo non
	# sono dati direttamente da Godot (giustamente: non condividono un lato) —
	# ma sono, per qualunque griglia a 4 connessioni, esattamente le celle
	# vicine di ALMENO 2 dei 4 vicini diretti. Proprietà geometrica universale,
	# non dipende dalla formula di coordinate specifica di questo TileSet.
	var direct: Array[Vector2i] = building_grid.get_surrounding_cells(cell)
	var corner_counts: Dictionary = {}
	for direct_neighbor in direct:
		for candidate in building_grid.get_surrounding_cells(direct_neighbor):
			if candidate == cell or direct.has(candidate):
				continue
			corner_counts[candidate] = corner_counts.get(candidate, 0) + 1

	var all_neighbors: Array[Vector2i] = direct.duplicate()
	for candidate in corner_counts:
		if corner_counts[candidate] >= 2:
			all_neighbors.append(candidate)
	return all_neighbors

func _compute_warm_cells() -> void:
	# Espansione "a passi veri" con get_surrounding_cells(): lasciamo a Godot
	# il compito di conoscere la vera disposizione delle celle vicine per
	# questo TileSet (Stacked + Horizontal Offset) — niente più formule scritte
	# a mano, che si sono rivelate sbagliate per questa configurazione.
	_warm_cells.clear()
	for source in heat_sources:
		if not source.is_unlocked:
			continue
		var frontier: Array[Vector2i] = [source.center_cell]
		_warm_cells[source.center_cell] = true
		for step in range(source.radius):
			var next_frontier: Array[Vector2i] = []
			for cell in frontier:
				for neighbor in _get_all_surrounding_cells(cell):
					if not _warm_cells.has(neighbor):
						_warm_cells[neighbor] = true
						next_frontier.append(neighbor)
			frontier = next_frontier

func _create_heat_zone_visuals(diamond_points: PackedVector2Array) -> void:
	for cell in _warm_cells:
		var tile := Polygon2D.new()
		tile.polygon = diamond_points
		tile.color = HEAT_ZONE_TINT
		tile.position = building_grid.map_to_local(cell)
		heat_zone_visual.add_child(tile)

func _build_registry() -> void:
	var all_buildings: Array[BuildingData] = [
		preload("res://data/buildings/house.tres"),
		preload("res://data/buildings/sawmill.tres"),
		preload("res://data/buildings/mine.tres"),
		preload("res://data/buildings/farm.tres"),
		preload("res://data/buildings/walls.tres"),
		GREAT_HALL_DATA,
	]
	for data in all_buildings:
		if data.building_id == "":
			push_warning("BuildingData senza building_id trovato (%s) — il salvataggio non potrà ricostruirlo." % data.resource_path)
			continue
		_building_registry[data.building_id] = data

func _on_building_selected(building: BuildingData) -> void:
	selected_building = building
	ghost.visible = true

func _on_demolish_mode_toggled(active: bool) -> void:
	_is_demolish_mode = active
	ghost.visible = false

## Chiamata alla chiusura del menu Edifici: annulla qualunque selezione di
## piazzamento in corso, altrimenti il ghost resterebbe visibile e
## trascinabile anche a menu chiuso.
func _on_buildings_menu_closed() -> void:
	ghost.visible = false


func _on_info_requested(building: Sprite2D) -> void:
	building_action_bar.hide_temporarily()
	info_modal.open_for_building(building)


func _process(_delta: float) -> void:
	if not ghost.visible:
		return

	var mouse_local: Vector2 = building_grid.get_local_mouse_position()
	_current_cell = building_grid.local_to_map(mouse_local)
	ghost.position = building_grid.map_to_local(_current_cell)

	var cell_free: bool = not occupied_cells.has(_current_cell)
	var affordable: bool = ResourceManager.can_afford(selected_building.cost)
	var warm: bool = _warm_cells.has(_current_cell)

	var tint: Color = AFFORDABLE_TINT if (cell_free and affordable and warm) else UNAFFORDABLE_TINT
	ghost_footprint.color = tint
	ghost_sprite.modulate = tint


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(-ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_left_button_held = true
				_is_dragging_camera = false
				_drag_press_position = event.position
			else:
				_is_left_button_held = false
				if not _is_dragging_camera:
					if _is_demolish_mode:
						_try_demolish_building()
					elif ghost.visible:
						_try_place_building()
					else:
						if not _try_collect_from_icon(event.position):
							_try_select_building()
				_is_dragging_camera = false
	elif event is InputEventMouseMotion and _is_left_button_held:
		if not _is_dragging_camera:
			if event.position.distance_to(_drag_press_position) > DRAG_THRESHOLD_PIXELS:
				_is_dragging_camera = true
		if _is_dragging_camera:
			camera.position -= event.relative * camera.zoom
	elif event is InputEventKey and event.pressed:
		building_action_bar.hide_panel()


	elif event is InputEventMouseMotion and _is_left_button_held:
		if not _is_dragging_camera:
			if event.position.distance_to(_drag_press_position) > DRAG_THRESHOLD_PIXELS:
				_is_dragging_camera = true
		if _is_dragging_camera:
			# Moltiplichiamo per camera.zoom: con lo zoom attivo, lo stesso
			# movimento del mouse in pixel deve corrispondere a una quantità
			# diversa di spazio di gioco (più zoomati = meno spazio percorso
			# a parità di pixel trascinati).
			camera.position -= event.relative * camera.zoom
	elif event is InputEventKey and event.pressed:
		# Qualunque tasto premuto chiude la barra azione: copre anche
		# l'apertura del Pause Menu con ESC, che prima restava scoperta.
		building_action_bar.hide_panel()


func _zoom_camera(delta_zoom: float) -> void:
	var new_zoom: float = clamp(camera.zoom.x + delta_zoom, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(new_zoom, new_zoom)

## Anima la camera verso la posizione dell'edificio selezionato, così
## diventa il centro della visuale. Usiamo un Tween invece di uno scatto
## istantaneo per coerenza con lo stile "morbido" già usato altrove
## (BuildingsPanel, BuildingActionBar). Il tween viene sempre "killato"
## prima di ripartire per evitare accumuli se si selezionano più edifici
## in rapida sequenza — stesso pattern già validato sugli altri pannelli.
func _center_camera_on(target_position: Vector2) -> void:
	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.tween_property(camera, "position", target_position, CAMERA_CENTER_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


func _try_place_building() -> void:
	if not ghost.visible:
		return
	if occupied_cells.has(_current_cell):
		return
	if not _warm_cells.has(_current_cell):
		return
	if not ResourceManager.spend(selected_building.cost):
		return
	_instantiate_building_at_cell(selected_building, _current_cell)


func _try_demolish_building() -> void:
	var mouse_local: Vector2 = building_grid.get_local_mouse_position()
	var cell: Vector2i = building_grid.local_to_map(mouse_local)

	if not occupied_cells.has(cell):
		return

	var building: Sprite2D = occupied_cells[cell]
	if not building.building_data.is_removable:
		NotificationManager.notify("Questo edificio non può essere demolito.", NotificationManager.NotificationType.WARNING)
		return

	for resource_name in building.building_data.cost:
		var refund: int = int(floor(building.building_data.cost[resource_name] * DEMOLISH_REFUND_PERCENTAGE))
		if refund > 0:
			ResourceManager.add_resource(resource_name, refund)

	building.queue_free()
	occupied_cells.erase(cell)
	NotificationManager.notify("Edificio demolito.", NotificationManager.NotificationType.INFO)


## Selezione di un edificio già piazzato (non in modalità costruzione/demolizione):
## avvia l'animazione "bounce" stile Clash of Clans e il suono associato.
## L'apertura del popup Info/Raccogli è compito del Blocco 3, non di questa funzione.
func _try_select_building() -> void:
	var mouse_local: Vector2 = building_grid.get_local_mouse_position()
	var cell: Vector2i = building_grid.local_to_map(mouse_local)

	if not occupied_cells.has(cell):
		building_action_bar.hide_panel()
		return

	var building: Sprite2D = occupied_cells[cell]
	building.on_selected()
	building_action_bar.show_for_building(building)
	_center_camera_on(building.global_position)


## Controlla se il click è avvenuto sull'icona "pronto" fluttuante di un
## edificio, cliccabile ovunque sulla mappa (non solo sulla sua cella).
## Restituisce true se ha gestito il click (raccolto la risorsa), così
## _unhandled_input sa di non dover proseguire con la selezione normale.
func _try_collect_from_icon(click_position: Vector2) -> bool:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	for cell in occupied_cells:
		var building: Sprite2D = occupied_cells[cell]
		if not building.is_ready_to_collect:
			continue
		var icon_screen_pos: Vector2 = canvas_transform * building.get_ready_icon_global_position()
		if icon_screen_pos.distance_to(click_position) <= READY_ICON_CLICK_RADIUS:
			building.collect_resource()
			return true
	return false


func _instantiate_building_at_cell(data: BuildingData, cell: Vector2i) -> void:
	var placed_building: Sprite2D = PLACED_BUILDING_SCENE.instantiate()
	placed_building.position = building_grid.map_to_local(cell)
	placed_buildings.add_child(placed_building)
	placed_building.setup(data)
	occupied_cells[cell] = placed_building

func save_game() -> void:
	var buildings_data: Array = []
	for cell in occupied_cells:
		var building: Sprite2D = occupied_cells[cell]
		buildings_data.append({
			"building_id": building.building_data.building_id,
			"cell_x": cell.x,
			"cell_y": cell.y,
		})

	var save_data: Dictionary = {
		"resources": ResourceManager.resources,
		"buildings": buildings_data,
	}

	if SaveManager.write_save(save_data):
		NotificationManager.notify("Partita salvata.", NotificationManager.NotificationType.SUCCESS)
	else:
		NotificationManager.notify("Errore durante il salvataggio.", NotificationManager.NotificationType.ERROR)

func load_game() -> void:
	var save_data: Dictionary = SaveManager.read_save()
	if save_data.is_empty():
		NotificationManager.notify("Nessun salvataggio trovato.", NotificationManager.NotificationType.WARNING)
		return

	_clear_world()
	ResourceManager.reset_resources(save_data.get("resources", {}))

	for entry in save_data.get("buildings", []):
		var building_id: String = entry.get("building_id", "")
		if not _building_registry.has(building_id):
			push_warning("Caricamento: building_id '%s' non trovato nel registro, salto." % building_id)
			continue
		var cell: Vector2i = Vector2i(entry.get("cell_x", 0), entry.get("cell_y", 0))
		_instantiate_building_at_cell(_building_registry[building_id], cell)

	NotificationManager.notify("Partita caricata.", NotificationManager.NotificationType.SUCCESS)

func _clear_world() -> void:
	for cell in occupied_cells.keys():
		occupied_cells[cell].queue_free()
	occupied_cells.clear()
	ResourceManager.reset_population()
