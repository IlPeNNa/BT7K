extends Node
## ResourceManager: tiene traccia delle risorse del giocatore (Legno, Pietra, Cibo, ecc.)
## e notifica la UI via signal quando cambiano, senza che la UI debba "chiedere" direttamente.

signal resources_changed(resource_name: String, new_amount: int)

# Dictionary scelto qui invece di variabili separate: aggiungere una risorsa
# futura (es. Ferro) non richiede modifiche allo script, solo una nuova entry.
var resources: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0,
}

func add_resource(resource_name: String, amount: int) -> void:
	if not resources.has(resource_name):
		push_warning("ResourceManager: risorsa '%s' non esiste." % resource_name)
		return
	resources[resource_name] += amount
	resources_changed.emit(resource_name, resources[resource_name])
