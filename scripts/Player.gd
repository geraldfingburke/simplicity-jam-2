extends Area2D

@export var health = 10
@export var health_max = 10
@export var attack = 1
@export var torch = 0
@export var torch_min = 10

var tile_size = 16
var inputs = {"right" : Vector2.RIGHT, "left" : Vector2.LEFT, "up" : Vector2.UP, "down" : Vector2.DOWN}

var move_speed = 3
var is_moving = false

var is_lit = false

@onready var ray = $RayCast2D
@onready var torch_sprite = $CanvasModulate/Sprite2D
@onready var stats_label = $Control/StatsLabel
@onready var alert_label = $Control/AlertLabel

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
	clear_label()
	ray.target_position = inputs[dir] * tile_size
	ray.force_raycast_update()
	if !ray.is_colliding():
		var tween = create_tween()
		tween.tween_property(self, "position", position + inputs[dir] * tile_size, 1.0/move_speed).set_trans(Tween.TRANS_SINE)
		is_moving = true
		await tween.finished
		is_moving = false
		update_light()
		update_stats_label()
	else:
		var object = ray.get_collider()
		match object.get_meta("Item"):
			"Torch":
				print("Here")
				pickup_torch()
				object.queue_free()
				return

func update_light():
	if torch > 0:
		torch -= 1
		light()
	if torch <= 0:
		is_lit = false
		light()

func pickup_torch():
	update_alert_label("[center]You found a torch[/center]")
	is_lit = true
	torch += torch_min
	light()
	update_stats_label()

func light():
	if (is_lit):
		torch_sprite.min_diameter = 3
		torch_sprite.max_diameter = 3.1
	else:
		torch_sprite.min_diameter = 1
		torch_sprite.max_diameter = 1.1

func clear_label():
	alert_label.text = ""

func update_alert_label(text):
	alert_label.text = text

func update_stats_label():
	stats_label.text = "Health: %s Attack: %s Light: %s" % [health, attack, torch]
