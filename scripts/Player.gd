extends Area2D

@export var health = 10
@export var health_max = 10
@export var attack = 1
@export var torch = 10
@export var torch_min = 10

var tile_size = 16
var inputs = {"right" : Vector2.RIGHT, "left" : Vector2.LEFT, "up" : Vector2.UP, "down" : Vector2.DOWN}

var move_speed = 3
var is_moving = false

var is_lit = false

@onready var ray = $RayCast2D
@onready var torch_sprite = $PlayerSprite/CanvasModulate/Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _unhandled_input(event):
	if is_moving:
		return
	for dir in inputs.keys():
		if event.is_action_pressed(dir):
			move(dir)

func move(dir):
	ray.target_position = inputs[dir] * tile_size
	ray.force_raycast_update()
	if !ray.is_colliding():
		var tween = create_tween()
		tween.tween_property(self, "position", position + inputs[dir] * tile_size, 1.0/move_speed).set_trans(Tween.TRANS_SINE)
		is_moving = true
		await tween.finished
		is_moving = false
	else:
		var object = ray.get_collider().get_parent()
