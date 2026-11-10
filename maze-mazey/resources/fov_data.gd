class_name FovData
extends BaseResource

@export var fov_shape: Shape2D = null
## Size in tiles. It can be the radius or the length.
@export var fov_size: int = 1
## Only applicable to cones
@export var fov_angle: float = 60.0
