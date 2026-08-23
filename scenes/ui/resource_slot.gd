extends Control
## Slot riusabile icona+valore dentro la cornice ornamentale del Nord.
## Usato per Popolazione ora, riusabile in futuro per Valute/Supplies/Goods.

@onready var icon_wrapper: Control = $Content/IconWrapper
@onready var icon_texture: TextureRect = $Content/IconWrapper/IconTexture
@onready var value_label: Label = $Content/ValueLabel

const ICON_SIZE := Vector2(28, 28)

func _ready() -> void:
	icon_wrapper.custom_minimum_size = ICON_SIZE
	icon_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_wrapper.clip_contents = true

	icon_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	$Content.offset_left = 7 # corretto: 21 (centro cerchio) - 14 (metà icona 28px) = 7


func setup(icon: Texture2D, value_text: String) -> void:
	icon_texture.texture = icon
	value_label.text = value_text
