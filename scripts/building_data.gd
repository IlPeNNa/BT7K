extends Resource
class_name BuildingData
## Dati di un edificio: nome, costo in risorse, e produzione nel tempo.
## Separato dalla logica di piazzamento/produzione per non hardcodare i
## valori negli script (regola architetturale del progetto).

@export var building_id: String = ""
@export var display_name: String = ""

## Categoria per il raggruppamento nel Menu Edifici (MainHud, tab "Edifici").
## UNCATEGORIZED = non compare nel menu (es. Sala Grande: pre-piazzata,
## non costruibile manualmente dal giocatore).
enum Category {UNCATEGORIZED, HOUSING, PRODUCTION, DEFENSE}
@export var category: Category = Category.UNCATEGORIZED

@export var cost: Dictionary[String, int] = {}  # es. {"wood": 20, "stone": 5}

# Popolazione: capacità che questo edificio aggiunge al regno se costruito.
# Vale 0 per tutti tranne Casa (impostato via Inspector su house.tres).
# MVP: appena l'edificio è piazzato, la capacità si "riempie" subito —
# niente crescita graduale né consumo di cibo per abitante, per ora.
@export var population_capacity: int = 0

# Produzione: se produces_resource è vuoto, l'edificio non produce nulla
# (es. Casa, Mura per ora — la popolazione la gestiremo separatamente).
@export var produces_resource: String = ""
@export var production_amount: int = 0
@export var production_interval_seconds: float = 0.0

# Se false, l'edificio non può essere demolito (es. Municipio). Il sistema
# di demolizione non esiste ancora — preparato in anticipo per non dover
# rivedere BuildingData quando arriverà.
@export var is_removable: bool = true
