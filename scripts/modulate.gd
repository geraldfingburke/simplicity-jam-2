extends Sprite2D

@export var min_diameter : float
@export var max_diameter : float
@export var speed : float
var growing = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if scale >= Vector2(max_diameter, max_diameter):
		growing = false
	if scale <= Vector2(min_diameter, min_diameter):
		growing = true
	if growing:
		scale += Vector2(1,1) * speed * delta
	else:
		scale -= Vector2(1,1) * speed * delta

