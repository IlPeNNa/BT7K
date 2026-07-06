extends Resource
class_name HeatSourceData
## Dati di una fonte di calore: definisce un'area quadrata (raggio di
## Chebyshev) entro cui è possibile costruire. Sostituisce il sistema di
## adiacenza al Municipio — più semplice (nessun flood-fill, nessun
## ricalcolo dopo demolizione) e tematicamente coerente con Il Nord.

@export var center_cell: Vector2i = Vector2i(4,4)
@export var radius: int = 2  # 1 = zona 3x3, 2 = 5x5, 3 = 7x7
@export var is_unlocked: bool = true
