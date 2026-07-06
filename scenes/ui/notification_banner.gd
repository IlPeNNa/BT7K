extends Control
## NotificationBanner: mostra il messaggio più recente di NotificationManager
## per qualche secondo, poi si nasconde da solo. Nessuna coda: una nuova
## notifica sostituisce quella in corso (sufficiente per save/load; da
## rivedere se il futuro sistema di Eventi genera raffiche di messaggi).

const DISPLAY_SECONDS: float = 3.0

# Le chiavi sono int (i valori dell'enum NotificationType sotto sono int):
# i Dictionary tipizzati di GDScript non accettano direttamente un tipo enum
# come chiave, quindi tipizziamo su int per evitare l'errore del parser.
const TYPE_COLORS: Dictionary[int, Color] = {
	NotificationManager.NotificationType.INFO: Color(0.75, 0.8, 0.9),
	NotificationManager.NotificationType.SUCCESS: Color(0.4, 0.85, 0.5),
	NotificationManager.NotificationType.WARNING: Color(0.95, 0.75, 0.2),
	NotificationManager.NotificationType.ERROR: Color(0.9, 0.35, 0.35),
}

@onready var message_label: Label = $Panel/MessageLabel
@onready var hide_timer: Timer = $HideTimer

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # non deve bloccare i click sulla griglia sottostante

	hide_timer.wait_time = DISPLAY_SECONDS
	hide_timer.one_shot = true
	hide_timer.timeout.connect(_on_hide_timer_timeout)

	NotificationManager.notification_requested.connect(_on_notification_requested)

func _on_notification_requested(message: String, type: NotificationManager.NotificationType) -> void:
	message_label.text = message
	message_label.modulate = TYPE_COLORS.get(type, Color.WHITE)
	visible = true
	hide_timer.start()  # se era già in corso una notifica, riparte da capo (no coda)

func _on_hide_timer_timeout() -> void:
	visible = false
