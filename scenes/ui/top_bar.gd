extends Control
## TopBar: barra superiore con identità del Regno, popolazione, Kingdom
## Points (stella), valute/supplies/goods (pannelli espandibili) e accesso
## rapido a Guida/Impostazioni. Skeleton: la maggior parte dei pulsanti
## sono placeholder in attesa dei sistemi dati corrispondenti (valute,
## supplies, goods, kingdom points) — non ancora progettati.

@onready var kingdom_name_label: Label = $HBoxContainer/KingdomNameLabel
@onready var kingdom_interface_label: Label = $HBoxContainer/KingdomInterfaceLabel
@onready var pop_label: Label = $HBoxContainer/PopulationLabel
@onready var currency_button: Button = $HBoxContainer/CurrencyButton
@onready var supplies_button: Button = $HBoxContainer/SuppliesButton
@onready var goods_button: Button = $HBoxContainer/GoodsButton
@onready var help_button: Button = $HBoxContainer/HelpButton
@onready var settings_button: Button = $HBoxContainer/SettingsButton
@onready var kingdom_points_star: Control = $KingdomPointsStar

# Placeholder in attesa del sistema di zone/regni: per ora un solo Regno
# esiste (Il Nord), quindi il nome è fisso qui invece di essere passato
# da fuori. Quando ci saranno più zone, questo diventa un @export o un
# parametro impostato da kingdom_thenorth.gd (o chi per esso) all'avvio.
const KINGDOM_NAME_PLACEHOLDER: String = "Il Nord"

# Placeholder: nessuna selezione zone reale esiste ancora, il Nord ha
# un'unica interfaccia implementata (kingdom_thenorth.tscn). Quando ci
# saranno più zone, set_interface_name() verrà chiamato da fuori.
const KINGDOM_INTERFACE_PLACEHOLDER: String = "Grande Inverno"

const KINGDOM_POINTS_STAR_SIZE := Vector2(140, 140)
const KINGDOM_POINTS_STAR_OVERLAP := 24.0  # quanto "invade" sopra il bordo della barra, regola a occhio
const TOP_BAR_HEIGHT := 50.0

func _ready() -> void:
	# Root cause probabile: l'anchor Top Wide applicato da editor con "Keep
	# Size" non azzera offset_left/offset_right, quindi la barra restava
	# larga solo quanto il suo contenuto invece di estendersi a tutto lo
	# schermo. Forziamo gli offset via codice per non dipendere da quale
	# opzione è stata scelta nell'editor.
	set_anchors_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_KEEP_SIZE)
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = TOP_BAR_HEIGHT
	
	kingdom_name_label.text = KINGDOM_NAME_PLACEHOLDER
	kingdom_interface_label.text = "- %s" % KINGDOM_INTERFACE_PLACEHOLDER

	ResourceManager.population_changed.connect(_on_population_changed)
	_update_population_label(ResourceManager.population_current, ResourceManager.population_max)
	
	# La stella vive fuori da HBoxContainer apposta: la sua posizione deve
	# restare fissa al centro della barra, indipendentemente da quanti
	# bottoni ci sono nei gruppi sinistro/destro del flusso orizzontale.
	kingdom_points_star.set_anchors_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE)
	kingdom_points_star.custom_minimum_size = KINGDOM_POINTS_STAR_SIZE
	kingdom_points_star.size = KINGDOM_POINTS_STAR_SIZE
	kingdom_points_star.offset_left = -KINGDOM_POINTS_STAR_SIZE.x / 2
	kingdom_points_star.offset_right = KINGDOM_POINTS_STAR_SIZE.x / 2
	kingdom_points_star.offset_top = 0
	kingdom_points_star.offset_bottom = KINGDOM_POINTS_STAR_SIZE.y
	
	# Placeholder testuali: nessun sistema dati dietro ancora.
	currency_button.text = "Valute"
	supplies_button.text = "Supplies"
	goods_button.text = "Goods"
	help_button.text = "?"
	settings_button.text = "⚙"

	# Impostazioni è già funzionante: SettingsManager esiste da prima.
	settings_button.pressed.connect(_on_settings_pressed)

	# Guida: nessun sistema esiste ancora, placeholder silenzioso in attesa.
	# help_button.pressed non collegato finché non progettiamo cosa deve aprire.


func _on_settings_pressed() -> void:
	SettingsManager.open_settings(self)


func _on_population_changed(current: int, max_pop: int) -> void:
	_update_population_label(current, max_pop)


## NOTA: mostra ancora popolazione TOTALE corrente/massima, non la vera
## distinzione "libera/occupata" descritta nel design — quella richiede
## un concetto di edificio che impiega popolazione, non ancora esistente
## nel modello dati. Placeholder in attesa di quel sistema.
func _update_population_label(current: int, max_pop: int) -> void:
	pop_label.text = "Pop: %d/%d" % [current, max_pop]


## Chiamato da fuori (in futuro, da un sistema di selezione zone) quando
## il giocatore cambia interfaccia all'interno dello stesso Regno.
func set_interface_name(interface_name: String) -> void:
	kingdom_interface_label.text = "- %s" % interface_name
