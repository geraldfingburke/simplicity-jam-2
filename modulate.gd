extends Sprite2D

@export var min : float
@export var max : float
@export var speed : float
var growing = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if scale >= Vector2(max, max):
		growing = false
	if scale <= Vector2(min, min):
		growing = true
	if growing:
		scale += Vector2(1,1) * speed * delta
	else:
		scale -= Vector2(1,1) * speed * delta

