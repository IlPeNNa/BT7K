extends Node
## SaveManager: wrapper generico per leggere/scrivere dati di gioco su JSON
## in user://. Non conosce la forma dei dati (risorse, edifici, ecc.) — quella
## responsabilità appartiene a chi chiama (es. kingdom_thenorth.gd), così
## SaveManager resta riutilizzabile anche se la struttura del salvataggio cambia.

const SAVE_PATH: String = "user://savegame.json"

# Flag letto e consumato da kingdom_thenorth.gd nel proprio _ready(): indica
# se la scena deve caricare una partita esistente invece di partire "vuota".
# Vive qui (autoload, sopravvive al cambio scena) perché MainMenu e
# kingdom_thenorth sono scene diverse e non si passano dati direttamente.
var load_requested: bool = false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func write_save(data: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: impossibile aprire %s in scrittura (errore %s)" % [SAVE_PATH, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func read_save() -> Dictionary:
	if not has_save():
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: impossibile aprire %s in lettura (errore %s)" % [SAVE_PATH, FileAccess.get_open_error()])
		return {}
	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: il file di salvataggio non contiene un JSON valido.")
		return {}
	return parsed
