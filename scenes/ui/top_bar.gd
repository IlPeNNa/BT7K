extends Control
## TopBar: mostra le risorse correnti del giocatore (Legno, Pietra, Cibo)
## e la popolazione (corrente/massima). Si aggiorna tramite i signal
## resources_changed e population_changed di ResourceManager — non
## controlliamo ogni frame, la UI reagisce solo quando qualcosa cambia
## davvero (loose coupling).

@onready var wood_label: Label = $HBoxContainer/WoodLabel
@onready var stone_label: Label = $HBoxContainer/StoneLabel
@onready var food_label: Label = $HBoxContainer/FoodLabel
@onready var pop_label: Label = $HBoxContainer/PopLabel

# Mappa nome risorsa -> Label corrispondente, per aggiornare quello giusto
# senza una lunga catena di if/elif.
var _resource_labels: Dictionary = {}

func _ready() -> void:
	_resource_labels = {
		"wood": wood_label,
		"stone": stone_label,
		"food": food_label,
	}
	ResourceManager.resources_changed.connect(_on_resources_changed)
	ResourceManager.population_changed.connect(_on_population_changed)

	# Il signal scatta solo sui CAMBIAMENTI futuri: i Label vanno
	# inizializzati subito con i valori attuali, altrimenti partirebbero vuoti.
	for resource_name in _resource_labels:
		_update_label(resource_name, ResourceManager.resources[resource_name])
	_update_population_label(ResourceManager.population_current, ResourceManager.population_max)

func _on_resources_changed(resource_name: String, new_amount: int) -> void:
	_update_label(resource_name, new_amount)

func _on_population_changed(current: int, max_pop: int) -> void:
	_update_population_label(current, max_pop)
	
func _update_label(resource_name: String, amount: int) -> void:
	if not _resource_labels.has(resource_name):
		return
	var display_names: Dictionary = {"wood": "Legno", "stone": "Pietra", "food": "Cibo"}
	_resource_labels[resource_name].text = "%s: %d" % [display_names.get(resource_name, resource_name), amount]

func _update_population_label(current: int, max_pop: int) -> void:
	pop_label.text = "Pop: %d/%d" % [current, max_pop]
