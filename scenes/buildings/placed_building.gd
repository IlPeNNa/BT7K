extends Sprite2D
## Rappresenta un edificio piazzato sulla mappa. Gestisce la propria
## produzione tramite un Timer interno con raccolta manuale stile Forge of
## Empires: al termine del ciclo l'edificio resta "pronto" (icona
## fluttuante pulsante sopra di lui) finché il giocatore non raccoglie,
## poi il timer riparte. Per ora tutti gli edifici condividono lo stesso
## blocco generico (block_128.png) — l'arte specifica per tipo è un task
## futuro separato.

signal production_ready
signal resource_collected

@onready var production_timer: Timer = $ProductionTimer
@onready var ready_icon: Node2D = $ReadyIcon
@onready var select_sound: AudioStreamPlayer2D = $SelectSound

## [HACK] Offset fisso indipendente dalla dimensione reale dello sprite:
## va bene per il blocco generico attuale (128px), ma quando arriverà
## l'arte specifica per edificio, edifici più alti (es. Mura) potrebbero
## aver bisogno di un offset diverso — valutare un campo su BuildingData
## se il problema si presenta davvero.
const READY_ICON_OFFSET: Vector2 = Vector2(0, -240)
const BOUNCE_HEIGHT: float = 12.0
const BOUNCE_DURATION: float = 0.5

var building_data: BuildingData
var is_ready_to_collect: bool = false
var _icon_tween: Tween = null

func _ready() -> void:
	ready_icon.position = READY_ICON_OFFSET
	ready_icon.visible = false

	# Sostituiamo il poligono disegnato a mano nell'editor (impreciso per via
	# dello zoom del canvas) con coordinate esatte via codice: piccolo
	# diamante di 20px totali, facilmente sostituibile con uno Sprite2D
	# quando arriverà l'asset vero.
	var icon_shape: Polygon2D = ready_icon.get_child(0)
	icon_shape.polygon = PackedVector2Array([
		Vector2(0, -30), Vector2(30, 0), Vector2(0, 30), Vector2(-30, 0),
	])
	icon_shape.color = Color(1.0, 0.85, 0.2, 1.0)  # oro

	production_ready.connect(_on_production_ready)
	resource_collected.connect(_on_resource_collected)

func setup(data: BuildingData) -> void:
	building_data = data

	if building_data.population_capacity > 0:
		ResourceManager.add_population_capacity(building_data.population_capacity)
	if building_data.produces_resource == "":
		return  # questo edificio non produce nulla (es. Casa, Mura)

	production_timer.wait_time = building_data.production_interval_seconds
	production_timer.one_shot = true
	production_timer.timeout.connect(_on_production_timer_timeout)
	production_timer.start()

func _on_production_timer_timeout() -> void:
	is_ready_to_collect = true
	production_ready.emit()

## Chiamata dal pannello Info/Raccogli o dal click diretto sull'icona
## fluttuante (Blocco 4): entrambi i percorsi arrivano qui, stesso effetto.
func collect_resource() -> bool:
	if not is_ready_to_collect:
		return false
	ResourceManager.add_resource(building_data.produces_resource, building_data.production_amount)
	is_ready_to_collect = false
	resource_collected.emit()
	production_timer.start()
	return true

## Restituisce la posizione mondo dell'icona: kingdom_thenorth.gd la
## converte in coordinate schermo per il test di click, invece di usare
## Area2D/physics picking — coerente con lo stile "un solo punto di
## ingresso input" già usato per piazzamento/demolizione/selezione.
func get_ready_icon_global_position() -> Vector2:
	return ready_icon.global_position

func _on_production_ready() -> void:
	ready_icon.visible = true
	_start_icon_pulse()

func _on_resource_collected() -> void:
	ready_icon.visible = false
	if _icon_tween != null and _icon_tween.is_valid():
		_icon_tween.kill()
	ready_icon.scale = Vector2.ONE


func _start_icon_pulse() -> void:
	if _icon_tween != null and _icon_tween.is_valid():
		_icon_tween.kill()
	_icon_tween = create_tween()
	_icon_tween.set_loops()
	_icon_tween.tween_property(ready_icon, "scale", Vector2(1.15, 1.15), 0.4).set_trans(Tween.TRANS_SINE)
	_icon_tween.tween_property(ready_icon, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE)


## Animazione di selezione stile Clash of Clans: l'edificio si solleva e
## ricade con un rimbalzo elastico, accompagnato da un suono. Puramente
## feedback visivo/sonoro — chiamata SOLO quando si clicca sull'edificio
## per selezionarlo (mai sulla raccolta, che passa da un percorso separato
## in kingdom_thenorth.gd tramite l'hit-test sull'icona).
func on_selected() -> void:
	if select_sound != null:
		select_sound.play()

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - BOUNCE_HEIGHT, BOUNCE_DURATION * 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position:y", position.y, BOUNCE_DURATION * 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
