extends Node
## ResourceManager: tiene traccia delle risorse del giocatore (Legno, Pietra, Cibo, ecc.)
## e della popolazione, notificando la UI via signal quando cambiano, senza che
## la UI debba "chiedere" direttamente.

signal resources_changed(resource_name: String, new_amount: int)
signal population_changed(current: int, max: int)

# Dictionary scelto qui invece di variabili separate: aggiungere una risorsa
# futura (es. Ferro) non richiede modifiche allo script, solo una nuova entry.
# Valori iniziali di TEST per poter provare subito il piazzamento — andranno
# bilanciati seriamente più avanti (probabilmente si parte da meno risorse
# con una fase iniziale di raccolta).
var resources: Dictionary = {
	"wood": 100,
	"stone": 50,
	"food": 20,
}

# Popolazione: parte da 0. Senza nessuna Casa piazzata non c'è capacità.
var population_current: int = 0
var population_max: int = 0

func add_resource(resource_name: String, amount: int) -> void:
	if not resources.has(resource_name):
		push_warning("ResourceManager: risorsa '%s' non esiste." % resource_name)
		return
	resources[resource_name] += amount
	resources_changed.emit(resource_name, resources[resource_name])

func can_afford(cost: Dictionary) -> bool:
	# Controlla se le risorse attuali bastano, senza modificare nulla.
	# Serve per il feedback visivo del ghost (verde/rosso).
	for resource_name in cost:
		if resources.get(resource_name, 0) < cost[resource_name]:
			return false
	return true

func spend(cost: Dictionary) -> bool:
	# Operazione atomica: o può pagare TUTTO il costo, o non scala nulla.
	if not can_afford(cost):
		return false
	for resource_name in cost:
		resources[resource_name] -= cost[resource_name]
		resources_changed.emit(resource_name, resources[resource_name])
	return true

func add_population_capacity(amount: int) -> void:
	# MVP: la capacità aggiunta si traduce subito in abitanti effettivi -
	# nessuna crescita graduale per ora (vedi commento in BuildingData).
	# TODO futuro: se introduciamo consumo di cibo o eventi di carestia,
	# population_current dovrà poter scendere sotto population_max.
	if amount <= 0:
		return
	population_max += amount
	population_current = population_max
	population_changed.emit(population_current, population_max)

func remove_population_capacity(amount: int) -> void:
	# Simmetrico ad add_population_capacity, ma robusto anche se in futuro
	# population_current diverge da population_max (eventi, carestie, ecc.):
	# abbassiamo solo il tetto, e "espelliamo" l'eccedenza se necessario.
	# Non tocchiamo mai population_current se è già sotto il nuovo max.
	if amount <= 0:
		return
	population_max = max(0, population_max - amount)
	population_current = min(population_current, population_max)
	population_changed.emit(population_current, population_max)

func reset_resources(new_resources: Dictionary) -> void:
	# Usato dal caricamento: sostituisce le risorse attuali con quelle salvate
	# ed emette il segnale per ogni risorsa, così la TopBar si aggiorna subito.
	resources = new_resources.duplicate()
	for resources_name in resources:
		resources_changed.emit(resources_name, resources[resources_name])

func reset_population() -> void:
	# Usato dal caricamento, PRIMA di ricreare gli edifici: azzera la
	# popolazione così add_population_capacity() può ricostruirla da zero
	# senza somme errate sopra a valori di una partita precedente.
	population_current = 0
	population_max = 0
	population_changed.emit(population_current, population_max)
