extends PanelContainer
## Popup informativo su hover di una card edificio nel Menu Edifici.
## Mostra popolazione, produzione e costi (colorati in base a
## ResourceManager.can_afford). NON mostra ancora rarità/dimensioni:
## dati non esistenti nel modello attuale, aggiunti quando progettati.

@onready var name_label: Label = $Margin/Content/NameLabel
@onready var population_row: HBoxContainer = $Margin/Content/PopulationRow
@onready var population_value: Label = $Margin/Content/PopulationRow/PopulationValue
@onready var products_header: Label = $Margin/Content/ProductsHeader
@onready var production_row: HBoxContainer = $Margin/Content/ProductionRow
@onready var production_label: Label = $Margin/Content/ProductionRow/ProductionLabel
@onready var production_interval: Label = $Margin/Content/ProductionRow/ProductionInterval
@onready var costs_header: Label = $Margin/Content/CostsHeader
@onready var costs_list: VBoxContainer = $Margin/Content/CostsList

const COLOR_AFFORDABLE := Color(0.4, 0.9, 0.4)
const COLOR_NOT_AFFORDABLE := Color(0.9, 0.3, 0.3)


func populate(data: BuildingData) -> void:
	name_label.text = data.display_name

	# Popolazione: riga visibile solo se l'edificio la fornisce davvero.
	population_row.visible = data.population_capacity > 0
	if population_row.visible:
		population_value.text = "+%d" % data.population_capacity

	# Produzione: sezione visibile solo per edifici produttivi.
	var has_production := data.produces_resource != "" and data.production_amount > 0
	products_header.visible = has_production
	production_row.visible = has_production
	if has_production:
		production_label.text = "%d %s" % [data.production_amount, data.produces_resource]
		production_interval.text = "ogni %ds" % data.production_interval_seconds

	_populate_costs(data.cost)


func _populate_costs(cost: Dictionary) -> void:
	for child in costs_list.get_children():
		child.queue_free()

	for resource_name in cost.keys():
		var amount: int = cost[resource_name]
		var label := Label.new()
		label.text = "%d %s" % [amount, resource_name]
		label.modulate = COLOR_AFFORDABLE if _can_afford_single(resource_name, amount) else COLOR_NOT_AFFORDABLE
		costs_list.add_child(label)


## Controllo per singola risorsa: ResourceManager.can_afford() valuta
## l'intero costo insieme, qui serve sapere QUALE risorsa manca per
## colorarla individualmente. Legge direttamente il Dictionary pubblico
## resources, coerente con come ResourceManager espone i dati.
func _can_afford_single(resource_name: String, amount: int) -> bool:
	return ResourceManager.resources.get(resource_name, 0) >= amount
