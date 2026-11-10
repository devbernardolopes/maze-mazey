class_name FovData
extends BaseResource

## Shape of the field of view. A circular shape (or an empty shape) is treated
## as a sector of circle narrowed by [member fov_angle]; convex and concave
## polygon shapes are used literally, facing-aligned to the entity.
@export var fov_shape: Shape2D = null
## Size in tiles: the sight length of the sector (cones) or the size of the
## rectangular shape (its width and height). The entity tile is
## `Helper.TILE_SIZE` pixels.
@export var fov_size: float = 6.0
## Full width of the sight sector in degrees, centered on the direction the
## entity faces (e.g. 60.0 = +-30 degrees around the facing). 180.0 = half plane,
## 360.0 = full circle. Only applicable to circular shapes.
@export var fov_angle: float = 60.0
