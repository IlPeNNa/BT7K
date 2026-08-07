extends Node
## KingdomPointsManager: accumulo automatico dei Kingdom Points fino a un
## massimo (default 7). A differenza della produzione edifici (raccolta
## manuale), i Kingdom Points si accumulano DA SOLI nel tempo.

signal kingdom_points_changed(current: int, max_points: int)
signal kingdom_points_full

const DEFAULT_MAX_POINTS := 7
# Valore di TEST per osservare l'accumulo rapidamente durante lo sviluppo.
const POINT_INTERVAL_SECONDS := 30.0

var current_points: int = 0
var max_points: int = DEFAULT_MAX_POINTS

var _timer: Timer = null


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = POINT_INTERVAL_SECONDS
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()


func _on_timer_timeout() -> void:
	if current_points >= max_points:
		_timer.stop()
		return
	current_points += 1
	kingdom_points_changed.emit(current_points, max_points)
	if current_points >= max_points:
		_timer.stop()
		kingdom_points_full.emit()


func get_seconds_until_next_point() -> float:
	if current_points >= max_points:
		return 0.0
	return _timer.time_left

# [HACK stub] Nessun sistema di spesa Kingdom Points esiste ancora.
