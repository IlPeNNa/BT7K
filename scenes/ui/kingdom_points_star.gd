extends Control
## Vista della stella Kingdom Points: nessuno stato/timer proprio, reagisce
## solo ai segnali di KingdomPointsManager (fonte di verità unica, stesso
## pattern già usato da TopBar/ResourceManager). Asset: star-base.svg +
## 7 point-N.svg + center-glow.svg (import diretto, il blur SVG originale
## non è supportato dall'importer Godot: le punte risultano leggermente
## più "nette" della demo browser, non un bug, un limite noto dell'import).

const GLOW_DURATION := 0.6
const FADE_OUT_DURATION := 0.4

@onready var point_layers: Array[TextureRect] = [
	$Point1, $Point2, $Point3, $Point4, $Point5, $Point6, $Point7,
]
@onready var center_glow: TextureRect = $CenterGlow
@onready var timer_label: Label = $TimerLabel
@onready var points_counter_label: Label = $PointsCounterLabel

func _ready() -> void:
	KingdomPointsManager.kingdom_points_changed.connect(_on_points_changed)
	KingdomPointsManager.kingdom_points_full.connect(_on_points_full)
	_on_points_changed(KingdomPointsManager.current_points, KingdomPointsManager.max_points)


func _process(_delta: float) -> void:
	if KingdomPointsManager.current_points < KingdomPointsManager.max_points:
		timer_label.text = _format_seconds(KingdomPointsManager.get_seconds_until_next_point())


func _on_points_changed(current: int, max_points: int) -> void:
	for i in range(point_layers.size()):
		var target_alpha: float = 1.0 if i < current else 0.0
		var layer: TextureRect = point_layers[i]
		if is_equal_approx(layer.modulate.a, target_alpha):
			continue
		var duration: float = GLOW_DURATION if target_alpha > 0.0 else FADE_OUT_DURATION
		var tween := create_tween()
		tween.tween_property(layer, "modulate:a", target_alpha, duration).set_trans(Tween.TRANS_SINE)
	points_counter_label.text = "%d/%d" % [current, max_points]


func _on_points_full() -> void:
	timer_label.text = "✦"
	var tween := create_tween()
	tween.tween_property(center_glow, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)


func _format_seconds(total_seconds: float) -> String:
	var seconds_int: int = int(ceil(total_seconds))
	@warning_ignore("integer_division")
	var minutes: int = seconds_int / 60
	var secs: int = seconds_int % 60
	return "%d:%02d" % [minutes, secs]
