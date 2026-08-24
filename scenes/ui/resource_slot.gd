extends Control
## Slot riusabile icona+valore dentro la cornice ornamentale del Nord.

@onready var icon_wrapper: Control = $Content/IconWrapper
@onready var icon_texture: TextureRect = $Content/IconWrapper/IconTexture
@onready var value_label: Label = $Content/ValueLabel

const ICON_WRAPPER_POSITION := Vector2(8, 8)
const ICON_WRAPPER_SIZE := Vector2(28, 28)
const VALUE_LABEL_POSITION := Vector2(42, 8)
const VALUE_LABEL_SIZE := Vector2(58, 28)


func _ready() -> void:
	icon_wrapper.position = ICON_WRAPPER_POSITION
	icon_wrapper.size = ICON_WRAPPER_SIZE
	value_label.position = VALUE_LABEL_POSITION
	value_label.size = VALUE_LABEL_SIZE
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func setup(icon: Texture2D, value_text: String) -> void:
	icon_texture.texture = icon
	value_label.text = value_text
