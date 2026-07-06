extends Node
## NotificationManager: canale broadcast per messaggi a schermo (banner UI).
## Non sa chi ascolta — emette solo il segnale. Userà anche Eventi/Vittoria
## più avanti, non solo save/load.

enum NotificationType {
	INFO,
	SUCCESS,
	WARNING,
	ERROR,
}

signal notification_requested(message: String, type: NotificationType)

func notify(message: String, type: NotificationType = NotificationType.INFO) -> void:
	notification_requested.emit(message, type)
